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

	    #
            # This creates a hash of values with attribute name and id as keys
            #
	    if($node_name eq "values"){
		foreach my $val_node ($define_node->childNodes()){
                    if($val_node->hasAttributes()){		 
			my @att = $val_node->attributes();
			foreach my $attstr (@att){
			    $attstr =~ /(\w+)=\"(.*)\"/;
			    my $att = $1;
			    my $att_val = $2;
			    my $val =  $val_node->textContent();		
			    $self->{$id}{$att}{$att_val} = $val;
			}
		    }
		}

	    }else{
		my $node_value = $define_node->textContent();
		if (defined $node_value) {
		    # now set the initial value to the default value - this can get overwritten
		    $self->{$id}{$node_name} = $node_value;
		    $logger->debug("id= $id name = $node_name value = $node_value\n");
		}
	    }
	}
	$self->set_default($id);
	if (! defined $self->{$id}{value} ) {
	    $logger->logdie( "ERROR default_value must be set for $id in $file\n");
	}
    }
}


sub set_default
{
    my($self, $id) = @_;

    if(defined $self->{$id}{default_value}){
	$self->{$id}{value} = $self->{$id}{default_value};
    }

}




    
sub resolve 
{
    my ($self, $string, $value) = @_;


    foreach my $id (keys %$self){
	if(defined $self->{$id}{value}){
	    if($self->{$id}{value} =~ /$string/){
		$self->{$id}{value} =~ s/$string/$value/;
		$logger->debug("id = $id value = $self->{$id}{value} string=$string sub=$value");
	    }
	}
    }
	    

}


sub get
{
    my($self, $name, $attribute, $id) = @_;

    defined($self->{$name}) or $logger->logdie( "ERROR $pkg_nm::get: unknown parameter name: $name\n");
    $logger->debug("GET: $name $self->{$name}->{value}\n");
    if(defined $attribute && defined $id){
	if(defined $self->{$name}{$attribute}){
	    my $val = $self->{$name}{$attribute}{$id};
	    if(! defined $val){
		$logger->warn("No match for $attribute and $id in $name");
	    }
	    return $val;
	}else{
	    $logger->warn("No values found for $name");
	}
    }
    return $self->{$name}{'value'};

}

1;
