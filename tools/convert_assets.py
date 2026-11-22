#!/usr/bin/env python3
"""Convert legacy assets from a local CD-ROM SYS/ copy into LÖVE-ready assets.

Reads from --source (default: backup/extracted/SYS) and writes to --output
(default: assets):
  - <output>/images/{screens,ui,draaiom,invullen,klplaat,turbowrd,video,woorden}/*.png
  - <output>/audio/{sfx,jantje,system}/*.wav
  - <output>/manifest.lua (with paths relative to <output>)
"""

from __future__ import annotations

import argparse
import concurrent.futures
import os
import re
import struct
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SOURCE = ROOT / "backup" / "extracted" / "SYS"
DEFAULT_OUTPUT = ROOT / "assets"

sys.path.insert(0, str(Path(__file__).resolve().parent))
from decode_bwv import decode_bwv  # noqa: E402


def normalize_name(stem: str) -> str:
    """Normalize legacy 8.3 filenames to clean lowercase Lua-friendly keys."""
    name = re.sub(r"[^a-z0-9_]+", "_", stem.lower())
    return name.strip("_") if name.strip("_") else "unnamed"


def normalize_filename_stem(stem: str) -> str:
    """Normalize stem while preserving trailing underscore (e.g. PIC_A_ -> pic_a_)."""
    cleaned = re.sub(r"[^a-z0-9_]+", "_", stem.lower())
    return cleaned or "unnamed"


def find_ci_dir(parent: Path, name: str) -> Path | None:
    """Locate a direct child directory case-insensitively."""
    direct = parent / name
    if direct.is_dir():
        return direct
    if not parent.is_dir():
        return None
    target = name.lower()
    for child in parent.iterdir():
        if child.is_dir() and child.name.lower() == target:
            return child
    return None


def inspect_bmp(bmp_path: Path) -> tuple[int, int, bool]:
    """Return (width, height, has_magenta_corners) from a Windows 3.x BMP header."""
    data = bmp_path.read_bytes()
    if len(data) < 54 or data[:2] != b"BM":
        return (0, 0, False)

    pixel_offset = struct.unpack_from("<I", data, 10)[0]
    dib_size = struct.unpack_from("<I", data, 14)[0]
    width, height = struct.unpack_from("<ii", data, 18)
    bpp = struct.unpack_from("<H", data, 28)[0]
    compression = struct.unpack_from("<I", data, 30)[0]
    abs_h = abs(height)

    # Only inspect uncompressed paletted/24-bit BMP corners for magenta chroma-key
    if compression != 0 or width <= 0 or abs_h <= 0:
        return (width, abs_h, False)

    def get_rgb(x: int, y_from_top: int) -> tuple[int, int, int] | None:
        row = (abs_h - 1 - y_from_top) if height > 0 else y_from_top
        stride = ((width * bpp + 31) // 32) * 4
        row_start = pixel_offset + row * stride
        if bpp == 8:
            idx_pos = row_start + x
            if idx_pos >= len(data):
                return None
            idx = data[idx_pos]
            pal_off = 14 + dib_size + idx * 4
            if pal_off + 3 > len(data):
                return None
            b, g, r = data[pal_off : pal_off + 3]
            return (r, g, b)
        if bpp == 4:
            byte_pos = row_start + (x // 2)
            if byte_pos >= len(data):
                return None
            byte_val = data[byte_pos]
            idx = (byte_val >> 4) if (x % 2 == 0) else (byte_val & 0x0F)
            pal_off = 14 + dib_size + idx * 4
            if pal_off + 3 > len(data):
                return None
            b, g, r = data[pal_off : pal_off + 3]
            return (r, g, b)
        if bpp == 24:
            px_pos = row_start + x * 3
            if px_pos + 3 > len(data):
                return None
            b, g, r = data[px_pos : px_pos + 3]
            return (r, g, b)
        return None

    tl = get_rgb(0, 0)
    tr = get_rgb(width - 1, 0)
    bl = get_rgb(0, abs_h - 1)
    br = get_rgb(width - 1, abs_h - 1)
    magenta = (255, 0, 255)
    corners = [c for c in (tl, tr, bl, br) if c is not None]
    has_magenta = len(corners) == 4 and (
        (tl == magenta and br == magenta) or corners.count(magenta) >= 3
    )
    return (width, abs_h, has_magenta)


def convert_bmp_task(task: tuple[Path, Path, bool]) -> tuple[Path, bool]:
    src, dst, chroma_magenta = task
    dst.parent.mkdir(parents=True, exist_ok=True)
    cmd = ["magick", str(src)]
    if chroma_magenta:
        cmd.extend(["-alpha", "set", "-transparent", "rgb(255,0,255)"])
    cmd.append(f"PNG32:{dst}")
    subprocess.run(cmd, check=True)
    return (dst, chroma_magenta)


def convert_audio_task(task: tuple[Path, Path]) -> Path:
    src, dst = task
    dst.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-i", str(src),
        "-acodec", "pcm_s16le", "-ar", "22050", "-ac", "1",
        str(dst),
    ]
    subprocess.run(cmd, check=True)
    return dst


def lua_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def write_manifest(
    manifest_path: Path,
    images_map: dict[str, dict[str, str]],
    audio_map: dict[str, dict[str, str]],
    pending_bwv: list[str],
) -> None:
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    lines: list[str] = [
        "-- Auto-generated by tools/convert_assets.py — paths are relative to this directory.",
        "return {",
        "  images = {",
    ]
    for cat in sorted(images_map.keys()):
        lines.append(f"    {cat} = {{")
        for key in sorted(images_map[cat].keys()):
            rel = lua_escape(images_map[cat][key])
            lines.append(f'      ["{lua_escape(key)}"] = "{rel}",')
        lines.append("    },")
    lines.append("  },")
    lines.append("  audio = {")
    for cat in sorted(audio_map.keys()):
        lines.append(f"    {cat} = {{")
        for key in sorted(audio_map[cat].keys()):
            rel = lua_escape(audio_map[cat][key])
            lines.append(f'      ["{lua_escape(key)}"] = "{rel}",')
        lines.append("    },")
    lines.append("    pending_bwv = {")
    for key in sorted(pending_bwv):
        lines.append(f'      "{lua_escape(key)}",')
    lines.append("    },")
    lines.append("  },")
    lines.append("}")
    manifest_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert local Spelen met Maan Roos Vis SYS/ assets for LÖVE."
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=DEFAULT_SOURCE,
        help="Path to the original SYS/ directory containing GRP/ and SND/ (default: backup/extracted/SYS)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help="Output directory for converted PNGs, WAVs, and manifest.lua (default: assets)",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    sys_dir = args.source.expanduser().resolve()
    out_dir = args.output.expanduser().resolve()
    grp_dir = find_ci_dir(sys_dir, "GRP")
    snd_dir = find_ci_dir(sys_dir, "SND")

    if not sys_dir.is_dir() or grp_dir is None or snd_dir is None:
        print(
            f"ERROR: Expected GRP/ and SND/ inside source directory: {sys_dir}",
            file=sys.stderr,
        )
        return 1

    image_tasks: list[tuple[Path, Path, bool]] = []
    images_map: dict[str, dict[str, str]] = {
        "screens": {},
        "ui": {},
        "draaiom": {},
        "invullen": {},
        "klplaat": {},
        "turbowrd": {},
        "video": {},
        "woorden": {},
    }

    bmp_files = sorted(p for p in grp_dir.rglob("*") if p.is_file() and p.suffix.lower() == ".bmp")
    for bmp in bmp_files:
        rel_parts = bmp.relative_to(grp_dir).parts
        key = normalize_filename_stem(bmp.stem)
        w, h, has_magenta = inspect_bmp(bmp)
        if len(rel_parts) == 1:
            category = "screens" if (w == 640 and h == 480) else "ui"
        else:
            category = rel_parts[0].lower()
            images_map.setdefault(category, {})

        dst = out_dir / "images" / category / f"{key}.png"
        rel_lua = dst.relative_to(out_dir).as_posix()
        if key in images_map[category]:
            raise RuntimeError(f"Key collision in images.{category}: {key}")
        images_map[category][key] = rel_lua
        image_tasks.append((bmp, dst, has_magenta))

    audio_tasks: list[tuple[Path, Path]] = []
    audio_map: dict[str, dict[str, str]] = {
        "sfx": {},
        "jantje": {},
        "system": {},
        "words": {},
    }

    sfx_dir = find_ci_dir(snd_dir, "SFX")
    if sfx_dir is not None:
        for wav in sorted(p for p in sfx_dir.iterdir() if p.is_file() and p.suffix.lower() == ".wav"):
            key = normalize_name(wav.stem)
            dst = out_dir / "audio" / "sfx" / f"{key}.wav"
            audio_map["sfx"][key] = dst.relative_to(out_dir).as_posix()
            audio_tasks.append((wav, dst))

    jantje_dir = find_ci_dir(snd_dir, "JANTJE")
    if jantje_dir is not None:
        for wav in sorted(p for p in jantje_dir.iterdir() if p.is_file() and p.suffix.lower() == ".wav"):
            key = normalize_name(wav.stem)
            dst = out_dir / "audio" / "jantje" / f"{key}.wav"
            audio_map["jantje"][key] = dst.relative_to(out_dir).as_posix()
            audio_tasks.append((wav, dst))

    for wav in sorted(p for p in snd_dir.iterdir() if p.is_file() and p.suffix.lower() == ".wav"):
        key = normalize_name(wav.stem)
        dst = out_dir / "audio" / "system" / f"{key}.wav"
        audio_map["system"][key] = dst.relative_to(out_dir).as_posix()
        audio_tasks.append((wav, dst))

    pending_bwv: list[str] = []
    decoded_bwv = 0
    for bwv in sorted(p for p in snd_dir.iterdir() if p.is_file() and p.suffix.lower() == ".bwv"):
        key = normalize_name(bwv.stem)
        dst = out_dir / "audio" / "words" / f"{key}.wav"
        if decode_bwv(bwv, dst):
            audio_map["words"][key] = dst.relative_to(out_dir).as_posix()
            decoded_bwv += 1
        else:
            pending_bwv.append(key)

    max_workers = min(8, (os.cpu_count() or 4))
    magenta_sprites: list[str] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as pool:
        img_futs = [pool.submit(convert_bmp_task, t) for t in image_tasks]
        aud_futs = [pool.submit(convert_audio_task, t) for t in audio_tasks]

        for f in concurrent.futures.as_completed(img_futs):
            dst, chroma = f.result()
            if chroma:
                magenta_sprites.append(dst.name)
        for f in concurrent.futures.as_completed(aud_futs):
            f.result()

    manifest_path = out_dir / "manifest.lua"
    write_manifest(manifest_path, images_map, audio_map, pending_bwv)

    sfx_count = len(audio_map["sfx"])
    vo_count = len(audio_map["jantje"]) + len(audio_map["system"])
    print(f"Converted {len(image_tasks)} PNG images (magenta chroma-key: {sorted(magenta_sprites)})")
    print(f"Converted {sfx_count} SFX .wav and {vo_count} VO/system .wav files")
    print(f"BWV files: {decoded_bwv} decoded, {len(pending_bwv)} cataloged in pending_bwv")
    print(f"Manifest written to {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
