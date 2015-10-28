package CIME::XML::Headers;
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
  $this->read();

}

sub read {
    my($this) = @_;
    my $file = $this->{CIMEROOT}."/cime_config/config_headers.xml";
    $this->SUPER::read($file);   
}

sub GetHeaderNode{
    my($this, $fname) = @_;
    
    my $fnode  = $this->SUPER::GetNode("file",{name=>$fname});
    my $headernode = $fnode->firstChild();

    return $headernode;
}




1;
 
