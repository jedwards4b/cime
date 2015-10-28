package CIME::XML::GenericEntry;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use Log::Log4perl;
my $logger;
my $version = "1.0";
my $encoding = "UTF-8";

BEGIN{
    $logger = Log::Log4perl::get_logger();
}

sub new {
    my ($class, $file) = @_;
     my $this = {};
     
     bless($this, $class);
     $this->_init(@_);
     return $this;
}

sub _init {
  my ($this, $file) = @_;


#  $this->SUPER::_init($bar, $baz);
  # Nothing to do here
}


sub read{
    my ($this, $file) = @_;
    
    if(! -f $file){
	$logger->logdie("Could not find or open file $file");
    }
    $logger->debug("Opening file $file to read");
    $this->{_xml} = XML::LibXML->new( no_blanks => 1)->parse_file($file);

}

sub write{
    my($this, $file, $node) = @_;

    my $doc = XML::LibXML::Document->createDocument( $version, $encoding );

    $doc->setDocumentElement($node);
   $logger->info("Writing file $file");
    $doc->toFile($file, 2);

}



sub SetDefaultValue
{
    my($this, $id) = @_;

    my $node;

    if(ref($id)){
	$node = $id;
    }else{
	my $nodes = $this->{_xml}->find("//entry[\@id=\'$id\']");
        $node = $nodes->get_node(1);
    }
    my $val = $node->find(".//default_value");
    $node->setAttribute("value",$val);
    return $val;
}


sub SetValue
{
    my($this, $id, $val) = @_;

    my $node;

    if(ref($id)){
	$node = $id;
    }else{
	my $nodes = $this->{_xml}->find("//entry[\@id=\'$id\']");
        $node = $nodes->get_node(1);
    }
    $node->setAttribute("value",$val);
    return $val;
}


sub resolve
{
    my($this, $name) = @_;
 
    my $val = $this->GetValue($name);
    
    while($val =~ /(\$[\w_]+)/){
	my $var = $1;
	if(defined $this->{$var}){
	    $val =~ s/\$$this->{var}/$val/;
	}else{
	     my $r = $this->GetValue($var);
	     if(defined $r){
		 $val =~ s/\$$r/$val/;
	     }
	}
    }
    
    print "val = $val\n";
}


sub GetValue
{
    my($this, $name, $attribute, $id) = @_;
    my $val;
    my $nodes = $this->{_xml}->find("//entry[\@id=\'$name\']");
    my $node = $nodes->get_node(1);

    if(defined $attribute and defined $id){
	my @valnode = $node->findnodes(".//value[\@$attribute=$id]");
	$val = $valnode[0]->textContent();
    }elsif($node->hasAttribute('value')){
	return $node->getAttribute('value');
    }else{
	$val = $this->SetDefaultValue($name,$node);
    }

    return $val;
    
}

sub GetNode {
    my ($this, $nodename, $attributes) = @_;

    my $xpath = "//$nodename";

    if(defined $attributes){
	my $cnt = 0;
	foreach my $id (keys %$attributes){
	    if($cnt==0){
		$xpath .="[";
	    }else{
		$xpath .= " and ";
	    }
	    $xpath.="\@$id=\'$attributes->{$id}\'";
	}
	$xpath .= "]";
    }
    my @nodesmatched = $this->{_xml}->findnodes($xpath);
    if($#nodesmatched < 0){
	$logger->warn("$xpath did not match any nodes");
    }elsif($#nodesmatched>0){
	$logger->warn("$xpath matches mulitiple nodes");
    }else{
	return $nodesmatched[0];
    }
    return undef;
}




	
1;
