#! /bin/sh

# Arguments: inner circle diameter, angle divide, ring spacing, ring1
# We're in the image directory.  Do the lines.

echo "gsave"
echo "20 setlinewidth"
echo "0 0 0 setrgbcolor"

HALF_SPACING=`echo "scale=2; $3 / 2" | bc`

RING1_BOUND=`tail -1 ring1.ps | awk '{print $5}'`
RING2_BOUND=`tail -1 ring2.ps | awk '{print $5}'`
RING3_BOUND=`tail -1 ring3.ps | awk '{print $5}'`
RING4_BOUND=`tail -1 ring4.ps | awk '{print $5}'`

# Add in half of ring spacing.
RING1_BOUND=`echo "$RING1_BOUND + $HALF_SPACING" | bc`
RING2_BOUND=`echo "$RING2_BOUND + $HALF_SPACING" | bc`
RING3_BOUND=`echo "$RING3_BOUND + $HALF_SPACING" | bc`
RING4_BOUND=`echo "$RING4_BOUND + $HALF_SPACING" | bc`

# Draw circles.
echo "0 0 $1 0 360 arc"
echo "$RING1_BOUND 0 moveto"
echo "0 0 $RING1_BOUND 0 360 arc"
echo "$RING2_BOUND 0 moveto"
echo "0 0 $RING2_BOUND 0 360 arc"
echo "$RING3_BOUND 0 moveto"
echo "0 0 $RING3_BOUND 0 360 arc"
echo "$RING4_BOUND 0 moveto"
echo "0 0 $RING4_BOUND 0 360 arc"

# Label for inner ring.
echo "0 -$RING1_BOUND moveto"
echo "/Helvetica findfont"
echo "100 scalefont setfont"
echo "(`echo $4 | sed 's/ /, /g' | sed 's/^\(.*\),/\1 \& /'`) show"

# Draw ring2 dividers
# -ve because I screwed up in draw_arrangement.c
half=`echo $2 / 2 | bc`
remainder=0
echo gsave
# Rotate half back
echo "$half rotate"
for f in `find . -name '*-ring2.angle'`; do
    echo "$RING1_BOUND 0 moveto $RING2_BOUND 0 lineto stroke"
    echo `echo \( $RING2_BOUND + $RING1_BOUND \) / 2 | bc` -200 moveto
    echo "(`echo $f | sed 's/-ring2.angle//'`) show"
    echo "-`cat $f` rotate"
    echo "-$2 rotate"
done
echo grestore

# Draw ring3 dividers
remainder=0
echo gsave
# Rotate half back
echo "$half rotate"
for f in `find . -name '*-ring3.angle'`; do
    echo "$RING2_BOUND 0 moveto $RING3_BOUND 0 lineto stroke"
    echo `echo \( $RING3_BOUND + $RING2_BOUND \) / 2 | bc` -200 moveto
    echo "(`echo $f | sed 's/-ring3.angle//'`) show"
    echo "-`cat $f` rotate"
    echo "-$2 rotate"
done
echo grestore

# Draw ring4 label
for f in `find . -name '*-ring4.ps'`; do
    echo `echo \( $RING4_BOUND + $RING3_BOUND \) / 2 | bc` -200 moveto
    echo "(`echo $f | sed 's/-ring4.ps//'`) show"
done

echo "stroke"
echo "grestore"
