package CIME::XML::GenericEntry;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use Log::Log4perl;
my $logger;

BEGIN{
    $logger = Log::Log4perl::get_logger();
}

sub new {
     my $class = shift();
     my $this = {};
     
     bless($this, $class);
     $this->_init(@_);
     return $this;
}

sub _init {
  my ($this) = @_;
#  $this->SUPER::_init($bar, $baz);
  # Nothing to do here
}

sub read{
    my ($self, $file) = @_;

    if(! -f $file){
	$logger->logdie("Could not find or open file $file");
    }
    $logger->debug("Opening file $file to read");
    my $xml = XML::LibXML->new( no_blanks => 1)->parse_file($file);
    my @nodes = $xml->findnodes(".//entry");

    if (! @nodes) {
	$logger->logdie( "ERROR XML read error in $file \n"); 
    }

    foreach my $node (@nodes) 
    {
	my $id = $node->getAttribute('id');
	foreach my $define_node ($node->childNodes()) 
	{
	    my $node_name  = $define_node->nodeName();
	    my $node_value = $define_node->textContent();
	    if (defined $node_value) {
		# now set the initial value to the default value - this can get overwritten
		if ($node_name eq 'default_value') {
		    $self->{$id}{value} = $node_value;
		} else {
		    $self->{$id}{$node_name} = $node_value;
		}
		$logger->debug("id= $id name = $node_name value = $node_value\n");
	    }
	}
	if (! defined $self->{$id}{value} ) {
	    $logger->logdie( "ERROR default_value must be set for $id in $file\n");
	}
    }
}
    
sub resolve 
{
    my ($self, $string, $value) = @_;


    foreach my $id (keys %$self){
	if(defined $self->{$id}{value}){
	    my $a = qr/$string/;
	    if($self->{$id}{value} =~ /$a/){
		$self->{$id}{value} =~ s/$a/$value/;
		$logger->debug("id = $id value = $self->{$id}{value} string=$string sub=$value");
	    }
	}
    }
	    

}



1;
