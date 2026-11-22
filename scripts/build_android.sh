#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ASSETS_DIR="${SMRV_ASSETS_DIR:-${REPO_ROOT}/assets}"
INCLUDE_ASSETS=true
OUTPUT_PATH="${REPO_ROOT}/build/game.love"
LOVE_ANDROID_DIR=""
BUILD_APK=false

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
  --love-android <path>  Copy game.love into a local love-android checkout
  --build-apk            Run Gradle in --love-android and copy APK into build/
  -h, --help             Show this help text
EOF
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
  elif [[ -d "${LOVE_ANDROID_DIR}/app/src/main" ]]; then
    DEST_ASSETS_DIR="${LOVE_ANDROID_DIR}/app/src/main/assets"
  else
    echo "Error: Could not find app/src/embed or app/src/main inside ${LOVE_ANDROID_DIR}." >&2
    exit 1
  fi

  mkdir -p "${DEST_ASSETS_DIR}"
  cp "${ABS_OUTPUT}" "${DEST_ASSETS_DIR}/game.love"
  echo "Copied bundle to ${DEST_ASSETS_DIR}/game.love"

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
