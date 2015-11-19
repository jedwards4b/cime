package CIME::XML::Compset;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use parent 'CIME::XML::GenericEntry';
use CIME::XML::Files;

my $logger;

BEGIN{
    $logger = Log::Log4perl::get_logger();
}

sub new {
    my ($class, $params) = @_;
    my $this = {};
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
    if(defined $params->{Files}){
	$this->{Files} = $params->{Files};
    }


    bless($this, $class);
    $this->_init($model);
    return $this;
}

sub _init {
  my ($this,$model) = @_;
  $this->SUPER::_init();

  if(!defined $this->{Files}){
      $this->{Files} = CIME::XML::Files->new({CIMEROOT=>$this->{CIMEROOT}} );
  }
  
}


sub getCompsetLongname
{
    # Determine compset longname, alias and support level
    my ($this, $input_compset) = @_;

    $input_compset =~ s/^\s+//; # strip any leading whitespace 
    $input_compset =~ s/\s+$//; # strip any trailing whitespace

    # Note - the value of the config variable 'COMPSETS_SPEC_FILE' gives the full pathname of the
    # file containing the possible out of the box compsets that can be used by create_newcase

    # TODO: add logic for determining support level
    # TODO: Add support level to $config rather than an argument

    my $support_level;
    my $pes_setby;

    my $cimeroot = $config->get('CIMEROOT');
    my $srcroot  = $config->get('SRCROOT');
    my $model    = $config->get('MODEL');
    my $compset_longname;
    my $compset_aliasname;

    # First determine primary component (for now this is only CESM specific)
    # Each primary component is responsible for defining the compsets that turn of the
    # appropriate feedbacks for development of that component

    my $compsets_file;
    my $compset_longname;

    my $pes_setby;
    my $xml1 = XML::LibXML->new( no_blanks => 1)->parse_file("$input_file");

    # Loop through all of the files listed in COMPSETS_SPEC_FILE and find the file
    # that has a match for either the alias or the longname in that order
    my @nodes = $xml1->findnodes(".//entry[\@id=\"COMPSETS_SPEC_FILE\"]/values/value");
    foreach my $node_file (@nodes) {
	my $file = $node_file->textContent();
	$file =~ s/\$CIMEROOT/$cimeroot/;
	$file =~ s/\$SRCROOT/$srcroot/;
	$file =~ s/\$MODEL/$model/;
	if (! -f $file ) {next;}
	my $xml2 = XML::LibXML->new( no_blanks => 1)->parse_file("$file");

	# First determine if there is a match for the alias - if so stop
	my @alias_nodes = $xml2->findnodes(".//compset[alias=\"$input_compset\"]");
	if (@alias_nodes) {
	    if ($#alias_nodes > 0) {
		die "ERROR create_newcase: more than one match for alias element in file $file \n";
	    } else {
		my @name_nodes = $alias_nodes[0]->findnodes(".//lname");
		foreach my $name_node (@name_nodes) {
		    $compset_longname = $name_node->textContent();
		}
	    }
	    $pes_setby = $node_file->getAttribute('component');
	    $compsets_file = $file;
	    $config->set('COMPSETS_SPEC_FILE', $compsets_file);
	    $config->set('COMPSET', "$compset_longname");
	    last;
	} 

	# If no alias match - then determine if there is a match for the longname
	my @lname_nodes = $xml2->findnodes(".//compset[lname=\"$input_compset\"]");
	if (@lname_nodes) {
	    if ($#lname_nodes > 0) {
		die "ERROR create_newcase: more than one match for lname element in file $file \n";
	    } else {
		my @name_nodes = $lname_nodes[0]->findnodes(".//lname");
		foreach my $name_node (@name_nodes) {
		    $compset_longname = $name_node->textContent();
		}
	    }
	    $pes_setby = $node_file->getAttribute('component');
	    $compsets_file = $file;
	    $config->set('COMPSETS_SPEC_FILE', "$compsets_file");
	    $config->set('COMPSET', "$compset_longname");
	    last;
	} 

    }
    if (! defined $pes_setby) {
	my $outstr = "ERROR create_newcase: no compset match was found in any of the following files:";
	foreach my $node_file (@nodes) {
	    my $file = $node_file->textContent();
	    $file =~ s/\$CIMEROOT/$cimeroot/;
	    $file =~ s/\$SRCROOT/$srcroot/;
	    $file =~ s/\$MODEL/$model/;
	    $outstr .= "$file\n";
	}
	$logger->logdie ($outstr);
    } else {
	$logger->info( "File specifying possible compsets: $compsets_file ");
	$logger->info( "Primary component (specifies possible compsets, pelayouts and pio settings): $pes_setby ");
	$logger->info("Compset: $compset_longname ");
    }   

    return ($pes_setby, $support_level);
}





1;
 
