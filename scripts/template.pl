#!/user/bin/env perl
BEGIN{
    my $cimeroot = $ENV{CIMEROOT};
#   This is the only place we should use die.  Once the perl library
#   location is found we can use the $logger->logdie() function
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

my $logger = get_logger();

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
       -cimeroot <path>  Path to the root directory of the cime source code

=head1 OPTIONS

=over 8

=item B<-help>

Prints a brief help message and exits.

=item B<-loglevel> Set the verbosity level of this script, levels are:

=over 4

=item DEBUG (most verbose)

=item INFO (default)

=item WARN

=item ERROR

=item FATAL(least verbose) 

=back

=item B<-cimeroot>

Path to the root directory of the cime source code. This can also be set as an environment variable CIMEROOT.  The command line option takes precidence.  

=item B<-model>

The name of the model coupled with cime.  Allowed values are the names of the 
directories under cime/cime_config.  

=back

=back

=head1 DESCRIPTION

B<case.template> will do this...

=head1 AUTHOR AND CREDITS

{name and e-mail}

{Other credits}

=head1 COPYRIGHT AND LICENSE


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
