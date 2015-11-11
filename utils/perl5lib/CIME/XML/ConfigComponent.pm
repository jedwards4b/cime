package CIME::XML::ConfigComponent;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use parent 'CIME::XML::GenericEntry';

my $logger;

BEGIN{
    $logger = get_logger();
}

sub new {
    my ($class, $files, $component) = @_;
    my $this = {};

    bless($this, $class);
    $this->_init($files,$component);
    return $this;
}

sub _init {
  my ($this,$files, $component) = @_;
  $this->SUPER::_init();

  my $file = $files->GetValue('COMPSETS_SPEC_FILE','component',$component);

  print "file = $file $component\n";
  $this->set($component, $this->read($file); 
}

sub read {
    my($this,$file) = @_;

    $this->SUPER::read($file);

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
