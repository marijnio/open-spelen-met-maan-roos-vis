# Spelen met Maan Roos Vis (LÖVE 2D Reimplementation)

An independent open-source reimplementation of the classic 1997 Dutch educational PC game *Spelen met Maan Roos Vis*, built with [LÖVE (Love2D)](https://love2d.org/) in Lua.

## Screenshots

| Start Menu | Draai maar om |
| :---: | :---: |
| ![Start Menu](docs/screenshots/1.png) | ![Draai maar om minigame](docs/screenshots/2.png) |

## Legal & Copyright Notice

This project is an **independent open-source engine reimplementation** and is **not affiliated with, authorized by, or endorsed by Uitgeverij Zwijsen or Radarsoft B.V.**

No copyrighted game graphics, audio recordings, or original CD-ROM files are distributed in this repository. To play, you must supply and convert assets locally from your own legal copy of the original game.

## Design Philosophy

This open-source reimplementation aims to stay faithful to the original 1997 release's visuals, audio, word lists, scoring rules, and gameplay flow, while fixing obvious usability pitfalls and 1990s technical limitations where they get in the way of modern playability.

For example, in the original Windows 3.1 release of **Kleurplaat**, checking whether every pixel had been painted was too slow to run on each brush click, so players had to click the small clock icon on the HUD to finish a completed picture—making it look as though nothing happened after coloring the final shape. In this version, guided mode automatically completes the level as soon as the last grey shape is filled in the right color, while free-color mode (grey sample picture) still finishes via the clock so players can keep recoloring as long as they like.

## Prerequisites

- **LÖVE 11.5** (`love`)
- **Python 3** (for local asset conversion)
- **ImageMagick** (`magick`)
- **FFmpeg** (`ffmpeg`)

## Generating Local Assets

1. Extract or mount your original CD-ROM and locate its `SYS/` directory (containing `GRP/` and `SND/`).
2. Run the conversion script locally:

```sh
python3 tools/convert_assets.py --source /path/to/CD/SYS --output assets
```

This converts legacy `.BMP` sprites/screens into RGBA `.png` files (with magenta chroma-key transparency on sprite sheets), converts `.WAV` audio to 16-bit PCM `.wav`, and generates `assets/manifest.lua`. Both `backup/` and `assets/` are ignored by `.gitignore` and will not be tracked by Git.

## Configuring an External Asset Directory (Optional)

If you prefer storing converted assets outside the repository folder, `src/core/assets.lua` searches for `manifest.lua` in this order:

1. `SMRV_ASSETS_DIR` environment variable:
   ```sh
   SMRV_ASSETS_DIR=/path/to/your/smrv-assets love .
   ```
2. `local_config.lua` (gitignored — copy from `local_config.example.lua`):
   ```lua
   return {
     assets_dir = "/path/to/your/smrv-assets",
   }
   ```
3. Default project-local `assets/` directory
4. LÖVE's user save directory (`<save-dir>/assets/`)

If no local assets are found at launch, the game opens a helpful setup screen instead of crashing.

## Running & Controls

```sh
love .
```

- `F1`: Toggle hotzone debug overlay (virtual `640×480` coordinates)
- `F2`: Toggle `nearest` / `linear` scaling filter
- `F11`: Toggle fullscreen
- `Escape`: Back to previous menu / open quit confirmation on Start Menu

## Building for Android Tablets (`love-android`)

You can package your own local copy into a standalone debug APK for an Android tablet using [love-android](https://github.com/love2d/love-android) (matching LÖVE 11.5). No APKs, `.love` bundles, or copyrighted assets are committed to Git (`build/`, `*.love`, `*.apk`, `love-android/`, and `assets/` are all gitignored).

1. **Prerequisites:** Java JDK (17 recommended), Android SDK (`ANDROID_HOME`), `zip`, and a local clone of `love-android` checked out at the `11.5` tag/branch.
2. **Convert assets locally** (if not done already):
   ```sh
   python3 tools/convert_assets.py --source /path/to/CD/SYS --output assets
   ```
3. **Create the `.love` bundle:**
   ```sh
   ./scripts/build_android.sh
   ```
   This packages `main.lua`, `conf.lua`, `src/`, and your local `assets/` into `build/game.love` (excludes `local_config.lua` and `backup/`).
4. **Embed in `love-android` & compile the APK:**
   Copy `build/game.love` into your local `love-android` checkout (or let the script do both steps):
   ```sh
   ./scripts/build_android.sh --love-android /path/to/love-android --build-apk
   ```
   Manually, that corresponds to copying `build/game.love` to `app/src/embed/assets/game.love` (or `app/src/main/assets/game.love` depending on your `love-android` flavor) and running:
   ```sh
   cd /path/to/love-android
   ./gradlew assembleEmbedNoRecordDebug
   ```
   *(Tip: in `love-android`'s `AndroidManifest.xml`, set `android:screenOrientation="sensorLandscape"` on `GameActivity` so the 4:3 canvas stays in tablet landscape mode.)*
5. **Optional side-load mode (code-only `.love`):**
   If you prefer keeping media separate from the APK, run `./scripts/build_android.sh --no-assets` and copy your `assets/` folder into the app's external save directory on the tablet (`/sdcard/Android/data/<package>/files/save/spelen-met-maan-roos-vis/assets/`).
