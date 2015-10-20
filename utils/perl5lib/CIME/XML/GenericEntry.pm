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
    my ($this, $file) = @_;

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
			    $this->{$id}{$att}{$att_val} = $val;
			}
		    }
		}

	    }else{
		my $node_value = $define_node->textContent();
		if (defined $node_value) {
		    # now set the initial value to the default value - this can get overwritten
		    $logger->debug("id= $id name = $node_name value = $node_value\n");
		    $this->{$id}{$node_name} = $node_value;
		}
	    }
	}
	$this->set_default($id);
	if (! defined $this->{$id}{value} ) {
	    $logger->logdie( "ERROR default_value must be set for $id in $file\n");
	}
    }
}


sub set_default
{
    my($this, $id) = @_;

    if(defined $this->{$id}{default_value}){
	$this->{$id}{value} = $this->{$id}{default_value};
    }

}




    
sub resolve 
{
    my ($this, $string, $value) = @_;



    foreach my $id (keys %$this){
	next unless (ref $this->{$id});
	if(defined $this->{$id}{value}){
	    if($this->{$id}{value} =~ /$string/){
		$this->{$id}{value} =~ s/$string/$value/;
		$logger->debug("id = $id value = $this->{$id}{value} string=$string sub=$value");
	    }
	}
    }
	    

}


sub get
{
    my($this, $name, $attribute, $id) = @_;

    defined($this->{$name}) or $logger->logdie( "ERROR get: unknown parameter name: $name\n");
    $logger->debug("GET: $name $this->{$name}->{value}\n");
    if(defined $attribute && defined $id){
	if(defined $this->{$name}{$attribute}){
	    my $val = $this->{$name}{$attribute}{$id};
	    if(! defined $val){
		$logger->warn("No match for $attribute and $id in $name");
	    }
	    return $val;
	}else{
	    $logger->warn("No values found for $name");
	}
    }
    return $this->{$name}{'value'};

}

1;
