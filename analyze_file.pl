#! /usr/bin/perl -w

# FIXME: handle FASTCALL (eg mm/filemap.c's truncate_list_pages).
$INFUNC=0;

open(INPUT, "$ARGV[0]") || die "Can't open $ARGV[0]: $!\n";

@LINES=<INPUT>;

for ($i = 0; $i <= $#LINES; $i++) {
    if ($LINES[$i] =~ /^\{\s*$/) {
	$funcname = "";
	# Search back for first line with open bracket.
	for ($funstart = $i-1; $funstart >= 0; $funstart--) {
#	    print "Looking at line $funstart: $LINES[$funstart]";
	    if ($LINES[$funstart] =~ /^[A-Za-z0-9_].*[A-Za-z0-9_] ??\(/) {
		$funcname = $LINES[$funstart];
		chomp($funcname);
		$funcname =~ s/ ??\(.*$//;
		$funcname =~ s/^.*[\s\*]//;
		if ($funcname !~ /^[0-9A-Za-z_]+$/) {
		    print "Found function \`$funcname\'\n";
		}
	    }
	    if ($funcname ne "" && $LINES[$funstart] !~ /^[A-Za-z_]/) {
		$funstart++;
		last;
	    }
	    elsif ($funcname eq "" 
		   && ($LINES[$funstart] =~ /=/
		       || $LINES[$funstart] =~ /\"/
		       || $LINES[$funstart] =~ /\/\*/
		       || $LINES[$funstart] =~ /\*\//)) {
		# Dummy hit.
		last;
	    }
	}
	if ($funcname ne "") {
	    open(OUTPUT, ">$ARGV[0].$funcname")
		|| die "Can't open $ARGV[0].$funcname: $!\n";
	    for (; $funstart < $i; $funstart++) {
		print OUTPUT $LINES[$funstart];
	    }
	    $INFUNC=1;
	}
    }
    if ($INFUNC) {
	print OUTPUT $LINES[$i];
    }

    if ($LINES[$i] =~ /^\}\s*$/) {
	close(OUTPUT);
	$INFUNC=0;
    }
}

close(OUTPUT);
