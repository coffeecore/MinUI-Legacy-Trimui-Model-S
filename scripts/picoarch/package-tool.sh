#!/bin/sh
set -eu

: "${PICOARCH_BUILD:?PICOARCH_BUILD is required}"
: "${PICOARCH_TOOL_OUTPUT:?PICOARCH_TOOL_OUTPUT is required}"

TOOL_OUTPUT="$PICOARCH_TOOL_OUTPUT"
PAK="$TOOL_OUTPUT/Tools/PicoArch.pak"

TOTAL_CORES=21

rm -rf "$TOOL_OUTPUT"

mkdir -p "$PAK/cores"

test -x "$PICOARCH_BUILD/picoarch"

SKIN_DIR="$PICOARCH_BUILD/picodrive/platform/opendingux/data/skin"

if [ ! -f "$SKIN_DIR/font.png" ] || \
   [ ! -f "$SKIN_DIR/selector.png" ] || \
   [ ! -f "$SKIN_DIR/skin.txt" ]; then
    echo "ERROR: missing PicoArch/libpicofe skin under $SKIN_DIR" >&2
    exit 1
fi

cp "$PICOARCH_BUILD/picoarch" "$PAK/picoarch"

# PicoArch resolves its libpicofe skin relative to the picoarch executable.
mkdir -p "$PAK/skin"
cp -a "$SKIN_DIR/." "$PAK/skin/"

test -f "$PAK/skin/font.png"
test -f "$PAK/skin/selector.png"
test -f "$PAK/skin/skin.txt"

find "$PICOARCH_BUILD" \
    -maxdepth 1 \
    -type f \
    -name '*_libretro.so' \
    -exec cp {} "$PAK/cores/" \;

cat > "$PAK/launch.sh" <<'EOF'
#!/bin/sh

PAK_DIR="$(dirname "$0")"
LOG_DIR="/mnt/SDCARD/.minui/logs"
LOG="$LOG_DIR/PicoArch-Tool.txt"

PICOARCH_HOME="/mnt/SDCARD/.minui/picoarch"
PICOARCH_SAVE_ROOT="/mnt/SDCARD/Saves/picoarch"
PICOARCH_SYSTEM_ROOT="/mnt/SDCARD/Bios/picoarch"

mkdir -p "$LOG_DIR"
mkdir -p "$PICOARCH_HOME"
mkdir -p "$PICOARCH_SAVE_ROOT"
mkdir -p "$PICOARCH_SYSTEM_ROOT"

export HOME="$PICOARCH_HOME"
export PICOARCH_SAVE_ROOT
export PICOARCH_SYSTEM_ROOT

exec >>"$LOG" 2>&1

echo "=== PicoArch Tool ==="
echo "PAK_DIR=$PAK_DIR"
echo "PWD before cd=$(pwd)"

cd "$PAK_DIR/cores"

echo "PWD after cd=$(pwd)"
echo
echo "=== skin ==="
ls -lah "$PAK_DIR/skin" 2>&1
echo
echo "=== cores ==="
ls -lah "$PAK_DIR/cores" 2>&1
echo
echo "=== starting PicoArch ==="

"$PAK_DIR/picoarch"
EOF

chmod +x "$PAK/launch.sh"
chmod +x "$PAK/picoarch"

CORE_COUNT=$(
    find "$PAK/cores" \
        -maxdepth 1 \
        -type f \
        -name '*_libretro.so' \
        | wc -l
)

if [ "$CORE_COUNT" -ne "$TOTAL_CORES" ]; then
    echo "ERROR: expected $TOTAL_CORES PicoArch cores, found $CORE_COUNT" >&2
    exit 1
fi

echo
echo "PicoArch Tool PAK complete:"
echo "  $PAK"
echo "  cores: $CORE_COUNT"
