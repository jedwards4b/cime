#!/user/bin/env perl
BEGIN{
my $cimeroot = $ENV{CIMEROOT};
die "CIMEROOT environment variable not set" unless defined $cimeroot;
die "CIMEROOT directory \"$cimeroot\" not found" unless (-d $cimeroot);
unshift @INC, "$cimeroot/utils/perl5lib";
require CIME::Base;
}
use CIME::Base;

my %opts;
$opts{localopt}=7;
$opts{loglevel}="WARN";
CIME::Base->getopts(\%opts);

GetOptions("localopt=s"=>$opts{localopt});

print "HERE @ARGV $opts{loglevel}<> $opts{localopt}\n";

