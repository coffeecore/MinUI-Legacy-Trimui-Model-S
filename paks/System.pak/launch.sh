#!/bin/sh
# System.pak/launch.sh

# echo -e "LD_LIBRARY_PATH=$LD_LIBRARY_PATH\nPATH=$PATH" > /mnt/SDCARD/.minui/logs/System.txt

# TODO: tmp
# /etc/init.d/adbd start &
# touch /tmp/disable-sleep

SD=/mnt/SDCARD

LOG_DIR="$SD/.minui/logs"
DISABLE_LOGS="$SD/.minui/disable-logs"

logs_are_tmpfs() {
	awk -v dir="$LOG_DIR" '$2 == dir && $3 == "tmpfs" { found = 1 } END { exit !found }' /proc/mounts
}

setup_logs() {
	mkdir -p "$LOG_DIR"

	if [ -f "$DISABLE_LOGS" ]; then
		if ! logs_are_tmpfs; then
			mount -t tmpfs -o size=1m tmpfs "$LOG_DIR"
		fi
	elif logs_are_tmpfs; then
		umount "$LOG_DIR"
	fi
}

UPDATE_LOG="$SD/update.log"
UPDATE_ZIP="$SD/TrimuiUpdate_MinUI.zip"
UPDATE_TMP="$SD/.tmp_update"

cd "$SD/System/System.pak"

# TODO: just search .tmp_update for any .pak
if [ -d "$UPDATE_TMP/Emus" ] || [ -d "$UPDATE_TMP/Games" ] || [ -d "$UPDATE_TMP/Tools" ]; then
	./update.sh
fi

notify 100 quit
killall -s KILL updateui
# killall -s KILL tee
rm -f "$UPDATE_LOG"

killall keymon

export LD_LIBRARY_PATH="$SD/System/lib:$LD_LIBRARY_PATH"
export PATH="$SD/System/bin:$PATH"

a=`ps | grep keymon | grep -v grep`
if [ "$a" == "" ]; then
	keymon &
fi

touch /tmp/minui_exec
sync

FAKE_RTC_FILE="$SD/.minui/fake-rtc"
FAKE_RTC_INITIAL=946684800
FAKE_RTC_BOOT_OFFSET=14400

if [ -f "$FAKE_RTC_FILE" ]; then
    FAKE_RTC=$(cat "$FAKE_RTC_FILE")
    FAKE_RTC=$((FAKE_RTC + FAKE_RTC_BOOT_OFFSET))
else
    FAKE_RTC=$FAKE_RTC_INITIAL
fi

date -s "@$FAKE_RTC"

date +%s > "$FAKE_RTC_FILE"
sync

while [ -f /tmp/minui_exec ]; do
	# these can be deleted with Commander.pak so make sure they exist
	setup_logs
	mkdir -p "$SD/.minui/screenshots"
	
	./MinUI &> "$SD/.minui/logs/MinUI.txt"
	sync

	NEXT="$SD/.minui/next.sh"
	if [ -f $NEXT ]; then
		CMD=`cat $NEXT`
		rm -f $NEXT
		eval $CMD

		date +%s > "$FAKE_RTC_FILE"
		
		if [ -f /tmp/using-swap ]; then
			rm -f /tmp/using-swap
			swapoff -a
		fi
		sync
	fi
done

killall keymon

if [ -f /tmp/minui_update ]; then
	rm -f /tmp/minui_update
	killall -s KILL updater
	
	echo start updating | tee $UPDATE_LOG
	updateui >> $UPDATE_LOG &
	notify 0 "extracting package"
	mkdir -p ${UPDATE_TMP}
	total=`unzip -l ${UPDATE_ZIP} | wc -l`
	unzip -d ${UPDATE_TMP} -o ${UPDATE_ZIP} | awk -v total="$total" -v out="/tmp/.update_msg" 'function bname(file,a,n){n=split(file,a,"/");return a[n]}BEGIN{cnt=0}{printf "">out;cnt+=1;printf "%d extract %s\n",cnt*100/total,bname($2)>>out;close(out)}'
	"$UPDATE_TMP/updater" | tee -a $UPDATE_LOG
fi
