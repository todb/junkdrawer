#!/bin/zsh
# --- source clip -------------------------------------------------------
SRC=claire-tex-dems.mkv
STIME=230.35   # seek start in source video, seconds
DUR=5.6          # clip length, seconds
FPS=12         # output frame rate
GIFW=480       # output width (height auto)

# --- caption style -------------------------------------------------------
FONT="/System/Library/Fonts/Supplemental/Impact.ttf"
# FONT="/Users/todb/Library/Fonts/Anton-Regular.ttf"   # alternate — comment/uncomment, don't duplicate
FILLPCT=92     # caption width as % of frame width (imgflip-style fill)
MAXHPCT=22     # caption height cap as % of frame height (keeps short words from covering her face)
KERNING=-2     # negative = tighter letter tracking
STROKEFRAC=16  # strokewidth = pointsize / STROKEFRAC

# --- sentence build-up ---------------------------------------------------
# each word joins the sentence (and stays) starting at its frame number;
# read these straight off working/frames/f_NNNN.png, not off a stopwatch.
# size is fixed to fit the FULL sentence so text never jumps size mid-build,
# and once the last word lands, the whole sentence just lingers to the end.
WORDS=("LET'S" "FUCKING" "GO!")
STARTS=(8 12 18)

OUT=claire-lets-fucking-go.gif

# all scratch output (clip.gif, extracted/annotated frames) lives here so it
# can be gitignored wholesale -- only $SRC and $OUT are meant to be committed
WORKDIR=working
# -------------------------------------------------------------------------

mkdir -p $WORKDIR &&
ffmpeg -ss $STIME -t $DUR -i $SRC -vf "fps=$FPS,scale=$GIFW:-1" -y $WORKDIR/clip.gif &&
rm -rf $WORKDIR/frames && mkdir -p $WORKDIR/frames && magick $WORKDIR/clip.gif -coalesce $WORKDIR/frames/f_%04d.png &&
read GIFW GIFH <<< "$(magick identify -format '%w %h' $WORKDIR/frames/f_0000.png)" &&

# one fixed pointsize/strokewidth, sized to the full final sentence
FULLTXT="${(j: :)WORDS}" &&
read tw th <<< "$(magick -font "$FONT" -pointsize 100 -kerning $KERNING label:"$FULLTXT" -format '%w %h' info:)" &&
ps_w=$(( 100 * (GIFW * FILLPCT / 100) / tw )) &&
ps_h=$(( 100 * (GIFH * MAXHPCT / 100) / th )) &&
ps=$(( ps_w < ps_h ? ps_w : ps_h )) &&
sw=$(( ps / STROKEFRAC )) &&

# left edge that centers the FULL sentence at $ps; every partial string draws
# pinned to this same edge (gravity West, not South) so words grow rightward
# instead of the whole block re-centering (and jumping left) each time a word
# is appended -- Impact isn't monospace, but anchoring the whole growing
# string at one fixed left edge makes that irrelevant.
read full_w full_h <<< "$(magick -font "$FONT" -pointsize $ps -kerning $KERNING label:"$FULLTXT" -format '%w %h' info:)" &&
x0=$(( (GIFW - full_w) / 2 )) &&

for f in $WORKDIR/frames/f_*.png; do
  idx=$(basename "$f" .png | sed "s/f_//"); idx=$((10#$idx))
  txt=""
  for i in {1..${#WORDS[@]}}; do
    (( idx >= STARTS[i] )) && txt="${txt:+$txt }${WORDS[i]}"
  done
  if [ -n "$txt" ]; then
    magick "$f" -gravity SouthWest -font "$FONT" -pointsize $ps -kerning $KERNING \
      -fill white -stroke black -strokewidth $sw -annotate +${x0}+15 "$txt" "$f"
  fi
done &&
magick -delay $((100/FPS)) -loop 0 $WORKDIR/frames/f_*.png $OUT
