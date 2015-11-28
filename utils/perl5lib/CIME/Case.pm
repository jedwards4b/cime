package CIME::Case;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use CIME::XML::Files;
use CIME::XML::env_run;
use CIME::XML::env_case;
use CIME::XML::env_build;
use CIME::XML::env_batch;
use CIME::XML::ConfigComponent;
use CIME::XML::Grids;
use CIME::XML::Machines;

my $logger;

our $VERSION = "v0.0.1";

BEGIN{
    $logger = get_logger("CIME::Case");
}

my @casefiles = qw(env_run env_case env_build env_batch);
#env_mach_pes);

sub new {
    my ($class,$cimeroot, $caseroot) = @_;

    my $this = {};
    bless($this, $class);
    $this->_init($cimeroot, $caseroot);
    return $this;
}

sub _init {
    my ($this,$cimeroot,$caseroot) = @_;

    $this->SetValue('CIMEROOT',$cimeroot);
    if(defined $caseroot){
	$this->InitCaseXML($caseroot);
    }
#  $this->SUPER::_init($bar, $baz);
    # Nothing to do here
}

# This is repeated in GenericEntry - how can we define in just one place?
sub GetResolvedValue {
    my($this, $val, $reccnt) = @_;

    if(defined $reccnt){
	if($reccnt>10){
	    $logger->logdie("Too many levels of recursion in ".ref($this)."::GetResolvedValue for $val");
	}
	$reccnt++;
    }else{
	$reccnt=0;
    }

#find and resolve any variable references.    
    if(! defined $val){
	$logger->logdie("GetResolvedValue called without an argument");
    }

    if($val =~ /^(.*)\$ENV{(.*)}(.*)$/){
	if(defined $ENV{$2}){
	    $val = $1.$ENV{$2}.$3;
	}else{
	    $logger->warn("Could not resolve environment variable $2");
	    return $val;
	}
    }

    my @cnt = $val =~ /\$/g;
    
    for(my $i=0; $i<= $#cnt; $i++){
	if($val =~ /^[^\$]*\$([^\$\}\/]+)/){
	    my $var = $1;
	    my $rvar = $this->GetValue($var);
	    $val =~ s/\$$var/$rvar/;
	}
    }
    # There is a possibility of infinite recursion here, need an error check.
    if($val =~ /\$/){
	$val = $this->GetResolvedValue($val,$reccnt);
    }
    
    return $val;

}


sub InitCaseXML{
    my($this,$caseroot) = @_;
    
    # Create objects for each XML file in the case directory
    $caseroot = $this->GetResolvedValue($caseroot);
    $this->{env_run} = CIME::XML::env_run->new($this->GetValue('CIMEROOT'), $caseroot."/env_run.xml");
    $this->{env_case} = CIME::XML::env_case->new($this->GetValue('CIMEROOT'), $caseroot."/env_case.xml");
    $this->{env_build} = CIME::XML::env_build->new($this->GetValue('CIMEROOT'), $caseroot."/env_build.xml");    
    $this->{env_batch} = CIME::XML::env_batch->new($this->GetValue('CIMEROOT'), $caseroot."/env_batch.xml");
    # needs env_mach_pes.xml
    # 

}

sub SetValue {
    my($this,$id,$value) = @_;
    
    my $val;
    foreach my $file (@casefiles){
	if(defined $this->{$file}){
	    $logger->debug("Looking for $id in $file");
	    $val = $this->{$file}->SetValue($id,$value);
	}
	if(defined $val){
	    $logger->debug("Found $id in $file, set to $val");
	    return 1;
	}
    }
    if(!defined $val){
	$this->{$id}=$value;
    }
    return undef;
}

# Given an xml id and optionally an attribute and name return the unique value associated with that 
# name, this value may contain unresolved variables 

sub GetValue {
    my($this,$id, $attribute, $name) = @_;
    my $val;

    if(defined $this->{$id}){
	$val =  $this->{$id};
    }else{
	foreach my $hkey (keys %$this){
	    my $tref = ref ($this->{$hkey});
	    if(ref( $this->{$hkey}) =~ "CIME::XML"){
		$logger->debug("Looking for $id in $tref");
		$val =  $this->{$hkey}->GetValue($id, $attribute, $name);
	    }
	    last if defined $val;
	}
    }
    return $val;
}

sub is_valid_name{
    my($this,$name) = @_;
    defined $this->GetValue($name) ? 1: 0;
    
}


sub PrintEntry
{
    my ($this,$id,$opts) = @_;
    
    my $found;
    foreach my $hkey (keys %$this){
	my $tref = ref ($this->{$hkey});
	if(ref( $this->{$hkey}) =~ "CIME::XML"){
	    $found =  $this->{$hkey}->PrintEntry($id, $opts);
	}
	last if defined $found;
    }

}



#
# configure 
#
#

sub configure {
    my($this) = @_;

    my $caseroot = $this->GetValue("CASEROOT");

    $this->InitCaseXML($caseroot);

    my $files = CIME::XML::Files->new($this);

    my $compset_files = $files->GetValues("COMPSETS_SPEC_FILE","component");

# Find the compset longname and target component
    my $target_comp;
    my $compset = $this->GetValue("COMPSET");
    $logger->info("Compset requested: $compset");
    foreach my $comp (keys %$compset_files){
	$logger->debug("comp = $comp $compset_files->{$comp}");
	my $file = $this->GetResolvedValue($compset_files->{$comp});

# does config_comp need to be part of the object or can it be a local?
#	$this->{"config_$comp"} = CIME::XML::ConfigComponent->new($file);

	my $compset = CIME::XML::ConfigComponent->new($file)->CompsetMatch($compset);
	if(defined $compset){
	    $logger->info("Compset longname: $compset");
	    $this->SetValue("COMPSET",$compset);
	    $target_comp = $comp;
	    last;
	}

    }
    if(!defined $target_comp){
	$logger->logdie("Could not find a compset match for ".$this->GetValue("COMPSET"));
    }

    
# Get the list of component classes supported by this drv
    my $file = $files->GetValue('CONFIG_DRV_FILE');
    $file = $this->GetResolvedValue($file);
    my $configcomp = CIME::XML::ConfigComponent->new($file);
    my @components = $configcomp->GetValue('components');
    $logger->debug( "components are @components");

# Find the specific components for this case 
    my @compcomp = $this->Compset_Components();

    if($#components != $#compcomp){
	$logger->logdie("General and specific component counts dont match");
    }

#   attributes used for multi valued defaults
    my $attlist = {component=>$target_comp};


    foreach my $comp (@components){
	my $file;
	my $compcomp = shift @compcomp;
	if($comp ne "DRV"){  # DRV was handled above
	    my $config_file = 'CONFIG_'.$comp.'_FILE';
	    $file = $files->GetValue($config_file, "component", $compcomp );
	    $this->SetValue($config_file,$file);
	    $file = $this->GetResolvedValue($file);
	    $configcomp = CIME::XML::ConfigComponent->new($file);
	}
	$this->AddElementsByGroup($configcomp, $attlist);
    }

    $this->AddElementsByGroup($files, $attlist);

    $this->ReparseXML();
    
# All of the elements of the case xml files are now defined and default values are
# set.   Now we can move the command line values from the object hash to the XML
    foreach my $var (keys %$this){
	next if(ref($this->{$var}));  #skip references
	my $found = $this->SetValue($var,$this->{$var});
	if($found){
	    # we've successfully updated the xml var, delete the hash entry
	    delete $this->{$var};
	}
    }
# Set any additional command line configuration options
    $this->SetConfOpts();
# Set any other values here
    $this->SetValue("USER", $ENV{USER});
        
    my $grids_file = $this->GetValue('GRIDS_SPEC_FILE');
    $grids_file = $this->GetResolvedValue($grids_file);
    
    $logger->debug("Opening grid file $grids_file");

    my $grid_file = CIME::XML::Grids->new($grids_file);

    my $grid = $this->GetValue('GRID');
    $logger->info("Grid requested: $grid");

    $grid = $grid_file->getGridLongname($grid, $compset);
    
    $logger->info("Grid Longname: $grid");

    $this->SetValue("GRID", $grid);

    my $compgrids = $grid_file->GetComponentGrids($grid);
    
    foreach my $comp (keys $compgrids){
 	foreach my $setting (keys $compgrids->{$comp}){
	    $this->SetValue("${comp}_${setting}",$compgrids->{$comp}{$setting});
	}
    }
    # Get all the inter component mapping files
    # start at 1 to skip coupler
    for(my $i=1; $i<=$#components; $i++){
	my $comp1 = $components[$i];
	for(my $j=$i+1; $j <= $#components; $j++){
	    my $comp2 = $components[$j];
	    my $maps = $grid_file->GetGridMaps(lc($comp1),$compgrids->{$comp1}{GRID},lc($comp2),$compgrids->{$comp2}{GRID});
	    if(defined $maps){
		foreach my $mapname (keys $maps){
		    $this->SetValue($mapname, $maps->{$mapname});
		}
	    }
	}
    }
    if(grep("xrof",@components)){
	my $floodMode = $grid_file->GetValue("XROF_FLOOD_MODE",{ocn_grid=>$compgrids->{OCN}{GRID},
								lnd_grid=>$compgrids->{LND}{GRID},
								rof_grid=>$compgrids->{ROF}{GRID}});
	if(defined $floodMode){
	    $this->SetValue("XROF_FLOOD_MODE",$floodMode);
	}
    }
    my $machfile = $this->GetValue('MACHINES_FILE');
    $machfile = $this->GetResolvedValue($machfile);
    $logger->info("Machine file is $machfile");
    my $machine = CIME::XML::Machines->new($machfile, $this->GetValue('MACH'));

    my $compiler = $this->GetValue('COMPILER');      #check for a user defined value
    $compiler = $machine->getCompiler($compiler);    #get the default value or confirm the user defined value is valid
    $this->SetValue("COMPILER",$compiler);           #set the updated value
    $logger->info("Compiler is $compiler");

    my $mpilib = $this->GetValue('MPILIB');
    $mpilib = $machine->getMPIlib($mpilib);
    $this->SetValue("MPILIB",$mpilib);
    $logger->info("MPILIB is $mpilib");
    
    my @ids = $machine->getNodeNames();
    foreach my $id (@ids){
# these are exceptions to be handled elsewhere
	next if($id eq "mpirun");
	next if($id eq "COMPILERS");
	next if($id eq "MPILIBS");
	next if($id eq "environment_variables");
	next if($id eq "module_system");

	my $val = $machine->getValue($id);
	$this->SetValue($id,$val);
    }    
    
}

sub SetConfOpts{
    my ($this) = @_;

    if(defined $this->{confopts}){
	my $coptions = $this->{confopts};
	delete $this->{confopts};
	$logger->debug( "  confopts = $coptions");

	if ($coptions =~ "_D" || $coptions =~ "_ED") {
	    $this->SetValue('DEBUG', "TRUE");
	    $logger->debug("    confopts DEBUG ON ");
	}
	if ($coptions =~ "_E" || $coptions =~ "_DE") {
	    $this->SetValue('USE_ESMF_LIB', "TRUE");
	    $this->SetValue('COMP_INTERFACE', "ESMF");
	    $logger->debug("    confopts COMP_INTERFACE ESMF set ");
	}
# 
	if ($coptions =~ "_P") {
	    my $popt = $coptions;
	    if($popt =~ /.*_P([A-Za-z0-9]*)_?.*/){
		my $pecount = $1;
		$this->SetValue("pecount",$pecount);
		$logger->debug("    confopts pecount set to $pecount");
	    }else{
		$logger->logdie("Error parsing confopts pecount");
	    }
	    
	}
	if ($coptions =~ "_M") {
	    my $mopt = $coptions;
	    my $mpilib;
	    if($mopt =~ /.*_M([A-Za-z0-9\-]*)_?.*/){
		$mpilib = $1;
		$this->SetValue("MPILIB",$mpilib);
		$logger->debug("    mpilib set to $mpilib ");
	    }else{
		$logger->logdie( "M option found but no MPILIB provided");
	    }
	}
	if ($coptions =~ "_L") {
	    my $lopt = $coptions;
	    $lopt =~ s/.*_L([A-Za-z0-9]*)_?.*/$1/;
	    my $loptc = substr($lopt,0,1);
	    my $lopti = substr($lopt,1);
	    my $lopts = 'unknown';
	    if ($loptc =~ "y") {$lopts = 'nyears'}
	    if ($loptc =~ "m") {$lopts = 'nmonths'}
	    if ($loptc =~ "d") {$lopts = 'ndays'}
	    if ($loptc =~ "h") {$lopts = 'nhours'}
	    if ($loptc =~ "s") {$lopts = 'nseconds'}
	    if ($loptc =~ "n") {$lopts = 'nsteps'}
	    if ($lopts =~ "unknown") {
		$logger->logdie(" _L confopts run length undefined, only y m d h s n allowed");
	    }
	    $this->SetValue('STOP_OPTION', $lopts);
	    $this->SetValue('STOP_N', $lopti);
	    $logger->debug("    confopts run length set to $lopt . $lopts . $lopti ");
	}
	if ($coptions =~ "_N") {
	    my $nopt = $coptions;
	    $nopt =~ s/.*_N([0-9]*)_?.*/$1/;
	    $this->SetValue('NINST_ATM', $nopt);
	    $this->SetValue('NINST_LND', $nopt);
	    $this->SetValue('NINST_OCN', $nopt);
	    $this->SetValue('NINST_ICE', $nopt);
	    $this->SetValue('NINST_GLC', $nopt);
	    $this->SetValue('NINST_ROF', $nopt);
	    $this->SetValue('NINST_WAV', $nopt);
	    $logger->debug("    confopts instances set to $nopt ");
	}
	if ($coptions =~ "_CG") {
	    $this->SetValue('CALENDAR', "GREGORIAN");
	    $logger->debug("    confopts CALENDAR set to GREGORIAN ");
	}
	if ($coptions =~ "_AOA") {
	    $this->SetValue('AOFLUX_GRID', "atm");
	    $logger->debug("    confopts AOFLUX_GRID set to atm ");
	}
	if ($coptions =~ "_AOE") {
	    $this->SetValue('AOFLUX_GRID', "exch");
	    $logger->debug("    confopts AOFLUX_GRID set to exch ");
	}
	

	
    }

}



sub AddElementsByGroup{
    my ($this, $configcomp, $attlist ) = @_;
    foreach my $casefile (@casefiles){
	$this->{$casefile}->AddElementsByGroup($configcomp, $attlist);
    }
}


sub WriteCaseXML{
    my($this) = @_;
    foreach my $casefile (@casefiles){
	$this->{$casefile}->write();
    }

}

sub ReparseXML{
    my($this) = @_;
    foreach my $casefile (@casefiles){
	$this->{$casefile}->ReparseXML();
    }

}



sub Compset_Components
{
    my($this) = @_;
    my $compset_longname = $this->GetValue("COMPSET");
    
    my @elements = split /_/, $compset_longname;

# add the driver explicitly - may need to change this if we have more than one.
    my @components;

    push(@components,'drv');

    foreach my $element (@elements){
	next if($element =~ /^\d+$/); # ignore the initial date
	my @element_components = split /%/, $element;
	my $component = lc $element_components[0];
	if ($component =~ m/\d+/) {
	    $component =~ s/\d//g;
	}
	push (@components, $component);
    }	
    return @components;
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

