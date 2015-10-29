package CIME::XML::Machine;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use CIME::XML::Files;
use CIME::XML::Modules;

my $logger;
our $VERSION = "v0.0.1";

BEGIN{
    $logger = get_logger();
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
    
    $this->{xmlnode} = $machnodes[0];
}



sub read_mpirun_node
{
    my($this) = @_;

    my $mpilib = 'any';
    my $threaded = 'any';
    my $compiler = 'any';
    my $node = $this->{xmlnode} or $logger->logdie("Node not initialized");
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
 
=head1 CIME::XML::Machine

CIME::XML::Machine perl interface module to cime config_machines.xml files

=head1 SYNOPSIS

  use CIME::XML::Machine;

  why??


=head1 DESCRIPTION

CIME::XML::Machine is a perl module to ...
       
A more complete description here.

=head2 OPTIONS

The following optional arguments are supported, passed in using a 
hash reference after the required arguments to ->new()

=over 4

=item loglevel

Sets the level of verbosity of this module, five levels are available:

=over 4

=item DEBUG (most verbose)

=item INFO  (default) 

=item WARN  (reason for concern but no error)

=item ERROR (non-fatal errors should be rare)

=item FATAL (least verbose)  

=back

=item another option

=back

=head1 SEE ALSO

=head1 AUTHOR AND CREDITS

{name and e-mail}

{Other credits}

=head1 COPYRIGHT AND LICENSE


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
__END__
