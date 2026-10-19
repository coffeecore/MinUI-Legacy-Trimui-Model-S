#!/bin/sh
# MS.pak/launch.sh

REMAP_FROM="MS"
REMAP_ONTO="GG"
EMU_DIR=$(dirname "$0")
EMU_DIR=${EMU_DIR/$REMAP_FROM/$REMAP_ONTO}
ROM=${1}

"$EMU_DIR/launch.sh" "$ROM"
