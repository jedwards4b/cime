package CIME::Case;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use CIME::XML::Files;
use CIME::XML::ConfigComponent;

my $logger;

our $VERSION = "v0.0.1";

BEGIN{
    $logger = get_logger();
}

sub new {
    my ($class,$cimeroot) = @_;

    my $this = {};
    bless($this, $class);
    $this->_init(@_);
    return $this;
}

sub _init {
    my ($this,$class, $cimeroot) = @_;
    $this->SetValue('CIMEROOT',$cimeroot);
#  $this->SUPER::_init($bar, $baz);
    # Nothing to do here
}

sub SetValue {
    my($this,$id,$value) = @_;
    $this->{$id}=$value;
}

sub GetValue {
    my($this,$id) = @_;
    if(defined $this->{$id}){
	return $this->{$id};
    }
    return undef;
}

sub GetValueResolved {
    my($this, $name, $attribute, $id) = @_;

    $logger->debug( Dumper($this));

    foreach my $hkey (keys %$this){
	$logger->info("key = $hkey");
	$logger->info( ref($this->{$hkey})); 
    }
}


sub configure {
    my($this) = @_;

    my $files = CIME::XML::Files->new($this);

    my $drvfile = $this->GetValueResolved(CIME::XML::ConfigComponent->new($files,"drv"));


}




1;

=head1 NAME

CIME::NAME a module to do this in perl

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

