"""Decoder stub for legacy .BWV compressed phonetic/word audio files.

Header format discovered in backup/extracted/SYS/SND/*.BWV:
  - Standard RIFF WAVE container (`RIFF` ... `WAVEfmt ` ... `data`)
  - Custom `wFormatTag = 0x006B` (mono, 22050 Hz, 8-bit)
  - Embedded references in SMRV.EXE point to a NoGate Consulting (1988-89)
    block-compressed PCM decoder.
  - The `data` chunk starts with:
      uint16 block_count
    Followed by `block_count` blocks, each prefixed with:
      uint32 compressed_size
      uint32 uncompressed_size (max 12100 samples/block)

Phase 2 will implement the `0x006B` block decompressor so all 124 `.BWV`
phoneme and word files decode cleanly into `assets/audio/words/`.
"""

from pathlib import Path


def decode_bwv(src_path: Path, dst_path: Path) -> bool:
    """Decode a 0x006B .BWV file into a standard PCM WAV at `dst_path`.

    Returns True if decoding succeeded, or False while the Phase 2
    decompressor is not yet implemented.
    """
    _ = (src_path, dst_path)
    return False
