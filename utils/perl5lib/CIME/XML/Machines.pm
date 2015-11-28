package CIME::XML::Machines;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
my $logger;

our $VERSION = "v0.0.1";

BEGIN{
    $logger = get_logger();
}
sub new {
    my ($class, $file, $machine) = @_;
    my $this = {};
  
    bless($this, $class);
    $this->_init($file, $machine);
    return $this;
}

sub _init {
    my ($this, $file, $machine) = @_;
    
    if(! -f $file){
	$logger->logdie("Could not find or open file $file");
    }
    $logger->debug("Opening file $file to read");
    $this->{_xml} = XML::LibXML->new( (no_blanks => 1, ))->parse_file($file);
    my $nodelist = $this->{_xml}->find("//machine[\@MACH=\"$machine\"]");
    if($nodelist->size > 1){
	$logger->logdie("Too many matches for $machine in $file");
    }
    $this->{root} = $nodelist->get_node(1);
    if(! defined $this->{root}){
	$logger->logdie("No match for $machine in $file");
    } 
}

sub getNodeNames {
    my ($this) = @_;
    
    my @nodes = $this->{root}->findnodes(".//*");
    my @names;
    foreach my $node (@nodes){
	next unless ($node->parentNode == $this->{root});
	my $name = $node->nodeName();
	push(@names, $name);
    }
    return @names;
}



sub getValue {
    my ($this, $name) = @_;
    my $val;
    my @nodes = $this->{root}->findnodes(".//$name");

    if($#nodes == 0){
	$val = $nodes[0]->textContent();
    }elsif($#nodes>0){
	$logger->debug("Too many matches for $name ");
    }
    
    return $val;
}

sub getValues {
    my ($this, $id) = @_;

    my @nodes = $this->{root}->findnodes(".//$id");
    if($#nodes != 0){
	$logger->logdie("Expecting exactly one match for $id got $#nodes");
    }
    my @list = split(/,/,$nodes[0]->textContent);
    return @list;
}


sub getMPIlib {
    my ($this, $mpilib) = @_;

    my @mpilibs = $this->getValues("MPILIBS");

    

    if(! defined $mpilib or $mpilib eq "UNSET"){
	return $mpilibs[0];
    }
    my $match = grep($mpilib, @mpilibs);
    if($match <= 0 ){
	$logger->logdie("MPIlib $mpilib not supported for Machine");
    }
    return $mpilib;

}
sub getCompiler {
    my($this, $compiler) = @_;
    
    my @compilers = $this->getValues("COMPILERS");



    if(! defined $compiler or $compiler eq "UNSET"){
	return $compilers[0];
    }
    my $match = grep($compiler, @compilers);
    if($match <= 0 ){
	$logger->logdie("Compiler $compiler not supported for Machine");
    }
    return $compiler;

}



1;

=head1 NAME

CIME::XML::Machines a module to parse the config_machines.xml file in perl

=head1 SYNOPSIS

  use CIME::NAME;

  why??


=head1 DESCRIPTION

CIME::Name is a perl module to ...
       
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

