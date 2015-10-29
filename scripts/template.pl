#!/user/bin/env perl
use 5.10.0; 
BEGIN{
    my $cimeroot = $ENV{CIMEROOT};
    die "CIMEROOT environment variable not set" unless defined $cimeroot;
    die "CIMEROOT directory \"$cimeroot\" not found" unless (-d $cimeroot);
    unshift @INC, "$cimeroot/utils/perl5lib";
    require CIME::Base;
}
use CIME::Base;

use CIME::template;

my %opts;
$opts{loglevel}="INFO";

CIME::Base->getopts(\%opts);

#GetOptions("localopt=s"=>$opts{localopt});

my $level = Log::Log4perl::Level::to_priority($opts{loglevel});
Log::Log4perl->easy_init({level=>$level,
			  layout=>'%m%n'});

my $logger = Log::Log4perl::get_logger();

my $cimeroot = $ENV{CIMEROOT};

my $obj = CIME::template->new();



__END__
=head1 NAME

cime_perl_script_template - CIME script to do something

=head1 SYNOPSIS

    cime.name [options] 
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
B<case.template> will do this...
=cut
