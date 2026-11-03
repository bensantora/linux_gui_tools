#!/bin/bash
# picture-sound-mp4: pick ONE picture and ONE sound file, get an mp4 as long as the sound.
# Uses slideshow.sh (from linux_scripts). The video is saved in your home folder as ~/NAME.mp4
# Start it:   ./picture-sound-mp4.sh
# (Optional, no window:  ./picture-sound-mp4.sh PICTURE SOUND NAME)

# Find slideshow.sh: next to this script, else on PATH
here=$(dirname "$(readlink -f "$0")")
if [ -x "$here/slideshow.sh" ]; then SLIDE="$here/slideshow.sh"
else SLIDE=$(command -v slideshow.sh || true); fi
GUI=1

say() {   # say "title" "text" icon  - window in GUI mode, plain text otherwise
    if [ "$GUI" = 1 ]; then
        yad --title="$1" --center --width=520 --image="${3:-gtk-dialog-info}" --text="$2" --button=gtk-ok:0
    else
        echo "$1: $2" | sed 's/<[^>]*>//g'
    fi
}

[ -x "${SLIDE:-}" ] || { say "Picture + sound to mp4" "Can't find slideshow.sh (get it from linux_scripts)" gtk-dialog-error; exit 1; }

if [ $# -ge 3 ]; then
    GUI=0
    pic=$1; snd=$2; name=$3
else
    res=$(yad --title="Picture + sound to mp4" --width=580 --center --form --separator='^' \
        --text="<b>Make an mp4 from one picture and one sound file</b>\nThe video is as long as the sound. It is saved in your home folder." \
        --field="Picture:FL" "$HOME/" \
        --field="Sound (wav or mp3):FL" "$HOME/" \
        --field="Name for the video (no spaces):" "my_video" \
        --button="gtk-cancel:1" --button="Make video!gtk-ok:0") || exit 0
    IFS='^' read -r pic snd name _ <<< "$res"
fi

name=$(echo "$name" | sed 's/[^A-Za-z0-9_-]/_/g; s/_*$//'); [ -z "$name" ] && name=my_video
out="$HOME/$name.mp4"

case "${pic,,}" in
    *.png|*.jpg|*.jpeg|*.webp|*.bmp|*.tif|*.tiff) ;;
    *) say "Picture + sound to mp4" "Please pick a picture file (png, jpg, ...).\nYou picked: $pic" gtk-dialog-warning; exit 1 ;;
esac
[ -f "$pic" ] || { say "Picture + sound to mp4" "Picture not found:\n$pic" gtk-dialog-warning; exit 1; }
[ -f "$snd" ] || { say "Picture + sound to mp4" "Please pick a sound file.\nYou picked: $snd" gtk-dialog-warning; exit 1; }

dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$snd" 2>/dev/null | head -1)
if ! awk -v d="$dur" 'BEGIN { exit !(d + 0 > 0) }'; then
    say "Picture + sound to mp4" "That doesn't look like a sound file:\n$snd" gtk-dialog-warning; exit 1
fi

if [ -e "$out" ]; then
    if [ "$GUI" = 1 ]; then
        yad --title="Picture + sound to mp4" --center --width=520 --image=gtk-dialog-question \
            --text="<b>$out</b> already exists.\nReplace it?" --button="Cancel:1" --button="Replace:0" || exit 0
    else
        echo "Refusing to replace existing $out"; exit 1
    fi
fi

work=$(mktemp -d)
log="$work/log.txt"
cp "$pic" "$work/picture.${pic##*.}"       # slideshow.sh wants a folder holding only the picture
mkdir "$work/in" && mv "$work/picture.${pic##*.}" "$work/in/"

mins=$(awk -v d="$dur" 'BEGIN { printf "%d:%02d", d / 60, d % 60 }')
fifo="$work/fifo"
if [ "$GUI" = 1 ]; then
    mkfifo "$fifo"
    yad --progress --pulsate --no-buttons --center --width=460 --title="Making your video ..." \
        --text="Making a $mins video.\nThis takes a minute or two - please wait." < "$fifo" &
    ypid=$!
    exec 3> "$fifo"
fi

"$SLIDE" -d "$dur" -f 0 -m "$snd" -o "$out" "$work/in" > "$log" 2>&1
rc=$?

if [ "$GUI" = 1 ]; then
    exec 3>&-
    kill "$ypid" 2>/dev/null
fi

if [ $rc -ne 0 ] || [ ! -s "$out" ]; then
    say "Picture + sound to mp4" "Something went wrong.\n\n$(tail -n 5 "$log" | tr '\r' '\n' | tail -n 5)" gtk-dialog-error
    rm -rf "$work"; exit 1
fi
rm -rf "$work"

if [ "$GUI" = 1 ]; then
    yad --title="Picture + sound to mp4" --center --width=560 --image=gtk-yes \
        --text="<b>Your video is ready ($mins).</b>\n$out" \
        --button="Play it!gtk-media-play:0" --button="gtk-close:1"
    [ $? -eq 0 ] && { setsid vlc "$out" >/dev/null 2>&1 & }
else
    echo "Done: $out ($mins)"
fi
