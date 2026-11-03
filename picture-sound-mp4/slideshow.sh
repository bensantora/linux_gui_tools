#!/usr/bin/env bash
# slideshow.sh - build an MP4 slideshow from a folder of images.
#
# Images are shown in natural filename order (01, 02, 10 - not 01, 10, 02).
# Output is always WxH (default 1920x1080); images keep their aspect ratio and
# are either letterboxed on black or centred over a blurred copy of themselves.

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./slideshow.sh [options] [IMAGE_DIR]

Build an MP4 slideshow from the images in IMAGE_DIR (default: current dir).
Images are sorted naturally by filename. Supported: png, jpg, jpeg, webp,
bmp, tif, tiff.

Options:
  -d, --duration SEC   seconds per image           (default: 6)
  -o, --output FILE    output file                 (default: slideshow.mp4)
  -f, --fade SEC       fade in/out per slide; 0 off (default: 0.5)
  -b, --background M   blur | black                (default: blur)
  -m, --music FILE     loop an audio track under the slideshow
  -w, --width PX       output width                (default: 1920)
      --height PX      output height               (default: 1080)
      --fps N          output frame rate           (default: 30)
      --crf N          x264 quality, 0-51          (default: 20)
      --preset NAME    x264 preset                 (default: medium)
  -h, --help           show this help

Examples:
  ./slideshow.sh png
  ./slideshow.sh -d 8 -f 1 -o quotes.mp4 png
  ./slideshow.sh --background black --fade 0 photos
  ./slideshow.sh -d 4 --music track.mp3 photos
EOF
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

is_number() {
    [[ $1 =~ ^[0-9]+([.][0-9]+)?$ ]]
}

is_uint() {
    [[ $1 =~ ^[0-9]+$ ]]
}

require_number() {
    is_number "$1" || die "$2 must be a number (got: $1)"
}

require_positive() {
    require_number "$1" "$2"
    awk -v n="$1" 'BEGIN { exit !(n > 0) }' || die "$2 must be greater than 0 (got: $1)"
}

DUR=6
OUT=slideshow.mp4
FADE=0.5
BACKGROUND=blur
MUSIC=
WIDTH=1920
HEIGHT=1080
FPS=30
CRF=20
PRESET=medium
IMGDIR=
IMGDIR_SET=0

while (($#)); do
    case "$1" in
        -d|--duration) [[ $# -ge 2 ]] || die "$1 needs a value"; DUR=$2; shift 2 ;;
        -o|--output)   [[ $# -ge 2 ]] || die "$1 needs a value"; OUT=$2; shift 2 ;;
        -f|--fade)     [[ $# -ge 2 ]] || die "$1 needs a value"; FADE=$2; shift 2 ;;
        -b|--background) [[ $# -ge 2 ]] || die "$1 needs a value"; BACKGROUND=$2; shift 2 ;;
        -m|--music)    [[ $# -ge 2 ]] || die "$1 needs a value"; MUSIC=$2; shift 2 ;;
        -w|--width)    [[ $# -ge 2 ]] || die "$1 needs a value"; WIDTH=$2; shift 2 ;;
        --height)      [[ $# -ge 2 ]] || die "$1 needs a value"; HEIGHT=$2; shift 2 ;;
        --fps)         [[ $# -ge 2 ]] || die "$1 needs a value"; FPS=$2; shift 2 ;;
        --crf)         [[ $# -ge 2 ]] || die "$1 needs a value"; CRF=$2; shift 2 ;;
        --preset)      [[ $# -ge 2 ]] || die "$1 needs a value"; PRESET=$2; shift 2 ;;
        -h|--help)     usage; exit 0 ;;
        --)
            shift
            if (($#)); then
                ((IMGDIR_SET == 0)) || die "only one image directory can be given"
                IMGDIR=$1
                IMGDIR_SET=1
                shift
            fi
            break
            ;;
        -*)            die "unknown option: $1 (try --help)" ;;
        *)
            ((IMGDIR_SET == 0)) || die "only one image directory can be given"
            IMGDIR=$1
            IMGDIR_SET=1
            shift
            ;;
    esac
done
(($# == 0)) || die "unexpected argument: $1"

IMGDIR=${IMGDIR:-.}
[[ -n $OUT ]] || die "output filename cannot be empty"

command -v ffmpeg >/dev/null 2>&1 || die "ffmpeg is required but was not found"
[[ -d $IMGDIR ]] || die "image directory not found: $IMGDIR"

require_positive "$DUR" "duration"
require_number "$FADE" "fade"
require_positive "$FPS" "fps"
is_uint "$WIDTH" && ((10#$WIDTH > 0)) || die "width must be a positive whole number"
is_uint "$HEIGHT" && ((10#$HEIGHT > 0)) || die "height must be a positive whole number"
((10#$WIDTH % 2 == 0)) || die "width must be even for yuv420p output"
((10#$HEIGHT % 2 == 0)) || die "height must be even for yuv420p output"
is_uint "$CRF" && ((10#$CRF >= 0 && 10#$CRF <= 51)) || die "crf must be a whole number from 0 to 51"
case "$PRESET" in
    ultrafast|superfast|veryfast|faster|fast|medium|slow|slower|veryslow|placebo) ;;
    *) die "unknown x264 preset: $PRESET" ;;
esac
case "$BACKGROUND" in
    blur|black) ;;
    *) die "background must be 'blur' or 'black' (got: $BACKGROUND)" ;;
esac
if [[ -n $MUSIC ]]; then
    [[ -f $MUSIC ]] || die "music file not found: $MUSIC"
fi

# Find images, sorted naturally. -print0 / -z keeps spaces and newlines safe.
mapfile -d '' -t FILES < <(
    find "$IMGDIR" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \
           -o -iname '*.webp' -o -iname '*.bmp' -o -iname '*.tif' \
           -o -iname '*.tiff' \) \
        -print0 | sort -z -V
)
N=${#FILES[@]}
((N > 0)) || die "no images found in $IMGDIR"

# A fade longer than half a slide would overlap itself.
FADE=$(awk -v f="$FADE" -v d="$DUR" 'BEGIN { if (f > d / 2) f = d / 2; printf "%.3f", f }')
FADE_OUT_START=$(awk -v d="$DUR" -v f="$FADE" 'BEGIN { printf "%.3f", d - f }')
TOTAL=$(awk -v n="$N" -v d="$DUR" 'BEGIN { printf "%.3f", n * d }')
HAS_FADE=$(awk -v f="$FADE" 'BEGIN { print (f > 0) ? 1 : 0 }')
# Static images only need one decoded frame per second. The extra second makes
# the fps filter produce the final second of frames before trim cuts it back.
INPUT_DUR=$(awk -v d="$DUR" 'BEGIN { printf "%.3f", d + 1 }')

INPUTS=()
CHAIN=""

for i in "${!FILES[@]}"; do
    INPUTS+=(-loop 1 -framerate 1 -t "$INPUT_DUR" -i "${FILES[$i]}")

    if [[ $BACKGROUND == blur ]]; then
        CHAIN+="[$i:v]split=2[bg$i][fg$i];"
        CHAIN+="[bg$i]scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=increase:flags=bilinear,"
        CHAIN+="crop=${WIDTH}:${HEIGHT},gblur=sigma=40,"
        CHAIN+="eq=brightness=-0.08:saturation=0.9[bgv$i];"
        CHAIN+="[fg$i]scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=decrease:flags=lanczos[fgv$i];"
        CHAIN+="[bgv$i][fgv$i]overlay=(W-w)/2:(H-h)/2,setsar=1,format=yuv420p[v$i];"
    else
        CHAIN+="[$i:v]scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=decrease:flags=lanczos,"
        CHAIN+="pad=${WIDTH}:${HEIGHT}:(ow-iw)/2:(oh-ih)/2:color=black,"
        CHAIN+="setsar=1,format=yuv420p[v$i];"
    fi

    if ((HAS_FADE)); then
        CHAIN+="[v$i]fps=$FPS,trim=duration=$DUR,setpts=PTS-STARTPTS,"
        CHAIN+="fade=t=in:st=0:d=$FADE,"
        CHAIN+="fade=t=out:st=$FADE_OUT_START:d=$FADE[o$i];"
    else
        CHAIN+="[v$i]fps=$FPS,trim=duration=$DUR,setpts=PTS-STARTPTS[o$i];"
    fi
done

if ((N == 1)); then
    CHAIN=${CHAIN%;}
    VIDEO_MAP="[o0]"
else
    for i in "${!FILES[@]}"; do
        CHAIN+="[o$i]"
    done
    CHAIN+="concat=n=${N}:v=1:a=0[vout]"
    VIDEO_MAP="[vout]"
fi

ARGS=(ffmpeg -y -hide_banner -loglevel warning -stats "${INPUTS[@]}")

if [[ -n $MUSIC ]]; then
    ARGS+=(-stream_loop -1 -i "$MUSIC")
fi

ARGS+=(
    -filter_complex "$CHAIN"
    -map "$VIDEO_MAP"
    -c:v libx264
    -preset "$PRESET"
    -crf "$CRF"
    -pix_fmt yuv420p
    -r "$FPS"
)

if [[ -n $MUSIC ]]; then
    ARGS+=(-map "$N:a:0")
    AUDIO_FADE_START=$(awk -v t="$TOTAL" 'BEGIN { s = t - 2; if (s < 0) s = 0; printf "%.3f", s }')
    AUDIO_FADE_DUR=$(awk -v t="$TOTAL" 'BEGIN { d = 2; if (d > t) d = t; printf "%.3f", d }')
    ARGS+=(-af "afade=t=out:st=$AUDIO_FADE_START:d=$AUDIO_FADE_DUR" -c:a aac -b:a 192k)
else
    ARGS+=(-an)
fi

ARGS+=(-t "$TOTAL")

case "${OUT,,}" in
    *.mp4|*.m4v|*.mov) ARGS+=(-movflags +faststart) ;;
esac

ARGS+=("$OUT")

mkdir -p "$(dirname "$OUT")"

printf 'Slideshow: %d images x %ss = %ss\n' "$N" "$DUR" "$TOTAL"
printf 'Output:    %s (%sx%s, %s fps, %s background)\n' "$OUT" "$WIDTH" "$HEIGHT" "$FPS" "$BACKGROUND"

if ! "${ARGS[@]}"; then
    die "ffmpeg failed"
fi

printf 'Done: %s\n' "$OUT"
du -h "$OUT" | cut -f1 | awk -v f="$OUT" '{ print "Size: " $1 " (" f ")" }'
