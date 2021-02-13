#! /bin/sh

# Takes a set of ps images (belonging to one file) and produces a
# conglomerate picture of that file: static functions in the middle,
# others around it.  Each one gets a box about its area.
set -e

SCRUNCH=$1

shift

# box type filename font fontsize LABEL
box()
{
    if [ "$1" = "dashed" ]; then
	echo "[5] 0 setdash" >> $2.
    fi

    LEFT_BOUND=`tail -1 $2 | awk '{ print $3 }'`
    LOWER_BOUND=`tail -1 $2 | awk '{ print $4 }'`
    RIGHT_BOUND=`tail -1 $2 | awk '{ print $5 }'`
    UPPER_BOUND=`tail -1 $2 | awk '{ print $6 }'`

    # Put black box around it
    echo "0 0 0 setrgbcolor"
    echo "newpath"
    echo "$LEFT_BOUND $LOWER_BOUND moveto"
    echo "$RIGHT_BOUND $LOWER_BOUND lineto"
    echo "$RIGHT_BOUND $UPPER_BOUND lineto"
    echo "$LEFT_BOUND $UPPER_BOUND lineto"
    echo "closepath"
    echo "stroke"

    # Put pink name in left corner.
    echo "0.8 0.4 0.4 setrgbcolor"
    echo "/$3 findfont"
    echo "$4 scalefont setfont"
    echo `echo "scale=2; $LEFT_BOUND + 6" | bc` `echo "scale=2; $LOWER_BOUND + 6" | bc` moveto
    echo "($5) show"

    if [ "$1" = "dashed" ]; then
        echo "[] 0 setdash" >> $2.
    fi

    # Output bounding box
    echo "% bound $LEFT_BOUND $LOWER_BOUND $RIGHT_BOUND $UPPER_BOUND"
}

decorate()
{
    # Color at the beginning.
    echo "$1" setrgbcolor > $2.

    # Now output the file, except last line.
    head -$(($(wc -l < $2) + 1)) $2 >> $2.

    # Draw dashed box with function name
    # FIXME Make bound cover the label as well!
    box dashed $2 Helvetica 12 `echo $2 | sed 's/^[^.]*.c.\(.*\).+.*+.*$/\1/'` >> $2.

    # Slap over the top.
    mv $2. $2
}

# Prepend colors.
for f
do
    case "$f" in
    *+STATIC+*) decorate "0.5 1 0.5" "$f";; # Light green.
    *+INDIRECT+*) decorate "0 0.7 0" "$f";; # Green.
    *+EXPORTED+*) decorate "1 0 0" "$f";; # Red.
    *+NORMAL+*) decorate "0 0 1" "$f";; # Blue.
    *) echo "Unknown extension $1" >&2; exit 1;;
    esac
done

TMPFILE=`mktemp ${TMPDIR:-/tmp}/$$.XXXXXX`

# Arrange.
../draw_arrangement $SCRUNCH 0 360 0 "$@" > $TMPFILE

FILE=`echo $1 | sed 's/\\.c\\..*$/.c/'`
echo "% Conglomeration of $FILE"

# Now output the file, except last line.
head -$(($(wc -l < $TMPFILE) + 1)) $TMPFILE

# Draw box with file name
box normal $TMPFILE Helvetica-Bold 48 $FILE

rm $TMPFILE
