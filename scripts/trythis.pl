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


__END__
=head1 NAME

create_newcase - CIME case generator script

=head1 SYNOPSIS

    create_newcase [options] 
    Options:
       -help             brief help message
       -loglevel <level> set stdout message verbosity
       -model <name>     Specifies target model system.

=head1 OPTIONS
=over 8
=item B<-help>
Prints a brief help message and exits.
=item B<-loglevel>
Can be DEBUG (most verbose), INFO (default), WARN, ERROR, FATAL(least verbose)    
=back
=head1 DESCRIPTION
B<create_newcase> will read the given input file(s) and do something
useful with the contents thereof.
=cut
