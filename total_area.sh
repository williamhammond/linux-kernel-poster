#! /bin/sh

# Figure out the total area for all the .ps file arguments.
TOTAL=0

# Last line of PS file is the bounding box (% Bounding xmin ymin xmax ymax).
for f; do
    TOTAL=`tail -1 $f | awk '{ print "'$TOTAL' + ( " $5 " - " $3 " ) * ( " $6 " - " $4 " )" }' | bc`
done
echo $TOTAL
    
