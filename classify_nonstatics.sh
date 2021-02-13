#! /bin/sh
# Takes a kernel dir and group of non-static functions, searches for them

TMPFILE=`mktemp ${TMPDIR:-/tmp}/$$.XXXXXX`

KERNEL_DIR=$1

shift
#  We eliminate strings, but eliminating comments is harder (do by
# hand).  Note this also catches EXPORT_SYMBOL as indirect (true, in a
# way).

REGEX=`for f; do echo "$f" | sed s/.*\\\.c\\\.// | sed s/\\\.+NONSTATIC+\\\$//; done | tr '\12' '|' | sed 's/|$//'`

# One sweep to grab all candidates.
find $KERNEL_DIR -name '*.c' | xargs egrep --no-filename -w "$REGEX" | grep -v '^ *\*' > $TMPFILE

#echo Got file of `wc -l < $TMPFILE` lines.

# Function to try to see if function $1 is used indirectly in stdin.
used_indirectly()
{
    # Eliminate strings, comments, compiler directives, occurances
    # followed by an optional space then '[A-Za-z0-9`'', occurances
    # preceeded by ->, lines starting with ' *', and finally real
    # function calls
    # FIXME: We can detect comment lines by occurrances of two
    # consecutive non-keywords without punctuation between them.
    sed -e 's/"[^"]*"//g' -e 's/\/\*.*\*\///' -e 's://.*$::' -e 's/#.*//' -e 's/\/\*[^*]*$//' -e "s/$1 *[A-Za-z0-9'\`]//" | grep -v "$1 *(" | grep -v -- "->$1" | fgrep -w "$1"
}

for f
do
    NAME=`echo $f | sed s/.*\\\.c\\\.// | sed s/\\\.+NONSTATIC+\\\$//`

    FIND="`used_indirectly $NAME < $TMPFILE`"
    if [ -n "$FIND" ]
    then
	if echo "$FIND" | grep -q EXPORT_SYMBOL
	then
	    #echo $f $NAME is EXPORTED: "`echo \"$FIND\"`"
	    mv $f `echo $f | sed 's/+NONSTATIC+/+EXPORTED+/'`
	else
	    #echo $f $NAME is INDIRECT: "`echo \"$FIND\"`"
	    mv $f `echo $f | sed 's/+NONSTATIC+/+INDIRECT+/'`
	fi
    else
	mv $f `echo $f | sed 's/+NONSTATIC+/+NORMAL+/'`
    fi
done

rm $TMPFILE
