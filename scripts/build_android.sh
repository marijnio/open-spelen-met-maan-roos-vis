#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ASSETS_DIR="${SMRV_ASSETS_DIR:-${REPO_ROOT}/assets}"
INCLUDE_ASSETS=true
OUTPUT_PATH="${REPO_ROOT}/build/game.love"
LOVE_ANDROID_DIR=""
BUILD_APK=false
APP_NAME="OpenSMRV"
ICON_PATH="${REPO_ROOT}/logo.png"

usage() {
  cat <<'EOF'
Usage: scripts/build_android.sh [options]

Packages the LÖVE Lua code (and optionally local converted assets) into a .love
bundle ready for love-android, without modifying or tracking anything in Git.

Options:
  --assets-dir <path>    Directory containing manifest.lua and converted media
                         (default: $SMRV_ASSETS_DIR or <repo>/assets)
  --no-assets            Build a code-only .love (side-load assets to Android save dir)
  --output <path>        Output .love path (default: <repo>/build/game.love)
  --love-android <path>  Copy game.love into a local love-android checkout,
                         apply app icon and Android title
  --app-name <name>      Android app title (default: OpenSMRV)
  --icon <path>          App icon PNG path (default: <repo>/logo.png)
  --build-apk            Run Gradle in --love-android and copy APK into build/
  -h, --help             Show this help text
EOF
}

resize_icon() {
  local src="$1"
  local dst="$2"
  local size="$3"
  mkdir -p "$(dirname "${dst}")"
  if command -v magick >/dev/null 2>&1; then
    magick "${src}" -resize "${size}x${size}!" "PNG32:${dst}"
  elif command -v convert >/dev/null 2>&1; then
    convert "${src}" -resize "${size}x${size}!" "PNG32:${dst}"
  elif command -v sips >/dev/null 2>&1; then
    sips -z "${size}" "${size}" "${src}" --out "${dst}" >/dev/null
  elif command -v python3 >/dev/null 2>&1 && python3 -c "import PIL" >/dev/null 2>&1; then
    python3 -c '
import sys
from PIL import Image
src, dst, size = sys.argv[1], sys.argv[2], int(sys.argv[3])
Image.open(src).convert("RGBA").resize((size, size), Image.LANCZOS).save(dst, "PNG")
' "${src}" "${dst}" "${size}"
  else
    echo "Error: Cannot resize icon; install ImageMagick (magick/convert), sips, or Python Pillow." >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --assets-dir)
      [[ $# -ge 2 ]] || { echo "Error: --assets-dir requires a path" >&2; exit 1; }
      ASSETS_DIR="$2"
      shift 2
      ;;
    --no-assets)
      INCLUDE_ASSETS=false
      shift
      ;;
    --output)
      [[ $# -ge 2 ]] || { echo "Error: --output requires a path" >&2; exit 1; }
      OUTPUT_PATH="$2"
      shift 2
      ;;
    --love-android)
      [[ $# -ge 2 ]] || { echo "Error: --love-android requires a path" >&2; exit 1; }
      LOVE_ANDROID_DIR="$2"
      shift 2
      ;;
    --app-name)
      [[ $# -ge 2 ]] || { echo "Error: --app-name requires a value" >&2; exit 1; }
      APP_NAME="$2"
      shift 2
      ;;
    --icon)
      [[ $# -ge 2 ]] || { echo "Error: --icon requires a path" >&2; exit 1; }
      ICON_PATH="$2"
      shift 2
      ;;
    --build-apk)
      BUILD_APK=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v zip >/dev/null 2>&1; then
  echo "Error: 'zip' command not found." >&2
  exit 1
fi

if [[ "${BUILD_APK}" == true && -z "${LOVE_ANDROID_DIR}" ]]; then
  echo "Error: --build-apk requires --love-android <path>." >&2
  exit 1
fi

if [[ "${INCLUDE_ASSETS}" == true ]]; then
  if [[ ! -f "${ASSETS_DIR}/manifest.lua" ]]; then
    echo "Error: Missing '${ASSETS_DIR}/manifest.lua'." >&2
    echo "Run 'python3 tools/convert_assets.py --source /path/to/SYS --output assets' first," >&2
    echo "pass --assets-dir <path>, or pass --no-assets for a code-only bundle." >&2
    exit 1
  fi
fi

# Resolve output path to absolute before changing directory.
OUT_DIR="$(dirname "${OUTPUT_PATH}")"
OUT_FILE="$(basename "${OUTPUT_PATH}")"
mkdir -p "${OUT_DIR}"
ABS_OUTPUT="$(cd "${OUT_DIR}" && pwd)/${OUT_FILE}"

STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/smrv-love-stage.XXXXXX")"
trap 'rm -rf "${STAGE_DIR}"' EXIT

cp "${REPO_ROOT}/main.lua" "${STAGE_DIR}/main.lua"
cp "${REPO_ROOT}/conf.lua" "${STAGE_DIR}/conf.lua"
cp -R "${REPO_ROOT}/src" "${STAGE_DIR}/src"

if [[ -f "${ICON_PATH}" ]]; then
  cp "${ICON_PATH}" "${STAGE_DIR}/logo.png"
fi

if [[ "${INCLUDE_ASSETS}" == true ]]; then
  mkdir -p "${STAGE_DIR}/assets"
  cp -R "${ASSETS_DIR}/." "${STAGE_DIR}/assets/"
  rm -rf "${STAGE_DIR}/assets/raw" "${STAGE_DIR}/assets/converted"
fi

# Strip OS/editor/developer-only clutter from staged tree.
rm -f "${STAGE_DIR}/local_config.lua"
find "${STAGE_DIR}" -name '.DS_Store' -delete
find "${STAGE_DIR}" -name '__pycache__' -type d -exec rm -rf {} +

rm -f "${ABS_OUTPUT}"
(
  cd "${STAGE_DIR}"
  zip -r -9 -q "${ABS_OUTPUT}" .
)

BUNDLE_SIZE="$(du -h "${ABS_OUTPUT}" | cut -f1)"
echo "Created ${ABS_OUTPUT} (${BUNDLE_SIZE})"

if [[ -n "${LOVE_ANDROID_DIR}" ]]; then
  if [[ ! -d "${LOVE_ANDROID_DIR}" ]]; then
    echo "Error: love-android directory not found: ${LOVE_ANDROID_DIR}" >&2
    exit 1
  fi

  if [[ -d "${LOVE_ANDROID_DIR}/app/src/embed" ]]; then
    DEST_ASSETS_DIR="${LOVE_ANDROID_DIR}/app/src/embed/assets"
    DEST_RES_DIR="${LOVE_ANDROID_DIR}/app/src/embed/res"
  elif [[ -d "${LOVE_ANDROID_DIR}/app/src/main" ]]; then
    DEST_ASSETS_DIR="${LOVE_ANDROID_DIR}/app/src/main/assets"
    DEST_RES_DIR="${LOVE_ANDROID_DIR}/app/src/main/res"
  else
    echo "Error: Could not find app/src/embed or app/src/main inside ${LOVE_ANDROID_DIR}." >&2
    exit 1
  fi

  mkdir -p "${DEST_ASSETS_DIR}"
  cp "${ABS_OUTPUT}" "${DEST_ASSETS_DIR}/game.love"
  echo "Copied bundle to ${DEST_ASSETS_DIR}/game.love"

  if [[ -f "${ICON_PATH}" ]]; then
    resize_icon "${ICON_PATH}" "${DEST_RES_DIR}/drawable-mdpi/love.png" 48
    resize_icon "${ICON_PATH}" "${DEST_RES_DIR}/drawable-hdpi/love.png" 72
    resize_icon "${ICON_PATH}" "${DEST_RES_DIR}/drawable-xhdpi/love.png" 96
    resize_icon "${ICON_PATH}" "${DEST_RES_DIR}/drawable-xxhdpi/love.png" 144
    resize_icon "${ICON_PATH}" "${DEST_RES_DIR}/drawable-xxxhdpi/love.png" 192
    echo "Updated launcher icons in ${DEST_RES_DIR}/drawable-*/love.png from ${ICON_PATH}"
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - "${LOVE_ANDROID_DIR}" "${APP_NAME}" <<'PY'
import pathlib
import re
import sys
from xml.sax.saxutils import escape

love_dir = pathlib.Path(sys.argv[1])
app_name = sys.argv[2]

attr_escaped = escape(app_name, {'"': "&quot;", "'": "&apos;"})
text_escaped = escape(app_name)

manifest_paths = [
    love_dir / "app" / "src" / "main" / "AndroidManifest.xml",
    love_dir / "app" / "src" / "embed" / "AndroidManifest.xml",
]

for manifest in manifest_paths:
    if not manifest.is_file():
        continue
    orig = manifest.read_text(encoding="utf-8")
    updated = orig

    updated = re.sub(
        r"<application\b[^>]*>",
        lambda m: re.sub(r'android:label="[^"]*"', f'android:label="{attr_escaped}"', m.group(0)),
        updated,
    )

    def replace_activity_label(match):
        tag = match.group(0)
        if "GameActivity" in tag or "LÖVE" in tag:
            return re.sub(r'android:label="[^"]*"', f'android:label="{attr_escaped}"', tag)
        return tag

    updated = re.sub(r"<activity\b[^>]*>", replace_activity_label, updated)
    updated = updated.replace('android:label="LÖVE for Android"', f'android:label="{attr_escaped}"')

    if updated != orig:
        manifest.write_text(updated, encoding="utf-8")
        print(f"Updated app title to '{app_name}' in {manifest}")

strings_paths = [
    love_dir / "app" / "src" / "main" / "res" / "values" / "strings.xml",
    love_dir / "app" / "src" / "embed" / "res" / "values" / "strings.xml",
]

for strings_xml in strings_paths:
    if not strings_xml.is_file():
        continue
    orig = strings_xml.read_text(encoding="utf-8")
    updated = re.sub(
        r'(<string\b[^>]*\bname="app_name"[^>]*>)(.*?)(</string>)',
        lambda m: f"{m.group(1)}{text_escaped}{m.group(3)}",
        orig,
        flags=re.DOTALL,
    )
    if updated != orig:
        strings_xml.write_text(updated, encoding="utf-8")
        print(f"Updated app_name to '{app_name}' in {strings_xml}")
PY
  else
    echo "Warning: python3 not found; skipping AndroidManifest.xml / strings.xml title update." >&2
  fi

  if [[ "${BUILD_APK}" == true ]]; then
    if [[ ! -x "${LOVE_ANDROID_DIR}/gradlew" ]]; then
      echo "Error: Executable gradlew not found in ${LOVE_ANDROID_DIR}." >&2
      exit 1
    fi

    GRADLE_TASK="assembleDebug"
    if [[ -d "${LOVE_ANDROID_DIR}/app/src/embed" ]]; then
      GRADLE_TASK="assembleEmbedNoRecordDebug"
    fi

    echo "Running ./gradlew ${GRADLE_TASK} in ${LOVE_ANDROID_DIR}..."
    (
      cd "${LOVE_ANDROID_DIR}"
      ./gradlew "${GRADLE_TASK}"
    )

    BUILT_APK="$(find "${LOVE_ANDROID_DIR}/app/build/outputs/apk" -type f -name '*.apk' | head -n 1 || true)"
    if [[ -n "${BUILT_APK}" ]]; then
      cp "${BUILT_APK}" "${OUT_DIR}/$(basename "${BUILT_APK}")"
      echo "Copied APK to ${OUT_DIR}/$(basename "${BUILT_APK}")"
    else
      echo "Warning: Gradle succeeded but no APK was found under app/build/outputs/apk." >&2
    fi
  fi
else
  echo "Next: copy ${ABS_OUTPUT} to <love-android>/app/src/embed/assets/game.love and run ./gradlew assembleEmbedNoRecordDebug"
fi
