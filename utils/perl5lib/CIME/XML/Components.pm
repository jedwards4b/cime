package CIME::XML::Components;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
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
    my($this,$file,$srcroot,$cimeroot,$model) = @_;
    $this->SUPER::read($file);

    $this->resolve(qr(\$MODEL),$model);
    $this->resolve(qr(\$CIMEROOT),$cimeroot);
    $this->resolve(qr(\$SRCROOT),$srcroot);
}
1;
 
