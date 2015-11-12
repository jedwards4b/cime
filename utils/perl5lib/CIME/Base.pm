package CIME::Base;
use 5.10.0;
use strict;
use warnings;
use Getopt::Long qw(GetOptions :config pass_through auto_help);
use Pod::Usage;
use base 'ToolSet';
use Log::Log4perl qw(get_logger);
ToolSet->use_pragma('strict');
ToolSet->use_pragma('warnings');
ToolSet->export('Log::Log4perl'=>qw(get_logger ),
		'Data::Dumper'=>undef,
		'XML::LibXML' => undef,
		'Getopt::Long'=>qw(GetOptions),
);

our $VERSION = "0.1";



$SIG{__DIE__} = sub {
   if($^S) {
      # We're in an eval {} and don't want log
      # this message but catch it later
      return;
   }
   $Log::Log4perl::caller_depth++;
   my $logger = get_logger("");
   $logger->fatal(@_);
   die @_; # Now terminate really
};




sub new {
     my $class = shift();
     my $this = {};
     
     bless($this, $class);
     $this->_init(@_);
     return $this;
}

sub _init {
  my ($this) = @_;
  $this->SUPER::_init();
  
  Log::Log4perl->init(\q{
        log4perl.category         = FATAL, Logfile
        log4perl.appender.Logfile = Log::Log4perl::Appender::File
        log4perl.appender.Logfile.filename = fatal_errors.log
        log4perl.appender.Logfile.layout = \
                   Log::Log4perl::Layout::PatternLayout
        log4perl.appender.Logfile.layout.ConversionPattern = %F{1}-%L (%M)> %m%n
    });
}


sub getopts {
    my ($self, $opts) = @_;
    # Set default values here, 
    # be careful not to overwrite defaults passed in
    $opts->{loglevel} = "INFO" unless(defined $opts->{loglevel});
    $opts->{help} = 0 unless(defined $opts->{help});
    
    # These are the options supported by all cime perl tools
    GetOptions("loglevel=s" => \$opts->{loglevel},
	       "h|help" => \$opts->{help},
	) or pod2usage(2);
    pod2usage(1) if($opts->{help});
    
}
1;
    
__END__
=head1 NAME

CIME::Base - Base functionality for perl in CIME

=head1 SYNOPSIS

    sample [options] [file ...]
     Options:
       -help            brief help message
       -loglevel        DEBUG,INFO,WARN,ERROR,FATAL
=head1 OPTIONS
=over 8
=item B<-help>
Print a brief help message and exits.
=item B<-loglevel>
    
=back
=head1 DESCRIPTION
B<This program> will read the given input file(s) and do something
useful with the contents thereof.
=cut



