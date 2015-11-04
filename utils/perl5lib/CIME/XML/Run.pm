package CIME::XML::Run;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use CIME::XML::Headers;

use parent 'CIME::XML::GenericEntry';

my $logger;

our $VERSION = "v0.0.1";


BEGIN{
    $logger = get_logger();
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

sub write {
    my ($this) = @_;

    my $headerobj = CIME::XML::Headers->new($this->{CIMEROOT});

    my $headernode = $headerobj->GetHeaderNode("env_run.xml");

    $this->SUPER::write("env_run.xml",$headernode);

    
}

1;
 
=head1 CIME::XML::Run

CIME::XML::Run a module interface to the file env_run.xml in the case directory

=head1 SYNOPSIS

  use CIME::XML::Run;

  why??


=head1 DESCRIPTION

CIME::XML::Run is a perl module to ...
       
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

CIME::XML::Run inherits from CIME::XML::GenericEntry, please see the description of that module 
for inherited interfaces.   

=head1 AUTHOR AND CREDITS

{name and e-mail}

{Other credits}

=head1 COPYRIGHT AND LICENSE


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
__END__
