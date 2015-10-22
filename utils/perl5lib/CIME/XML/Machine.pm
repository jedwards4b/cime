package CIME::XML::Machine;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use CIME::XML::Files;
use CIME::XML::Modules;

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
	if($#machnodes > 0){
	    $logger->logdie("ERROR more than one machine match for $machine in $machfile");
	}
	$logger->info("Found machine \"$machine\" in $machfile \n");
    } else {
	$logger->error( "ERROR ConfigMachine::setMachineFile: no match for machine $machine 
	                 - possible machine values are: \n");
	$this->listMachines( $machfile );
	exit -1;
    }	    
    my $node = $machnodes[0];
    foreach my $child ($node->findnodes("./*")) {
	next if ($child->nodeType() == XML_COMMENT_NODE);

	my $name = $child->nodeName();
	if($name eq "mpirun"){
	    $this->read_mpirun_node($child);
	    next;
	}

	if($name eq "module_system"){
	   $this->{module_system} = CIME::XML::Modules->new($child);
	    next;
	}
	if($name eq "batch_system"){
	    next;
	}
	if($name eq "environment_variables"){
	    next;
	}

	my $value = $child->textContent();
	$this->{$name} = $value;
    }  
}



sub read_mpirun_node
{
    my($this, $node) = @_;

    my $mpilib = 'any';
    my $threaded = 'any';
    my $compiler = 'any';
    if(defined $node->getAttribute('mpilib')){
	$mpilib = $node->getAttribute('mpilib');
    }
    if(defined $node->getAttribute('threaded')){
	$threaded = $node->getAttribute('threaded');
    }
    if($node->getAttribute('compiler')){
	$compiler = $node->getAttribute('compiler');
    }
    my @exenode = $node->findnodes("./*");
    my $exe = $exenode[0]->textContent();
    
    $this->{exectuable}{$mpilib}{$compiler}{$threaded} = $exe;
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

sub loadModules
{
    my($this) = @_;
    my $attributes={};
   
# Compiler and mpilib are in machine but what about debug hard coded for the moment
    $attributes->{compiler} = $this->get('compiler');
    $attributes->{mpilib} = $this->get('mpilib');
    $attributes->{debug} = 'false';

    $this->{module_system}->load($attributes);
}

sub get
{
    my($this, $what) = @_;


# no compiler set, get the default
    if($what eq 'compiler'){
	if(defined $this->{COMPILERS}){
	    my @compilers = split(",",$this->{COMPILERS});
	    $this->{compiler} = $compilers[0];
	} 
    }
# no mpilib set, get the default
    if($what eq 'mpilib'){
	if(defined $this->{MPILIBS}){
	    $this->{mpilib} = (split(",",$this->{MPILIBS}))[0];
	} 
    }
    if(defined $this->{$what}){
	return $this->{$what};
    }
    $logger->warn("no $what attribute found");
}


1;
 
