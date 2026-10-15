#!/usr/bin/env bash

set -euo pipefail

TOTAL_PAKS=27

: "${PICOARCH_BUILD:?PICOARCH_BUILD is required}"
: "${PICOARCH_OUTPUT:?PICOARCH_OUTPUT is required}"
: "${PICOARCH_PAKS_OUTPUT:?PICOARCH_PAKS_OUTPUT is required}"

PICOARCH_BIN="$PICOARCH_OUTPUT/picoarch"
CORES_DIR="$PICOARCH_OUTPUT/cores"

OUTPUT="$PICOARCH_PAKS_OUTPUT"

BLUEMSX_ASSETS="$PICOARCH_BUILD/bluemsx/system/bluemsx"
FMSX_ROMS="$PICOARCH_BUILD/fmsx/fMSX/ROMs"

# ---------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------

if [ ! -f "$PICOARCH_BIN" ]; then
    echo "ERROR: missing PicoArch binary:"
    echo "  $PICOARCH_BIN"
    exit 1
fi

if [ ! -d "$CORES_DIR" ]; then
    echo "ERROR: missing PicoArch cores directory:"
    echo "  $CORES_DIR"
    exit 1
fi

# libpicofe loads menu graphics from ./skin relative to PicoArch's current
# working directory. Locate the pinned checkout's skin and package it with every
# PAK instead of relying on files already present on the SD card.
SKIN_DIR="$PICOARCH_BUILD/picodrive/platform/opendingux/data/skin"

if [ ! -f "$SKIN_DIR/font.png" ] || \
   [ ! -f "$SKIN_DIR/selector.png" ] || \
   [ ! -f "$SKIN_DIR/skin.txt" ]; then
    echo "ERROR: missing PicoArch/libpicofe skin under $SKIN_DIR" >&2
    exit 1
fi


required_cores=(
    beetle-pce-fast_libretro.so
    bluemsx_libretro.so
    fceumm_libretro.so
    gambatte_libretro.so
    gme_libretro.so
    gngeo_libretro.so
    gpsp_libretro.so
    handy_libretro.so
    mame2000_libretro.so
    mame2003_libretro.so
    mednafen_ngp_libretro.so
    mednafen_wswan_libretro.so
    pcsx_rearmed_libretro.so
    picodrive_libretro.so
    pokemini_libretro.so
    smsplus-gx_libretro.so
    snes9x2005_libretro.so
    stella2014_libretro.so
)

for core in "${required_cores[@]}"; do
    if [ ! -f "$CORES_DIR/$core" ]; then
        echo "ERROR: missing core:"
        echo "  $CORES_DIR/$core"
        exit 1
    fi
done

if [ ! -d "$BLUEMSX_ASSETS/Machines" ]; then
    echo "ERROR: missing blueMSX Machines:"
    echo "  $BLUEMSX_ASSETS/Machines"
    exit 1
fi

if [ ! -d "$BLUEMSX_ASSETS/Databases" ]; then
    echo "ERROR: missing blueMSX Databases:"
    echo "  $BLUEMSX_ASSETS/Databases"
    exit 1
fi

fmsx_roms=(
    MSX.ROM
    MSX2.ROM
    MSX2EXT.ROM
    MSX2P.ROM
    MSX2PEXT.ROM
    DISK.ROM
    KANJI.ROM
)

for rom in "${fmsx_roms[@]}"; do
    if [ ! -f "$FMSX_ROMS/$rom" ]; then
        echo "ERROR: missing fMSX system ROM:"
        echo "  $FMSX_ROMS/$rom"
        exit 1
    fi
done

# ---------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------

rm -rf "$OUTPUT"
mkdir -p "$OUTPUT"


create_pak()
{
    local system="$1"
    local core_file="$2"
    local mode="${3:-normal}"

    # One system name is used everywhere.
    #
    # Example:
    #   system="Nintendo"
    #
    # ROM directory:
    #   /mnt/SDCARD/Roms/Nintendo
    #
    # PicoArch PAK:
    #   Nintendo-picoarch.pak
    local pak_dir="$OUTPUT/$system-picoarch.pak"

    # Example:
    #   core_file="fceumm_libretro.so"
    #   core_name="fceumm"
    local core_name="${core_file%_libretro.so}"

    mkdir -p "$pak_dir"

    cp "$PICOARCH_BIN" "$pak_dir/picoarch"
    cp "$CORES_DIR/$core_file" "$pak_dir/$core_file"

    mkdir -p "$pak_dir/skin"
    cp -a "$SKIN_DIR/." "$pak_dir/skin/"

    cat > "$pak_dir/launch.sh" <<EOF_LAUNCH
#!/bin/sh

EMU_EXE="picoarch"
EMU_DIR=\$(dirname "\$0")

# The PAK name and ROM directory always share the same system name.
#
# Example:
#   Nintendo-picoarch.pak
#   -> /mnt/SDCARD/Roms/Nintendo
ROM_DIR="/mnt/SDCARD/Roms/$system"

PICOARCH_HOME="/mnt/SDCARD/.minui/picoarch"
PICOARCH_SAVE_ROOT="/mnt/SDCARD/Saves/picoarch"
PICOARCH_SYSTEM_ROOT="/mnt/SDCARD/Bios/picoarch"
PICOARCH_CACHE_ROOT="/mnt/SDCARD/.minui/picoarch/cache"
SYSTEM_DIR="\$PICOARCH_SYSTEM_ROOT/$core_name"

EMU_NAME="$system"
ROM="\$1"

mkdir -p "\$PICOARCH_HOME"
mkdir -p "\$PICOARCH_SAVE_ROOT"
mkdir -p "\$SYSTEM_DIR"
mkdir -p "/mnt/SDCARD/.minui/logs"
EOF_LAUNCH

    case "$mode" in
        swap)
            cat >> "$pak_dir/launch.sh" <<'EOF_LAUNCH'

needs-swap
EOF_LAUNCH
            ;;

        psx)
            cat >> "$pak_dir/launch.sh" <<'EOF_LAUNCH'

# Use the PlayStation BIOS provided by the Trimui firmware when available.
if [ ! -f "$SYSTEM_DIR/scph5502.bin" ] && \
   [ -f "/usr/trimui/bin/pcsx_rearmed/bios/scph5502.bin" ]; then
    cp "/usr/trimui/bin/pcsx_rearmed/bios/scph5502.bin" \
       "$SYSTEM_DIR/scph5502.bin"
fi

needs-swap
EOF_LAUNCH
            ;;

        bluemsx)
            mkdir -p "$pak_dir/assets"

            cp -a "$BLUEMSX_ASSETS/Machines" \
                  "$pak_dir/assets/Machines"

            cp -a "$BLUEMSX_ASSETS/Databases" \
                  "$pak_dir/assets/Databases"

            cat >> "$pak_dir/launch.sh" <<'EOF_LAUNCH'

# Install blueMSX machine definitions and databases on first use.
if [ ! -d "$SYSTEM_DIR/Machines" ]; then
    cp -R "$EMU_DIR/assets/Machines" "$SYSTEM_DIR/Machines"
fi

if [ ! -d "$SYSTEM_DIR/Databases" ]; then
    cp -R "$EMU_DIR/assets/Databases" "$SYSTEM_DIR/Databases"
fi
EOF_LAUNCH
            ;;

        fmsx)
            mkdir -p "$pak_dir/assets"

            for rom in "${fmsx_roms[@]}"; do
                cp "$FMSX_ROMS/$rom" "$pak_dir/assets/$rom"
            done

            cat >> "$pak_dir/launch.sh" <<'EOF_LAUNCH'

# Install the system ROMs supplied with the pinned fMSX source.
for FILE in \
    MSX.ROM \
    MSX2.ROM \
    MSX2EXT.ROM \
    MSX2P.ROM \
    MSX2PEXT.ROM \
    DISK.ROM \
    KANJI.ROM

do
    if [ ! -f "$SYSTEM_DIR/$FILE" ]; then
        cp "$EMU_DIR/assets/$FILE" "$SYSTEM_DIR/$FILE"
    fi
done
EOF_LAUNCH
            ;;

        normal)
            ;;

        *)
            echo "ERROR: unknown PAK mode: $mode"
            exit 1
            ;;
    esac

    cat >> "$pak_dir/launch.sh" <<EOF_LAUNCH

export HOME="\$PICOARCH_HOME"
export PICOARCH_SAVE_ROOT
export PICOARCH_SYSTEM_ROOT
export PICOARCH_CACHE_ROOT

cd "\$EMU_DIR"

"\$EMU_DIR/\$EMU_EXE" "./$core_file" "\$ROM" \
    &> "/mnt/SDCARD/.minui/logs/\$EMU_NAME.txt"
EOF_LAUNCH

    chmod +x "$pak_dir/launch.sh"
}


# ---------------------------------------------------------------------
# Nintendo
# ---------------------------------------------------------------------

create_pak \
    "Nintendo" \
    "fceumm_libretro.so"

# create_pak \
#     "Nintendo (QuickNES)" \
#     "quicknes_libretro.so" \
#     "Nintendo"

    # create_pak \
    #     "Famicom Disk System (FCEUmm)" \
    #     "fceumm_libretro.so" \
    #     "Famicom Disk System"


# ---------------------------------------------------------------------
# Game Boy
# ---------------------------------------------------------------------

create_pak \
    "Game Boy" \
    "gambatte_libretro.so"

create_pak \
    "Game Boy Color" \
    "gambatte_libretro.so"

create_pak \
    "Game Boy Advance" \
    "gpsp_libretro.so" \
    "swap"


# ---------------------------------------------------------------------
# Sega 8-bit / ColecoVision
# ---------------------------------------------------------------------

create_pak \
    "Game Gear" \
    "smsplus-gx_libretro.so" 

create_pak \
    "Master System" \
    "smsplus-gx_libretro.so"

create_pak \
    "ColecoVision" \
    "bluemsx_libretro.so" \
    "bluemsx"

create_pak \
    "SG-1000" \
    "bluemsx_libretro.so" \
    "bluemsx"


# ---------------------------------------------------------------------
# Sega 16/32-bit / CD
# ---------------------------------------------------------------------

create_pak \
    "Genesis" \
    "picodrive_libretro.so"

create_pak \
    "Sega CD" \
    "picodrive_libretro.so"

create_pak \
    "Sega 32X" \
    "picodrive_libretro.so"

# ---------------------------------------------------------------------
# Super Nintendo
# ---------------------------------------------------------------------

# create_pak \
#     "Super Nintendo (Snes9x 2002)" \
#     "snes9x2002_libretro.so" \
#     "Super Nintendo"

create_pak \
    "Super Nintendo" \
    "snes9x2005_libretro.so"

# ---------------------------------------------------------------------
# PlayStation
# ---------------------------------------------------------------------

create_pak \
    "PlayStation" \
    "pcsx_rearmed_libretro.so" \
    "psx"


# ---------------------------------------------------------------------
# NEC
# ---------------------------------------------------------------------

create_pak \
    "TurboGrafx-16" \
    "beetle-pce-fast_libretro.so"

create_pak \
    "TurboGrafx-CD" \
    "beetle-pce-fast_libretro.so"

# ---------------------------------------------------------------------
# SNK / Bandai
# ---------------------------------------------------------------------

create_pak \
    "Neo Geo Pocket" \
    "mednafen_ngp_libretro.so"

create_pak \
    "Neo Geo Pocket Color" \
    "mednafen_ngp_libretro.so"

create_pak \
    "Neo Geo" \
    "gngeo_libretro.so" \
    "swap"

create_pak \
    "WonderSwan" \
    "mednafen_wswan_libretro.so"

create_pak \
    "WonderSwan Color" \
    "mednafen_wswan_libretro.so"

create_pak \
    "Pokemon Mini" \
    "pokemini_libretro.so"

# ---------------------------------------------------------------------
# MSX
# ---------------------------------------------------------------------

create_pak \
    "MSX" \
    "bluemsx_libretro.so" \
    "bluemsx"

# create_pak \
#     "MSX (fMSX)" \
#     "fmsx_libretro.so" \
#     "MSX" \
#     "fmsx"


# ---------------------------------------------------------------------
# Atari
# ---------------------------------------------------------------------

create_pak \
    "Atari 2600" \
    "stella2014_libretro.so"


# ---------------------------------------------------------------------
# Arcade
# ---------------------------------------------------------------------

create_pak \
    "MAME 2000" \
    "mame2000_libretro.so"

create_pak \
    "MAME 2003" \
    "mame2003_libretro.so" \

# ---------------------------------------------------------------------
# Atari Lynx
# ---------------------------------------------------------------------

create_pak \
    "Lynx" \
    "handy_libretro.so"

# ---------------------------------------------------------------------
# Other
# ---------------------------------------------------------------------

create_pak \
    "Game Music" \
    "gme_libretro.so"

# ---------------------------------------------------------------------
# Final validation
# ---------------------------------------------------------------------

pak_count=$(
    find "$OUTPUT" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -name '*-picoarch.pak' \
        | wc -l
)

if [ "$pak_count" -ne "$TOTAL_PAKS" ]; then
    echo "ERROR: expected $TOTAL_PAKS PAKs, got $pak_count"
    exit 1
fi


while IFS= read -r -d '' pak; do
    if ! sh -n "$pak/launch.sh"; then
        echo "ERROR: invalid launcher:"
        echo "  $pak/launch.sh"
        exit 1
    fi
done < <(
    find "$OUTPUT" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -name '*-picoarch.pak' \
        -print0
)

echo
echo "PicoArch PAK packaging complete."
echo "Output:"
echo "  $OUTPUT"
echo
echo "PAKs: $pak_count"
