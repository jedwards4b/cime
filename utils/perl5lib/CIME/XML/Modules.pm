package CIME::XML::Modules;
my $pkg_nm = __PACKAGE__;

use CIME::Base;

my $logger;

BEGIN{
    $logger = get_logger();
}

sub new {
     my ($class, $node) = @_;
     my $this = {};
     bless($this, $class);
     $this->_init($node);
     return $this;
}

sub _init {
  my ($this, $node) = @_;
#  $this->SUPER::_init();
  
  $this->{_xml} = $node;
  
}

sub _get_module_init_path
{
    my ($this, $lang) = @_;
    my $node = $this->{_xml};
    if($node->hasAttribute('type')){
	my @moduleinit= $node->findnodes(".//init_path[\@lang=\'$lang\']");
	if($#moduleinit != 0){
	    $logger->error("Error finding module init path for $lang");
	}
	return $moduleinit[0]->textContent();
    }
    return undef;
		
}


sub load
{
    my($this, $attributes) = @_;

    my $node = $this->{_xml};
    my $type = $node->getAttribute('type');

    if($type eq "module"){
	$this->load_modules($attributes);
    }elsif($type eq "dotkit"){
	$this->load_dotkit();
    }elsif($type eq "soft"){
	$this->load_soft();
    }elsif($type eq "none"){
	$this->load_none();
    }else{
	$logger->logdie("Unrecognized module_system type $type");
    }
    
}

sub load_modules
{
    my($this, $attributes) = @_;

    my $init_path = $this->_get_module_init_path('perl');
    
    if(defined $init_path){
	require $init_path;
    }
    my $node = $this->{node};
    my @modulecmds;
    
    my @allmodulenodes = $node->findnodes(".//module_system/modules");
    
    foreach my $mnode (@allmodulenodes){
	if(! $mnode->hasAttributes()){
	    my @commands = $mnode->findnodes(".//command");
	    foreach my $command (@commands){
		my $action = $command->getAttribute("name");
		my $actupon = $command->textContent();
		push(@modulecmds,"$action $actupon");
	    }
	}else{
	    my @modatts = $mnode->attributes();
	    print "HERE @modatts\n";
	}
	
    }	
    module("list");
}
sub load_soft
{
    my($this) = @_;
}
sub load_dotkit
{
    my($this) = @_;
}
sub load_none
{
    my($this) = @_;
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

