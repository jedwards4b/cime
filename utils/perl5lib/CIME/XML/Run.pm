package CIME::XML::Run;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use CIME::XML::Headers;

use parent 'CIME::XML::GenericEntry';

my $logger;

BEGIN{
    $logger = Log::Log4perl::get_logger();
}

sub new {
     my ($class, $cimeroot) = @_;
     my $this = {CIMEROOT=>$cimeroot};
     
     bless($this, $class);
     $this->_init(@_);
     return $this;
}

sub _init {
  my ($this) = @_;
  $this->SUPER::_init();

}

sub read {
    my($this,$file) = @_;
    $this->SUPER::read($file);
}



sub write {
    my ($this) = @_;

    my $headerobj = CIME::XML::Headers->new($this->{CIMEROOT});

    my $headernode = $headerobj->GetHeaderNode("env_run.xml");

    $this->SUPER::write("env_run.xml",$headernode);

    
}

1;
 
