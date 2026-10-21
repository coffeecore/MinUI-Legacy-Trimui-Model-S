#!/bin/sh
# OD Commander.pak/launch.sh

EMU_DIR=$(dirname "$0")
cd "$EMU_DIR"

./commander \
	--config "$EMU_DIR/commander.cfg" \
	--res-dir "$EMU_DIR/res"
