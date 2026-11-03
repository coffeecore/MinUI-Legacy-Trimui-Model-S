#!/bin/sh
# Random Game.pak - launch a random ROM using MinUI's emulator preference.
# A small SDL/TTF helper displays the system being scanned; MinUI is unchanged.

SD=${SDCARD_PATH:-/mnt/SDCARD}
ROMS="$SD/Roms"
EMUS="$SD/Emus"
MINUI="$SD/.minui"
RECENTS="$MINUI/recent.txt"
LOG="$MINUI/logs/Random Game.txt"
PAK_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
STATUS_FIFO="/tmp/minui-random-status.$$"
STATUS_PID=""
STATUS_ACTIVE=0

# Keep the progress window alive during scanning without busy polling.
# A named pipe sends new system names to the tiny SDL helper on demand.
start_status() {
    [ -x "$PAK_DIR/status" ] || return 0
    mkfifo "$STATUS_FIFO" 2>/dev/null || return 0
    "$PAK_DIR/status" < "$STATUS_FIFO" &
    STATUS_PID=$!
    exec 3>"$STATUS_FIFO"
    STATUS_ACTIVE=1
    (printf '%s\n' 'Selecting a system...' >&3) 2>/dev/null || :
}

stop_status() {
    if [ "$STATUS_ACTIVE" -eq 1 ]; then
        exec 3>&-
        wait "$STATUS_PID" 2>/dev/null || :
        STATUS_ACTIVE=0
    fi
    rm -f "$STATUS_FIFO"
}

# Display the user-facing name from the same map.txt used by MinUI.
system_label() {
    tag=$1
    alias=""
    if [ -f "$ROMS/map.txt" ]; then
        alias=$(awk -F '[;\t]' -v tag="$tag" '$1 == tag { print $2; exit }' "$ROMS/map.txt")
        alias=$(printf '%s' "$alias" | tr -d '\r')
    fi
    [ -n "$alias" ] || alias=$tag
    printf '%s\n' "${alias#.}"
}


mkdir -p "$MINUI/logs"

# Pick a random installed system first instead of scanning *every* ROM on
# every launch. On the Model S a full-card scan can take a long time.
# Systems have equal weight; games within the selected system are uniform.
SYSTEM_LIST="/tmp/minui-random-systems.$$"
cleanup() {
    stop_status
    rm -f "$SYSTEM_LIST"
}
trap cleanup 0
trap 'exit 1' HUP INT TERM

{
    for SYSTEM in "$ROMS"/*; do
        [ -d "$SYSTEM" ] || continue
        TAG=${SYSTEM##*/}
        [ "$TAG" = GME ] && continue  # Music files are not games.
        [ -f "$EMUS/$TAG.pak/launch.sh" ] ||
            [ -f "$EMUS/$TAG-picoarch.pak/launch.sh" ] || continue
        printf '%s\n' "$SYSTEM"
    done
} | awk '
    BEGIN { srand() }
    { systems[NR] = $0 }
    END {
        count = NR
        while (count > 0) {
            pick = 1 + int(rand() * count)
            print systems[pick]
            systems[pick] = systems[count]
            count--
        }
    }
' > "$SYSTEM_LIST"

printf 'Random Game: starting search\n' > "$LOG"
start_status
GAME=""

# Try systems in random order. Normally the first system is sufficient.
# If it has no playable entries, move on to the next one.
while IFS= read -r SYSTEM; do
    TAG=${SYSTEM##*/}
    printf 'Scanning system: %s\n' "$TAG" >> "$LOG"
    if [ "$STATUS_ACTIVE" -eq 1 ]; then
        (system_label "$TAG" >&3) 2>/dev/null || :
    fi
    GAME=$(
        find "$SYSTEM" \
            \( -type d \( -name '.*' -o -name res -o -name media \) -prune \) -o \
            \( -type f -print \) | awk -v root="$ROMS" '
    BEGIN {
        srand()
        allowed = "|zip|gno|nes|fds|unf|unif|gb|gbc|dmg|gba|gg|sms|sg|col|rom|ri|mx1|mx2|dsk|cas|sc|md|gen|smd|32x|68k|sgd|cue|m3u|chd|ccd|toc|iso|pbp|img|mdf|cbn|bin|pce|ngp|ngc|ngpc|npc|ws|wsc|pc2|smc|sfc|fig|gd3|gd7|dx2|bsx|swc|a26|a78|cdf|lnx|lyx|min|o|p8|ay|gbs|gym|hes|kss|nsf|nsfe|sap|spc|vgm|vgz|"
        read_map(root, 1)
    }
    function read_map(dir, is_root,    line, separator, tab, key, value, target) {
        if (dir in loaded) return
        loaded[dir] = 1
        while ((getline line < (dir "/map.txt")) > 0) {
            sub(/\r$/, "", line)
            separator = index(line, ";")
            tab = index(line, "\t")
            if (tab && (!separator || tab < separator)) separator = tab
            if (!separator) continue
            key = substr(line, 1, separator - 1)
            value = substr(line, separator + 1)
            if (substr(value, 1, 1) == ".") {
                target = dir "/" key
                hidden[target] = 1
            }
        }
        close(dir "/map.txt")
    }
    {
        path = $0
        relative = substr(path, length(root) + 2)
        sys_tag = relative
        sub(/\/.*/, "", sys_tag)
        if ((root "/" sys_tag) in hidden) next

        name = path
        sub(/^.*\//, "", name)
        if (substr(name, 1, 1) == ".") next
        if (tolower(name) ~ /^\[bios\]/ || tolower(name) ~ /^\(bios\)/) next
        if (index(name, ".") == 0) next
        ext = tolower(name)
        sub(/^.*\./, "", ext)
        if (index(allowed, "|" ext "|") == 0 && !(sys_tag == "PICO8" && ext == "png")) next

        dir = path
        sub("/[^/]*$", "", dir)
        read_map(dir, 0)
        if (path in hidden) next

        # Prefer one playlist entry over its individual disc .cue files.
        if (ext == "cue") {
            folder = dir
            sub(/^.*\//, "", folder)
            playlist = dir "/" folder ".m3u"
            if ((getline unused < playlist) >= 0) {
                close(playlist)
                next
            }
            close(playlist)
        }
        # Do not randomly pick a raw track when there is a matching cue sheet.
        if (ext == "bin" || ext == "img" || ext == "iso") {
            cue = path
            sub("[.][^./]+$", ".cue", cue)
            if ((getline unused < cue) >= 0) {
                close(cue)
                next
            }
            close(cue)
        }

        count++
        if (int(rand() * count) == 0) chosen = path
    }
    END { if (count) print chosen }
        '
    )
    [ -n "$GAME" ] && break
done < "$SYSTEM_LIST"
rm -f "$SYSTEM_LIST"

if [ -z "$GAME" ]; then
    printf 'No playable ROMs found.\n' >> "$LOG"
    exit 0
fi

# A playlist is one game. Start at its first existing disc (as MinUI does).
case "$GAME" in
    *.[mM]3[uU])
        PLAYLIST_DIR=${GAME%/*}
        DISC=""
        while IFS= read -r LINE || [ -n "$LINE" ]; do
            LINE=$(printf '%s' "$LINE" | tr -d '\r')
            case "$LINE" in ''|\#*) continue ;; esac
            case "$LINE" in
                /*) CANDIDATE=$LINE ;;
                *) CANDIDATE="$PLAYLIST_DIR/$LINE" ;;
            esac
            if [ -f "$CANDIDATE" ]; then
                DISC=$CANDIDATE
                break
            fi
        done < "$GAME"
        if [ -z "$DISC" ]; then
            printf 'No usable disc in playlist: %s\n' "$GAME" >> "$LOG"
            exit 0
        fi
        GAME=$DISC
        ;;
esac

RELATIVE=${GAME#"$ROMS"/}
TAG=${RELATIVE%%/*}
STANDALONE="$EMUS/$TAG.pak/launch.sh"
PICOARCH="$EMUS/$TAG-picoarch.pak/launch.sh"

# Match MinUI main.c: prefer-picoarch chooses the preferred implementation,
# with a fallback to the other one when it is not installed.
if [ -f "$MINUI/prefer-picoarch" ]; then
    if [ -f "$PICOARCH" ]; then LAUNCH=$PICOARCH
    else LAUNCH=$STANDALONE
    fi
else
    if [ -f "$STANDALONE" ]; then LAUNCH=$STANDALONE
    else LAUNCH=$PICOARCH
    fi
fi
[ -f "$LAUNCH" ] || exit 1

# The launcher has already exited to run this tool. Keep its recents and
# selected-ROM restoration behavior consistent with a regular game launch.
TMP="$RECENTS.random.tmp"
{
    printf '%s\n' "$GAME"
    if [ -f "$RECENTS" ]; then
        awk -v game="$GAME" '$0 != game && NF && ++count < 40 {print}' "$RECENTS"
    fi
} > "$TMP" && mv -f "$TMP" "$RECENTS"
printf '%s' "$GAME" > /tmp/last.txt

printf 'Selected: %s\nLauncher: %s\n' "$GAME" "$LAUNCH" >> "$LOG"
stop_status
exec "$LAUNCH" "$GAME"
