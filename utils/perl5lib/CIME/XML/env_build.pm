package CIME::XML::env_build;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use CIME::XML::Headers;

use parent 'CIME::XML::GenericEntry';

my $logger;

our $VERSION = "v0.0.1";


BEGIN{
    $logger = get_logger("CIME::XML::env_build");
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
	  my $headernode = $headerobj->GetHeaderNode("env_build.xml");	  
#	  my $newheader = $this->{_xml}->createElement('header');
#	  $this->{_xml}->addChild($headernode);
	  $this->{root}->addChild($headernode);	  
      }	  
  }
}


sub AddElementsByGroup
{
    my($this, $srcdoc) = @_;

    # Add elements from srcdoc to the env_build.xml file under the appropriate
    # group element.  Add the group if it does not already exist, remove group and
    # file children from the entry

    $this->SUPER::AddElementsByGroup($srcdoc,"env_build.xml");
    
}




sub write {
    my ($this) = @_;

    $this->SUPER::write("env_build.xml");
    
}

1;
 
=head1 CIME::XML::env_build

CIME::XML::env_build a module interface to the file env_build.xml in the case directory

=head1 SYNOPSIS

  use CIME::XML::env_build;

  why??


=head1 DESCRIPTION

CIME::XML::env_build is a perl module to ...
       
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

CIME::XML::env_build inherits from CIME::XML::GenericEntry, please see the description of that module 
for inherited interfaces.   

=head1 AUTHOR AND CREDITS

{name and e-mail}

{Other credits}

=head1 COPYRIGHT AND LICENSE


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
__END__
