#! /bin/sh
# Code to output a translated postscript.

set -e

# Get bounds of the image we're relative to.
# eg. % bound -1538.51 -1552.25 1499.18 1645.42
LEFT_BOUND=`tail -1 $3 | awk '{ print $3 }'`
LOWER_BOUND=`tail -1 $3 | awk '{ print $4 }'`
RIGHT_BOUND=`tail -1 $3 | awk '{ print $5 }'`
UPPER_BOUND=`tail -1 $3 | awk '{ print $6 }'`

case "$1"
in
    bottom-right)
	MY_RIGHT_BOUND=`tail -1 $2 | awk '{ print $5 }'`
	MY_LOWER_BOUND=`tail -1 $2 | awk '{ print $4 }'`
	echo "% Place at bottom right"
	echo gsave
	echo `echo "scale=2; $RIGHT_BOUND - $MY_RIGHT_BOUND" | bc` `echo "scale=2; $LOWER_BOUND - $MY_LOWER_BOUND" | bc` translate
	;;
    bottom-left)
	MY_LEFT_BOUND=`tail -1 $2 | awk '{ print $3 }'`
	MY_LOWER_BOUND=`tail -1 $2 | awk '{ print $4 }'`
	echo "% Place at bottom left"
	echo gsave
	echo `echo "scale=2; $LEFT_BOUND - $MY_LEFT_BOUND" | bc` `echo "scale=2; $LOWER_BOUND - $MY_LOWER_BOUND" | bc` translate
	;;
    below)
	MY_UPPER_BOUND=`tail -1 $2 | awk '{ print $6 }'`
	echo "% Place below"
	echo gsave
	echo 0 `echo "scale=2; $LOWER_BOUND - $MY_UPPER_BOUND" | bc` translate
	LOWER_BOUND=`echo "scale=2; $LOWER_BOUND - $MY_UPPER_BOUND * 2" | bc`
	;;
    above)
	MY_LOWER_BOUND=`tail -1 $2 | awk '{ print $4 }'`
	echo "% Place above"
	echo gsave
	echo 0 `echo "scale=2; $UPPER_BOUND - $MY_LOWER_BOUND" | bc` translate
	UPPER_BOUND=`echo "scale=2; $UPPER_BOUND - $MY_LOWER_BOUND * 2" | bc`
	;;
    *)
	echo place.sh: Unimplemented position "$1" >&2
	exit 1
        ;;
esac

cat $2
echo grestore
echo "% bound $LEFT_BOUND $LOWER_BOUND $RIGHT_BOUND $UPPER_BOUND"
