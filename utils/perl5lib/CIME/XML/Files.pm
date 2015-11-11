package CIME::XML::Files;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use parent 'CIME::XML::GenericEntry';

my $logger;

BEGIN{
    $logger = get_logger();
}

sub new {
    my ($class, $params) = @_;
    my $this = {};


    print Dumper($params);

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
