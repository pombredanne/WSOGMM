#!/usr/bin/perl

# snr -- a small perl script to perform a batch search-n-replace.
# Murtaza Gulamali (20/11/2002)
# usage: snr <search_term> <replace_term> <filename>
# where wildcards are allowed in the filename.

$ARGV[2] || die
     "snr -- a small perl script to perform a batch search-n-replace.\n"
    ."Usage: snr <search_term> <replace_term> <filename>\n"
    ."Filename may contain wildcards.  Symbols in arguments must be delimited.\n";

$search  = $ARGV[0];
$replace = $ARGV[1];
@filez   = glob $ARGV[2];
$m = @filez;
$n = 0;

if ($m>0) {
    for ($i=0; $i<$m; $i++) {
        $file = $filez[$i];
        $tmpfile = $filez[$i].".tmp";
        open(INFILE, '<'.$file);
        open(OUTFILE, '>'.$tmpfile);
        while(<INFILE>) {
            if (eof) { close(INFILE); }
            if (/$search/) {
                s/$search/$replace/;
                $n++;
            }
            print OUTFILE $_;
        }
        close(OUTFILE);
        if ($n>0) {
            rename($tmpfile,$file);
        }
    }
    print "snr made $n substitution(s) across $m file(s).\n";
} else {
    die "Error: no files to perform search-n-replace upon.\n";
}
