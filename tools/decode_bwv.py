"""Decoder for legacy .BWV phonetic/word audio files.

Header format in backup/extracted/SYS/SND/*.BWV:
  - Standard RIFF WAVE container (`RIFF` ... `WAVEfmt ` ... `data`)
  - Format tags:
      * `0x0001`: uncompressed 8-bit unsigned mono PCM (22050 Hz)
      * `0x006B`: NoGate Consulting (1988-89) block-compressed 8-bit PCM
  - For `0x006B`, the `data` chunk starts with:
      uint16 block_count
    Followed by `block_count` (uint32 compressed_size, uint32 uncompressed_size)
    entries, then `block_count` compressed blocks back-to-back.
"""

from __future__ import annotations

import array
import struct
import sys
import wave
from pathlib import Path

DIST_BITS = (
    3, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
)

DIST_CODE = (
    0, 4, 1, 24, 2, 12, 5, 25, 0, 13, 6, 26, 3, 14, 7, 48,
    0, 8, 1, 27, 2, 15, 9, 28, 0, 16, 10, 29, 3, 17, 11, 49,
    0, 4, 1, 30, 2, 18, 5, 31, 0, 19, 6, 32, 3, 20, 7, 50,
    0, 8, 1, 33, 2, 21, 9, 34, 0, 22, 10, 35, 3, 23, 11, 51,
    0, 4, 1, 36, 2, 12, 5, 37, 0, 13, 6, 38, 3, 14, 7, 52,
    0, 8, 1, 39, 2, 15, 9, 40, 0, 16, 10, 41, 3, 17, 11, 53,
    0, 4, 1, 42, 2, 18, 5, 43, 0, 19, 6, 44, 3, 20, 7, 54,
    0, 8, 1, 45, 2, 21, 9, 46, 0, 22, 10, 47, 3, 23, 11, 55,
    0, 4, 1, 24, 2, 12, 5, 25, 0, 13, 6, 26, 3, 14, 7, 56,
    0, 8, 1, 27, 2, 15, 9, 28, 0, 16, 10, 29, 3, 17, 11, 57,
    0, 4, 1, 30, 2, 18, 5, 31, 0, 19, 6, 32, 3, 20, 7, 58,
    0, 8, 1, 33, 2, 21, 9, 34, 0, 22, 10, 35, 3, 23, 11, 59,
    0, 4, 1, 36, 2, 12, 5, 37, 0, 13, 6, 38, 3, 14, 7, 60,
    0, 8, 1, 39, 2, 15, 9, 40, 0, 16, 10, 41, 3, 17, 11, 61,
    0, 4, 1, 42, 2, 18, 5, 43, 0, 19, 6, 44, 3, 20, 7, 62,
    0, 8, 1, 45, 2, 21, 9, 46, 0, 22, 10, 47, 3, 23, 11, 63,
)


def _read_bits(buf: bytes, bit_idx: int, count: int) -> int:
    if count <= 0:
        return 0
    byte_i = bit_idx >> 3
    rem = bit_idx & 7
    chunk = 0
    for k in range(4):
        if byte_i + k < len(buf):
            chunk |= buf[byte_i + k] << (8 * k)
    return (chunk >> rem) & ((1 << count) - 1)


def _decompress_nogate(src: bytes, expected_len: int) -> bytes:
    if expected_len == 0:
        return b""
    if len(src) < 3:
        raise ValueError("Compressed block too short")

    tree_size = struct.unpack_from("<H", src, 0)[0]
    nbits = src[2]
    if tree_size < 2 or tree_size > 0x275 or nbits == 0 or nbits > 16:
        raise ValueError(f"Invalid tree parameters: size={tree_size}, nbits={nbits}")

    bidx = 24
    tree: list[int] = []
    for _ in range(tree_size):
        v = _read_bits(src, bidx, nbits)
        bidx += nbits
        if v >= tree_size:
            v = (v + 0x8000 - tree_size) & 0xFFFF
        tree.append(v)

    root = tree_size - 2
    out = bytearray()
    while len(out) < expected_len:
        node = root
        while (node & 0x8000) == 0:
            byte_i = bidx >> 3
            if byte_i >= len(src):
                raise ValueError("Unexpected end of Huffman bitstream")
            bit = (src[byte_i] >> (bidx & 7)) & 1
            bidx += 1
            node = tree[node + bit]

        sym = node & 0x7FFF
        if sym < 256:
            out.append(sym)
        elif sym == 0x100:
            break
        else:
            length = sym - 0xFE
            byte8 = _read_bits(src, bidx, 8)
            hi = DIST_CODE[byte8]
            bidx += DIST_BITS[hi]

            window_pos = len(out) + 0x3C
            if window_pos >= 0x2000:
                dh = 7
            else:
                tmp = window_pos >> 5
                dh = 0
                while True:
                    tmp >>= 1
                    if tmp == 0:
                        break
                    dh += 1

            lo = _read_bits(src, bidx, dh)
            bidx += dh
            dist = ((hi << dh) | lo) + 1
            for _ in range(length):
                out.append(0x20 if dist > len(out) else out[-dist])

    return bytes(out)


def _parse_riff_wave(raw: bytes) -> tuple[bytes, bytes] | None:
    if len(raw) < 12 or raw[:4] != b"RIFF" or raw[8:12] != b"WAVE":
        return None
    fmt_chunk: bytes | None = None
    data_chunk: bytes | None = None
    pos = 12
    end = len(raw)
    while pos + 8 <= end:
        chunk_id = raw[pos : pos + 4]
        chunk_size = struct.unpack_from("<I", raw, pos + 4)[0]
        body_start = pos + 8
        body_end = body_start + chunk_size
        if body_end > end:
            break
        if chunk_id == b"fmt ":
            fmt_chunk = raw[body_start:body_end]
        elif chunk_id == b"data":
            data_chunk = raw[body_start:body_end]
        pos = body_end + (chunk_size & 1)
    if fmt_chunk is None or data_chunk is None or len(fmt_chunk) < 16:
        return None
    return fmt_chunk, data_chunk


def decode_bwv(src_path: Path, dst_path: Path) -> bool:
    """Decode a .BWV file (0x006B NoGate or 0x0001 PCM) into 16-bit PCM WAV."""
    raw = src_path.read_bytes()
    parsed = _parse_riff_wave(raw)
    if parsed is None:
        return False

    fmt_chunk, data_chunk = parsed
    fmt_tag, channels, sample_rate, _, _, bits_per_sample = struct.unpack_from("<HHIIHH", fmt_chunk, 0)
    if channels < 1 or sample_rate <= 0 or bits_per_sample != 8:
        return False

    if fmt_tag == 0x0001:
        pcm_u8 = data_chunk
    elif fmt_tag == 0x006B:
        if len(data_chunk) < 2:
            return False
        block_count = struct.unpack_from("<H", data_chunk, 0)[0]
        table_end = 2 + block_count * 8
        if table_end > len(data_chunk):
            return False

        blocks: list[tuple[int, int]] = []
        pos = 2
        for _ in range(block_count):
            cs, us = struct.unpack_from("<II", data_chunk, pos)
            pos += 8
            blocks.append((cs, us))

        pcm_buf = bytearray()
        for cs, us in blocks:
            if pos + cs > len(data_chunk):
                return False
            comp_block = data_chunk[pos : pos + cs]
            pos += cs
            decoded = _decompress_nogate(comp_block, us)
            if len(decoded) != us:
                return False
            pcm_buf.extend(decoded)
        pcm_u8 = bytes(pcm_buf)
    else:
        return False

    pcm_s16 = array.array("h", ((b - 128) << 8 for b in pcm_u8))
    if sys.byteorder != "little":
        pcm_s16.byteswap()

    dst_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(dst_path), "wb") as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(pcm_s16.tobytes())
    return True
