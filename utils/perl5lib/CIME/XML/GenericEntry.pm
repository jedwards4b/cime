package CIME::XML::GenericEntry;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use XML::LibXML::NodeList;
use XML::LibXSLT;

my $logger;
our $VERSION = "v0.0.1";
my $encoding = "UTF-8";
my $xmlversion = "1.0";

BEGIN{
    $logger = get_logger("CIME::XML::GenericEntry");
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

  if(defined $file and -f $file){
      $this->read($file);
  }elsif(defined $file){
    $this->{_xml} = XML::LibXML::Document->new($xmlversion, $encoding);      
    $this->{root} = $this->{_xml}->createElement('file');
    $file =~ /([^\/]+).xml/;
    my $id = $1;
    $this->{root}->setAttribute("id",$id);

  }

}


sub read{
    my ($this, $file) = @_;
    
    if(! -f $file){
	$logger->logdie("Could not find or open file $file");
    }
    $logger->debug("Opening file $file to read");
#    $this->{_xml} = XML::LibXML->new( (no_blanks => 1, validation=>1))->parse_file($file);
    $this->{_xml} = XML::LibXML->new( (no_blanks => 1, ))->parse_file($file);

}

sub write{
    my($this, $file) = @_;

    my $doc = XML::LibXML::Document->createDocument( $xmlversion, $encoding );

    $doc->setDocumentElement($this->{root});
    $logger->info("Writing file $file");
# Here we use a style-sheet to format the case xml files. 
# This can be done from the command line with xsltproc for testing and tuning the 
# style file.  
    my $xslt = XML::LibXSLT->new();
    $xslt->max_depth(5000);
    my $style = XML::LibXML->load_xml(location=>"$this->{CIMEROOT}/cime_config/case_xml.xsl");
    my $stylesheet = $xslt->parse_stylesheet($style);
    $doc = $stylesheet->transform($doc);
    open(F,">$file");
    print F $stylesheet->output_as_bytes($doc);
    close (F);
#    $doc->toFile($file, 0);

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
    my($this, $id, $value) = @_;

    $logger->debug("id $id val $value");

    my $node;
    my $val;

    if(ref($id)){
	$node = $id;
    }else{

	$node=$this->GetNode("file/group/entry",{id=>$id,});

#	my @nodes = $this->{_xml}->findnodes("//file/group/entry[\@id=\"$id\"]");
#	print "HERE $#nodes\n";
#        $node = $nodes[0];
    }
    if(defined $node){
	$logger->debug("SetValue: ".ref($this)." id=$id value=$value");	
	$node->setAttribute("value",$value);
	$val = $value;
    }
    return $val;
}


sub GetValue
{
    my($this, $name, $attribute, $id) = @_;
    my $val;
    $logger->debug("name=$name file:".ref($this));
    my $nodes = $this->{_xml}->find("//entry[\@id=\'$name\']");
#    my @nodes = $this->{_xml}->findnodes("//entry[\@id=\"$name\"]");
#    print ref($this)." nodes = $#nodes\n";
#    my $node;
    my $node = $nodes->get_node(1);

    if(! defined $node) {
	$logger->info("Node not defined for $name");
	return undef;
    }
    if(defined $attribute and defined $id){
	my @valnode = $node->findnodes(".//value[\@$attribute=\'$id\']");
	$logger->debug("attribute $attribute id $id $#valnode");
	if($#valnode==0){
	    $val = $valnode[0]->textContent();
	}else{
	    $logger->warn("No match for $attribute=$id");
	}

    }elsif($node->hasAttribute('value')){
	return $node->getAttribute('value');
    }else{
	$val = $this->SetDefaultValue($name,$node);
    }

    return $val;
    
}

sub GetValues {
    my ($this, $id, $att) = @_;
    my $values;

    my $nodes = $this->{_xml}->find("//entry[\@id=\'$id\']");
    my $node = $nodes->get_node(1);
    my @valnodes = $node->findnodes(".//value");
    $logger->debug("Found $#valnodes valnodes");
    foreach my $vnode ( @valnodes ){
	my $attval = $vnode->getAttribute($att);
	$logger->debug("Att $att $attval");
	my $txt = $vnode->textContent();
	$values->{$attval} = $txt;
    }
    return $values;
}

sub GetElementsfromChildContent {
    my ($this, $childname, $childcontent) = @_;
    my @parents;
    $logger->debug(ref($this)." GetElementsfromChildContent $childname $childcontent");

    my @nodes = $this->{_xml}->findnodes("//entry");

    $logger->debug("Got $#nodes");


    foreach my $node (@nodes){
	my @nodeid = $node->attributes();
	$logger->debug("Found node @nodeid");
	my @cnodes = $node->findnodes(".//$childname");
	if($#cnodes != 0) {
	    $logger->warn("Unexpected number of matches for $childname $#cnodes @nodeid");
	}
	my $content = $cnodes[0]->textContent();
	$logger->debug(" Checking $content");
	if($childcontent =~ /$content/){
	    push(@parents, $node);
	}
    }
    $logger->debug("Found $#parents parents $childname $childcontent");
    my $nodelist = undef;
    if($#parents){
	$nodelist = XML::LibXML::NodeList->new(@parents);
    }
    return ($nodelist);
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
	    $cnt++;
	}
	$xpath .= "]";
    }
    
    $logger->debug("XPATH = $xpath");
    my @nodesmatched;
    if(defined $this->{root}){
	@nodesmatched = $this->{root}->findnodes($xpath);
    }else{
	@nodesmatched = $this->{_xml}->findnodes($xpath);   
    }
    if($#nodesmatched < 0){
	$logger->debug("$xpath did not match any nodes");
    }elsif($#nodesmatched>0){
	$logger->warn("$xpath matches mulitiple nodes");
    }else{
	return $nodesmatched[0];
    }
    return undef;
}

sub PrintEntry
{
    my($this, $id, $opts) = @_;
    my $found;
    my $node = $this->GetNode("entry",{id=>$id});
    if(defined $node){
	$found = 1;
	if($opts->{fileonly}){
	    ref($this) =~ /CIME::XML::(.*)/;
	    my $file = $1.".xml";
	    print "$id is defined in $file\n";

	}
	my $value = $node->getAttribute("value");
	if(!(defined $opts->{noexpandxml}) || $opts->{noexpandxml}==0){
	    $value = $this->GetResolvedValue($value);
	}
	if($opts->{value}){
	    print $value;
	    return $found;
	}
	print "$id = $value\n";
	if($opts->{valonly}){
	    return $found;
	}	
	my @fields = $node->findnodes(".//*");
	foreach my $fld (@fields){
	    print "  ".$fld->nodeName().":  ".$fld->textContent()."\n";
	} 


    }
    return $found;
}

sub GetResolvedValue {
    my($this, $val) = @_;

#find and resolve any variable references.    
    if(! defined $val){
	$logger->logdie("GetResolvedValue called without an argument");
    }
    my @cnt = $val =~ /\$/g;
    
    for(my $i=0; $i<= $#cnt; $i++){
	if($val =~ /^[^\$]*\$([^\$\}\/]+)/){
	    my $var = $1;
	    my $rvar = $this->GetValue($var);
	    $val =~ s/\$$var/$rvar/;
	}
    }
    
    return $val;

}



sub AddElementsByGroup
{
    my($this, $srcdoc, $file) = @_;

    # Add elements from srcdoc to the $file under the appropriate
    # group element.  Add the group if it does not already exist, remove group and
    # file children from each entry, set the default value
    my %groups;
    my $nodelist = $srcdoc->GetElementsfromChildContent('file' ,$file);
#    my $root = $this->{_xml}->getDocumentElement();
    if(defined $nodelist){
	foreach my $node ($nodelist->get_nodelist()){
	    my $childnode = ${$node->findnodes(".//file")}[0];
	    $node->removeChild($childnode);
	    $childnode = ${$node->find(".//group")}[0];
	    my $groupname = $childnode->textContent();
	    $node->removeChild($childnode);
	    
#	    my $groupnode = ${$this->{root}->findnodes("//file/group[\@id=\"$groupname\"]")}[0];
	    if(!defined $groups{$groupname}){
		$logger->debug("Defining group ",$groupname);
		my $groupnode = $this->{_xml}->createElement("group");
		$groupnode->setAttribute("id",$groupname);
		$this->{root}->addChild($groupnode);
		$groups{$groupname}=$groupnode;
	    }
	    my $id = $node->getAttribute("id");
	    $logger->debug("Adding $id  to group ",$groupname);
	    $this->SetDefaultValue($node);
	    $groups{$groupname}->addChild($node);

	}
    }
}




1;
    
__END__

=head1 CIME::XML::GenericEntry

CIME::XML::GenericEntry : a module to read and write CIME entry/id style xml files.

=head1 SYNOPSIS

  use CIME::XML::GenericEntry;

  my $obj = CIME::XML::GenericEntry->new();


=head1 DESCRIPTION

CIME::XML::GenericEntry is a module to read and write CIME entry/id style xml files.
       
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

