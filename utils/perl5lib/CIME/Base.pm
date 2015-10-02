package CIME::Base;
our $VERSION = "0.1";
use strict;
use warnings;
use Getopt::Long qw(GetOptions :config pass_through);
use base 'ToolSet';
ToolSet->use_pragma('strict');
ToolSet->use_pragma('warnings');
ToolSet->export('Log::Log4perl'=>undef,
		'Getopt::Long'=>qw(GetOptions),
);


sub new {
     my $class = shift();
     my $this = {};
     
     bless($this, $class);
     $this->_init(@_);
     return $this;
}

sub _init {
  my ($this, $foo, $bar, $baz) = @_;
  $this->SUPER::_init($bar, $baz);
  $$this{foo} = $foo;
}


sub getopts {
    my ($self,$opts) = @_;
    $opts->{loglevel} = "INFO" unless(defined $opts->{loglevel});


    GetOptions("loglevel=s" => $opts->{loglevel});
}



1;
