package CIME::XML::Grids;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
#use parent 'CIME::XML::GenericEntry';
my $logger;

our $VERSION = "v0.0.1";

BEGIN{
    $logger = get_logger("CIME::XML::Grids");
}

sub new {
    my ($class, $file) = @_;
    my $this = {};
  
    bless($this, $class);
    $this->_init($file);
    return $this;
}

sub _init {
    my ($this, $file) = @_;
    
    if(! -f $file){
	$logger->logdie("Could not find or open file $file");
    }
    $logger->debug("Opening file $file to read");
    $this->{_xml} = XML::LibXML->new( (no_blanks => 1, ))->parse_file($file);

}


#-------------------------------------------------------------------------------
sub getGridLongname
{
    my ($this, $grid_input, $compset) = @_;

    my ($grid_longname, $grid_shortname, $grid_aliasname);
    my $compset_match;

    my @nodes_alias = $this->{_xml}->findnodes("//grid[alias=\"$grid_input\"]");
    my @nodes_sname = $this->{_xml}->findnodes("//grid[sname=\"$grid_input\"]");
    my @nodes_lname = $this->{_xml}->findnodes("//grid[lname=\"$grid_input\"]");

    my $grid_node;
    if (@nodes_alias) {
	$grid_node = $nodes_alias[0];
    } elsif (@nodes_lname) {
	$grid_node = $nodes_lname[0];
    } elsif (@nodes_sname) {
	$grid_node = $nodes_sname[0];
    } else { 
	die " ERROR: no supported grid match for target grid $grid_input ";
    }
    
    # set the compset grid alias and longname
    foreach my $node ($grid_node->findnodes(".//*")) {
	my $name = $node->nodeName();
	my $value = $node->textContent();
	if ($name eq 'lname') {$grid_longname   = $node->textContent();}
	if ($name eq 'sname') {$grid_shortname  = $node->textContent();}
	if ($name eq 'alias') {$grid_aliasname  = $node->textContent();}
    }	

    # determine compgrid hash (global variable)
    # Assume the following order for specifying a grid name
    #  a%aname_l%lname_oi%oiname_r%rname_m%mname_g%gname_w%wname

    $grid_longname =~ /(a%)(.+)(_l%)/ ; $this->{compgrid}{'atm'}  = $2;
    $grid_longname =~ /(l%)(.+)(_oi%)/; $this->{compgrid}{'lnd'}  = $2;
    $grid_longname =~ /(oi%)(.+)(_r%)/; 
    $this->{compgrid}{ocn}  = $2; 
    $this->{compgrid}{ice} = $this->{compgrid}{ocn};
    $grid_longname =~ /(r%)(.+)(_m%)/ ; $this->{compgrid}{'rof'}  = $2; 
    $grid_longname =~ /(g%)(.+)(_w%)/ ; $this->{compgrid}{'glc'}  = $2; 
    $grid_longname =~ /(w%)(.+)$/     ; $this->{compgrid}{'wav'}  = $2; 
    $grid_longname =~ /(m%)(.+)(_g%)/ ; $this->{compgrid}{'mask'} = $2; 

    my @nodes = $this->{_xml}->findnodes(".//grid[lname=\"$grid_longname\"]");
    if ($#nodes != 0) {
	die "ERROR ConfigCompsetGrid::checkGrid : no match found for $grid_longname \n";
    } 
    my $attr = $nodes[0]->getAttribute('compset');
    if (defined $attr) {
	if ($compset !~ m/$attr/) {
	    $logger->logdie("ERROR: CIME::XML::Grids::getGridLongame $grid_longname is not supported for $compset");
	}
    }

    return ($grid_longname);
}

sub GetComponentGridSettings{
    my($this,$comp,$compgrid,$mask) = @_;
    my $settings;
    my @nodes = $this->{_xml}->findnodes("//domain[\@name=\"$compgrid\"]");
    
    my $node = $nodes[0];
    $settings->{GRID} = $compgrid;
    $settings->{NX} = ${$node->findnodes(".//nx")}[0]->textContent();
    $settings->{NY} = ${$node->findnodes(".//ny")}[0]->textContent();
    my @pathnode;
    if ($comp eq 'ATM' || $comp eq 'LND'){
	$settings->{DOMAIN_FILE} = ${$node->findnodes(".//file[\@lnd_mask=\"$mask\"]")}[0]->textContent();
	@pathnode = $node->findnodes(".//path[\@lnd_mask=\"$mask\"]");
    }elsif($comp eq 'ICE' || $comp eq 'OCN') {
	$settings->{DOMAIN_FILE} = ${$node->findnodes(".//file[\@ocn_mask=\"$mask\"]")}[0]->textContent();
	@pathnode = $node->findnodes(".//path[\@ocn_mask=\"$mask\"]");
    }
    if( @pathnode){
	$settings->{DOMAIN_PATH} = $pathnode[0]->textContent();
    }
	
    return $settings;
}

sub GetGridMaps
{
    my($this, $comp1, $comp1grid, $comp2, $comp2grid) = @_;
    my $gridmaps;
    
    my @nodes = $this->{_xml}->findnodes("//gridmap[\@${comp1}_grid=\"$comp1grid\" and \@${comp2}_grid=\"$comp2grid\"]");

    if(@nodes){
	my $gmapnode = $nodes[0];
	foreach my $node ( $gmapnode->findnodes(".//*") ){
	    $gridmaps->{$node->nodeName}=$node->textContent();
	}
    }
    return($gridmaps);

}

sub GetValue{
    my($this, $nodename, $attributes) = @_;

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

    my @nodesmatched = $this->{_xml}->findnodes($xpath);   

    if($#nodesmatched < 0){
	$logger->debug("$xpath did not match any nodes");
    }elsif($#nodesmatched>0){
	$logger->warn("$xpath matches mulitiple nodes");
    }else{
	return $nodesmatched[0]->textContent();
    }
    return undef;

}



sub GetComponentGrids{
    my($this, $gridname) = @_;
    my $compgrid;
    my ($atmgrid, $lndgrid, $ocnicegrid, $runoffgrid, $mask, $glcgrid, $wavgrid);
# Problem here - this pattern restricts us to only one gridname spec
# Need to figure out how to generalize
#    my $pattern = $this->GetValue("gridname_spec");
    if($gridname =~ /a%(.+)_l%(.+)_oi%(.+)_r%(.+)_m%(.+)_g%(.+)_w%(.+)$/){
	$atmgrid=$1;
	$lndgrid=$2;
	$ocnicegrid=$3;
	$runoffgrid=$4;
	$mask=$5;
	$glcgrid=$6;
	$wavgrid=$7;
	
	
	$compgrid->{ATM} = $this->GetComponentGridSettings("ATM",$atmgrid, $mask);
	$compgrid->{LND} = $this->GetComponentGridSettings("LND",$lndgrid, $mask);
	$compgrid->{OCN} = $this->GetComponentGridSettings("OCN",$ocnicegrid, $mask);
	$compgrid->{ICE} = $this->GetComponentGridSettings("ICE",$ocnicegrid, $mask);
	$compgrid->{ROF} = $this->GetComponentGridSettings("ROF",$runoffgrid, $mask);
	$compgrid->{GLC} = $this->GetComponentGridSettings("GLC",$glcgrid, $mask);
	$compgrid->{WAV} = $this->GetComponentGridSettings("WAV",$wavgrid, $mask);


    }else{
	$logger->logdie("Gridname $gridname did not fit expected pattern");
    } 
    return $compgrid;
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

