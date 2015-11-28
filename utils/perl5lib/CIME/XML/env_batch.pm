package CIME::XML::env_batch;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use CIME::XML::Headers;

use parent 'CIME::XML::GenericEntry';

my $logger;

our $VERSION = "v0.0.1";

my @subgroups = qw(run test st_archive lt_archive);

BEGIN{
    $logger = get_logger("CIME::XML::env_batch");
}

sub new {
     my ($class, $cimeroot, $file) = @_;
     my $this = {CIMEROOT=>$cimeroot};
     
     bless($this, $class);
     $this->_init($file);
     return $this;
}

sub _init {
  my ($this, $file) = @_;

  $this->SUPER::_init($file);
  if(defined $file){
# if the file is found read it, otherwise create an xml object (not a file - that comes later). 
      if( -f $file){
	  $this->read($file);
      }else{
	  my $headerobj = CIME::XML::Headers->new($this->{CIMEROOT});
	  my $headernode = $headerobj->GetHeaderNode("env_batch.xml");	  
	  $this->{root}->addChild($headernode);	  
	      # Now we duplicate for each subgroup
	  foreach my $job (@subgroups){
	      my $jobnode = $this->{_xml}->createElement("job");
	      $jobnode->setAttribute("id",$job);
	      $this->{root}->addChild($jobnode);
	      $this->{jobnode}{$job}=$jobnode;
	  }

      }	  
  }
}


sub AddElementsByGroup
{
    my($this, $srcdoc, $attlist) = @_;

    # Add elements from srcdoc to the env_batch.xml file under the
    # appropriate group element.  Add the group if it does not already
    # exist, remove group and file children from the entry    

    # env_batch repeats the same entries for each of @subgroups
    # So we need to clone the new nodes here.

    my $baseroot = $this->{root};
    
    $this->{root} = $this->{jobnode}{$subgroups[0]};
    $this->SUPER::AddElementsByGroup($srcdoc,$attlist, "env_batch.xml");    
    
    foreach my $job (@subgroups){
	next if($this->{jobnode}{$job}==$this->{root});
	if(! $this->{jobnode}{$job}->hasChildNodes()){
	    my $newnode = $this->{root}->firstChild()->cloneNode(1);
	    $this->{jobnode}{$job}->addChild($newnode);
	}
    }

    $this->{root} = $baseroot;
}

sub SetValue{
    my ($this, $id, $value, $jobid) = @_;
    my $val;
    my @jobids;
    my $xpath;
    if(defined $jobid){
	$xpath = "//job[\@id=\"$jobid\"]/group/entry[\@id=\"$id\"]";
    }else{
	$xpath = "//entry[\@id=\"$id\"]";
    }
    
    my @tnodes = $this->{_xml}->findnodes($xpath);
    if(@tnodes){
	foreach my $tnode (@tnodes){
	    $val = $this->SUPER::SetValue($tnode, $value);
	}
    }
    return $val;

}


sub write {
    my ($this) = @_;

    $this->SUPER::write("env_batch.xml");
    
}

1;
 
=head1 CIME::XML::env_batch

CIME::XML::env_batch a module interface to the file env_batch.xml in the case directory

=head1 SYNOPSIS

  use CIME::XML::env_batch;

  why??


=head1 DESCRIPTION

CIME::XML::env_batch is a perl module to ...
       
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

CIME::XML::env_batch inherits from CIME::XML::GenericEntry, please see
the description of that module for inherited interfaces.

=head1 AUTHOR AND CREDITS

{name and e-mail}

{Other credits}

=head1 COPYRIGHT AND LICENSE


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
__END__
