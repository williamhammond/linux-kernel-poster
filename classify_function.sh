#! /bin/sh

# Given a filename and kernel directory, figure out if it's referred
# to elsewhere; rename it accordingly.

NAME=`echo $1 | sed s/.*\\\.c\\\.//`

STATIC="`while read LINE; do [ \"$LINE\" = \"{\" ] && break; echo \"$LINE\"; done < $1 | grep 'static' | grep -v '[A-Za-z0-9_]static' | grep -v 'static[A-Za-z0-9_]'`"

# Function to try to see if function $1 is used indirectly in stdin.
used_indirectly()
{
    # Eliminate strings, comments, lines starting with *, occurances
    # followed by an optional space then '[A-Za-z0-9`'', and finally
    # real function calls
    sed 's/"[^"]*"//g' | sed 's/\/\*.*\*\///' | sed 's/^ *\*.*$//' | sed 's/\/\*[^*]*$//' | sed "s/$1 *[A-Za-z0-9'\`]//" | grep -v "$1 *(" | fgrep -w "$1"
}

if [ "$STATIC" = "" ]
then
    # Have to search entire kernel tree for references, so we do this later.
    mv $1 $1.+NONSTATIC+
else
    # Only need to grep this file for references.
    FILE=$2/`echo $1 | sed s/\\\.c\\\..*$//`.c
    if [ -n "`used_indirectly $NAME < $FILE`" ]
    then
#	# Report if it's not the most common cases: = foo or foo,
#	if [ -z "`used_indirectly $NAME < $FILE | grep =\ \*$NAME`" \
#	    -a -z "`used_indirectly $NAME < $FILE | grep $NAME\ \*,`" ]
#	then
#	    echo -n $1 $NAME is STATIC INDIRECT:
#	    used_indirectly $NAME < $FILE
#	fi
        mv $1 $1.+INDIRECT+
    else
	mv $1 $1.+STATIC+
    fi
fi
