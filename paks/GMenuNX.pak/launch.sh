#!/bin/sh
# Launch GMenuNX from MinUI Legacy on Trimui Model S.

SD=/mnt/SDCARD
GMENU_DIR="$SD/Apps/gmenunx"
MINUI_KEYMON="$SD/System/bin/keymon"
RUN_FLAG=/tmp/gmenu_exec

# Check everything before stopping MinUI's keymon.
if [ ! -x "$GMENU_DIR/gmenunx" ] || [ ! -x "$GMENU_DIR/keymon" ] || [ ! -x "$MINUI_KEYMON" ]; then
    echo "GMenuNX: missing executable (gmenunx or keymon)" >&2
    exit 1
fi

# Create a return shortcut only if GMenuNX does not have one yet.
# Existing user-defined shortcuts are never overwritten.
if [ -d "$GMENU_DIR/sections/applications" ]; then
    if [ ! -e "$GMENU_DIR/switch-minui.sh" ]; then
        cp "$SD/Tools/GMenuNX.pak/switch-minui.sh" "$GMENU_DIR/switch-minui.sh" && \
            chmod +x "$GMENU_DIR/switch-minui.sh"
    fi
    if [ ! -e "$GMENU_DIR/sections/applications/MinUI" ]; then
        cp "$SD/Tools/GMenuNX.pak/MinUI" "$GMENU_DIR/sections/applications/MinUI"
    fi
fi

restore_minui() {
    rm -f "$RUN_FLAG"
    killall keymon 2>/dev/null
    "$MINUI_KEYMON" &
}

# Run cleanup on normal exit or on an interrupt/error exit.
trap 'restore_minui' 0
trap 'exit 1' 1 2 15

killall keymon 2>/dev/null

export HOME="$SD/Apps"
export LD_LIBRARY_ORG="$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$SD/lib:$LD_LIBRARY_PATH"

cd "$GMENU_DIR" || exit 1

./keymon &
touch "$RUN_FLAG" || exit 1

while [ -f "$RUN_FLAG" ]; do
    ./gmenunx
    result=$?
    sync

    # Do not loop forever when GMenuNX fails to start or crashes.
    [ "$result" -eq 0 ] || break
done
