#!/bin/sh
# SMS.pak/launch.sh

REMAP_FROM="SMS"
REMAP_ONTO="GG"
EMU_DIR=$(dirname "$0")
EMU_DIR=${EMU_DIR/$REMAP_FROM/$REMAP_ONTO}
ROM=${1}

"$EMU_DIR/launch.sh" "$ROM"