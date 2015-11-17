package CIME::XML::GenericEntry;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use XML::LibXML::NodeList;

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
  }else{
    $this->{_xml} = XML::LibXML::Document->new($xmlversion, $encoding);      
  }


#  $this->SUPER::_init($bar, $baz);
  # Nothing to do here
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

    $doc->setDocumentElement($this->{_xml}->documentElement());
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

    $logger->debug("id $id val $val");

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


sub GetValue
{
    my($this, $name, $attribute, $id) = @_;
    my $val;
    $logger->debug("name=$name");
    my $nodes = $this->{_xml}->find("//entry[\@id=\'$name\']");
    my $node = $nodes->get_node(1);
    if(! defined $node) {
	$logger->info("Node not defined for $name");
	return undef;
    }
    if(defined $attribute and defined $id){
	my @valnode = $node->findnodes(".//value[\@$attribute=\'$id\']");
	$logger->debug("attribute $attribute id $id $#valnode");
	$val = $valnode[0]->textContent();
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

sub AddElementsByGroup
{
    my($this, $srcdoc, $file) = @_;

    # Add elements from srcdoc to the env_run.xml file under the appropriate
    # group element.  Add the group if it does not already exist, remove group and
    # file children from the entry

    my $nodelist = $srcdoc->GetElementsfromChildContent('file' ,$file);
    my $root = $this->{_xml}->getDocumentElement();

    foreach my $node ($nodelist->get_nodelist()){
	my $childnode = ${$node->findnodes(".//file")}[0];
	$node->removeChild($childnode);
        $childnode = ${$node->find(".//group")}[0];
	my $groupname = $childnode->textContent();
	$node->removeChild($childnode);

	my $groupnode = ${$root->findnodes("//$groupname")}[0];
	if(!defined $groupnode){
	    $groupnode = $this->{_xml}->createElement($groupname);
	    $root->addChild($groupnode);
	}
	my $id = $node->getAttribute("id");
	$logger->debug("Adding $id  to group ",$groupnode->nodeName());
	
	$groupnode->addChild($node);

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

