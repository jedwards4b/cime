package CIME::XML::ConfigComponent;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use parent 'CIME::XML::GenericEntry';

my $logger;

BEGIN{
    $logger = get_logger();
}

sub new {
    my ($class, $file) = @_;
    my $this = {};

    bless($this, $class);
    $this->_init($file);
    return $this;
}

sub _init {
  my ($this,$file) = @_;
  $this->SUPER::_init();
  $this->{filename} = $file;
  $this->read($file);
}

sub read {
    my($this,$file) = @_;

    $this->SUPER::read($file);

}

sub GetValue {
    my($this, $name, $attribute, $id) = @_;
    if($name eq "components"){
	my @components;
	my @compnodes = $this->{_xml}->findnodes("//components/comp");
	foreach my $node (@compnodes){
	    push(@components,$node->textContent());
	}
	return @components; 
    }else{
	$this->SUPER->GetValue($name, $attribute, $id);
    }
    
}


sub CompsetMatch
{
    my($this,$compset_request) = @_;
    my $compset_longname;
    # Look for a match for compset_request in this components config_compsets.xml file
    my @alias_nodes = $this->{_xml}->findnodes(".//compset[alias=\"$compset_request\"]");
    if (@alias_nodes) {
	if ($#alias_nodes > 0) {
	    $logger->logdie("ERROR create_newcase: more than one match for alias element in file $this->{filename} ");
	} else {
	    my @name_nodes = $alias_nodes[0]->findnodes(".//lname");
	    foreach my $name_node (@name_nodes) {
		$compset_longname = $name_node->textContent();
	    }
	}
    } 
    if(! defined $compset_longname){
	# If no alias match - then determine if there is a match for the longname
	my @lname_nodes = $this->{_xml}->findnodes(".//compset[lname=\"$compset_request\"]");
	if (@lname_nodes) {
	    if ($#lname_nodes > 0) {
		$logger->logdie("ERROR create_newcase: more than one match for lname element in file $this->{filename}");
	    } else {
		my @name_nodes = $lname_nodes[0]->findnodes(".//lname");
		foreach my $name_node (@name_nodes) {
		    $compset_longname = $name_node->textContent();
		}
	    }
	} 
    }
    return $compset_longname;
}

1;
    
__END__

=head1 CIME::XML::Files

CIME::XML::Files a module interface to the file config_files.xml

=head1 SYNOPSIS

  use CIME::XML::Files;

  my $files = CIME::XML::Files->new();
  


=head1 DESCRIPTION

CIME::XML::Files is a perl module to ...
       
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
