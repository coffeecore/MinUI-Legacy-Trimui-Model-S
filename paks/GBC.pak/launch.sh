#!/bin/sh
# GBC.pak/launch.sh

REMAP_FROM="GBC"
REMAP_ONTO="GB"
EMU_DIR=$(dirname "$0")
EMU_DIR=${EMU_DIR/$REMAP_FROM/$REMAP_ONTO}
ROM=${1}

"$EMU_DIR/launch.sh" "$ROM"