package CIME::Case;
my $pkg_nm = __PACKAGE__;

use CIME::Base;
use CIME::XML::Files;
use CIME::XML::env_run;
use CIME::XML::env_case;
use CIME::XML::env_build;
use CIME::XML::ConfigComponent;
use CIME::XML::Grids;

my $logger;

our $VERSION = "v0.0.1";

BEGIN{
    $logger = get_logger("CIME::Case");
}

my @casefiles = qw(env_run env_case env_build env_mach_pes);


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

    $this->InitCaseXML($caseroot);

#  $this->SUPER::_init($bar, $baz);
    # Nothing to do here
}

sub InitCaseXML{
    my($this,$caseroot) = @_;
    
    if(defined ($caseroot)){
	# Create objects for each XML file in the case directory
	$caseroot = $this->GetResolvedValue($caseroot);
	$this->{env_run} = CIME::XML::env_run->new($this->GetValue('CIMEROOT'), $caseroot."/env_run.xml");
	$this->{env_case} = CIME::XML::env_case->new($this->GetValue('CIMEROOT'), $caseroot."/env_case.xml");
	$this->{env_build} = CIME::XML::env_build->new($this->GetValue('CIMEROOT'), $caseroot."/env_build.xml");
	# needs env_mach_pes.xml
	# 
    }
}

sub SetValue {
    my($this,$id,$value) = @_;
    
    my $val;
    foreach my $file (@casefiles){
	if(defined $this->{$file}){
	    $val = $this->{$file}->SetValue($id,$value);
	}
	last if(defined $val);
    }
    if(!defined $val){
	$this->{$id}=$value;
    }
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
		$val =  $this->{$hkey}->GetValue($id, $attribute, $name);
	    }
	    last if defined $val;
	}
    }
    return $val;
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



# Resolve any unresolved variables in a given string.

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


#
# configure 
#
#

sub configure {
    my($this) = @_;

    $this->InitCaseXML();

    $this->{files} = CIME::XML::Files->new($this);

    my $compset_files = $this->{files}->GetValues("COMPSETS_SPEC_FILE","component");

# Find the compset longname and target component
    my $target_comp;
    my $compset = $this->GetValue("COMPSET");
    $logger->info("Compset requested: $compset");
    foreach my $comp (keys %$compset_files){
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
    my $file = $this->{files}->GetValue('CONFIG_DRV_FILE');
    $file = $this->GetResolvedValue($file);
    my $configcomp = CIME::XML::ConfigComponent->new($file);
    my @components = $configcomp->GetValue('components');
    $logger->debug( "components are @components");

# Find the specific components for this case 
    $this->Compset_Components();


    
#    my @components = qw(DRV ATM LND ICE OCN ROF GLC WAV);
    my @compcomp = @{$this->{compset_components}};

    if($#components != $#compcomp){
	$logger->logdie("General and specific component counts dont match");
    }

    foreach my $comp (@components){
	my $file;
	my $compcomp = shift @compcomp;
	if($comp eq "DRV"){
	    # $file and $configcomp already defined above
	}else{
	    $file = $this->{files}->GetValue('CONFIG_'.$comp.'_FILE', "component", $compcomp );
	    $file = $this->GetResolvedValue($file);
	    $configcomp = CIME::XML::ConfigComponent->new($file);
	}
	
	$this->{env_run}->AddElementsByGroup($configcomp);
	$this->{env_case}->AddElementsByGroup($configcomp);
	$this->{env_build}->AddElementsByGroup($configcomp);
	
    }

#    $this->{env_run}->write();
#    $this->{env_case}->write();
#    $this->{env_build}->write();

    my $grids_file = $this->GetResolvedValue($this->{files}->GetValue('GRIDS_SPEC_FILE'));
    
    
    $logger->debug("Opening grid file $grids_file");

    $this->{grid_file} = CIME::XML::Grids->new($grids_file);
    my $grid = $this->GetValue('GRID');
    $logger->info("Grid requested: $grid");

    $grid = $this->{grid_file}->getGridLongname($grid, $compset);
    
    $logger->info("Grid Longname: $grid");

    $this->SetValue("GRID", $grid);


    
}


sub WriteCaseXML{
    my($this) = @_;
    $this->{env_build}->write();
    $this->{env_case}->write();
    $this->{env_run}->write();
#    $this->{env_mach_pes}->write();
}



sub Compset_Components
{
    my($this) = @_;
    my $compset_longname = $this->GetValue("COMPSET");
    
    my @elements = split /_/, $compset_longname;

# add the driver explicitly - may need to change this if we have more than one.

    push(@{$this->{compset_components}},'drv');

    foreach my $element (@elements){
	next if($element =~ /^\d+$/); # ignore the initial date
	my @element_components = split /%/, $element;
	my $component = lc $element_components[0];
	if ($component =~ m/\d+/) {
	    $component =~ s/\d//g;
	}
	push (@{$this->{compset_components}}, $component);
    }	
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

