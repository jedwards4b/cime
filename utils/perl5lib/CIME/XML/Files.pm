package CIME::XML::Files;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use parent 'CIME::XML::GenericEntry';

my $logger;

BEGIN{
    $logger = Log::Log4perl::get_logger();
}

sub new {
    my ($class, $params) = @_;
    my $this = {};
    if(defined $params->{CIMEROOT}){
	$this->{CIMEROOT}=$params->{CIMEROOT};
    }elsif (defined $ENV{CIMEROOT}){
	$this->{CIMEROOT}=$ENV{CIMEROOT};
    }else{
	$logger->logdie("CIMEROOT not found");
    }
    my $model;
    if(defined $params->{MODEL}){
	$model = $params->{MODEL};
    }else{
	$model = "cesm";
    }

    bless($this, $class);
    $this->_init($model);
    return $this;
}

sub _init {
  my ($this,$model) = @_;
  $this->SUPER::_init();
  my $file = $this->{CIMEROOT}."/cime_config/".$model."/config_files.xml";

  $this->read($file); 
}

sub read {
    my($this,$file) = @_;

    $this->SUPER::read($file);

    $this->resolve(qr(\$MODEL),$this->get('MODEL'));
    $this->resolve(qr(\$CIMEROOT),$this->{CIMEROOT});



}
1;
 
