package CIME::ConfigCase;

use CIME::Base;
use Log::Log4perl;
my $logger;

BEGIN{
    $logger = Log::Log4perl::get_logger();
}

sub new {
    my ($class, $compset) = @_;
    my $this = {};
     
    bless($this, $class);
    $this->_init(@_);
    return $this;
}

sub _init {
    my ($this, $compset) = @_;

    

}




1;
