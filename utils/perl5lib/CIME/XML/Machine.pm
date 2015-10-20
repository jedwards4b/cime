package CIME::XML::Machine;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use CIME::XML::Files;

my $logger;

BEGIN{
    $logger = Log::Log4perl::get_logger();
}

sub new {
    my ($class, $params) = @_;
    my $this = {};
    if(defined $params->{FILES}){
	$this->{FILES} = $params->{FILES};
    }else{
	$this->{FILES} = CIME::XML::Files->new($params);
    }
    
    bless($this, $class);
    $this->_init(@_);
    return $this;
}

sub _init {
  my ($this) = @_;
#  $this->SUPER::_init();
}

sub read {
    my($this,$machine) = @_;
    
    my $machfile = $this->{FILES}->get('MACHINES_SPEC_FILE');
    my $machxml = XML::LibXML->new( no_blanks => 1)->parse_file($machfile);
    my @machnodes = $machxml->findnodes(".//machine[\@MACH=\"$machine\"]");
    if (@machnodes) {
	$logger->info("Found machine \"$machine\" in $machfile \n");
    } else {
	$logger->error( "ERROR ConfigMachine::setMachineFile: no match for machine $machine 
	                 - possible machine values are: \n");
	$this->listMachines( $machfile );
	exit -1;
    }	    
}
sub listMachines
{
    my($this, $machfile) = @_;

    my $parser = XML::LibXML->new( no_blanks => 1);
    my $xml = $parser->parse_file($machfile);

    $logger->warn ("  MACHINES:  name (description)\n");

    foreach my $node ($xml->findnodes(".//machine")) {
	next if ($node->nodeType() == XML_COMMENT_NODE);
	my $name = $node->getAttribute('MACH');
	foreach my $child ($node->findnodes("./*")) {
	    next if ($child->nodeType() == XML_COMMENT_NODE);
	    if ($child->nodeName() eq 'DESC') {
		my $desc = $child->textContent();
		$logger->warn( "    $name ($desc) \n");		
	    }
	}
    }

}

1;
 
