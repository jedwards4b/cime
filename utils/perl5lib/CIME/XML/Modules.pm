package CIME::XML::Modules;
my $pkg_nm = __PACKAGE__;

use CIME::Base;

my $logger;

BEGIN{
    $logger = Log::Log4perl::get_logger();
}

sub new {
     my ($class, $node) = @_;
     my $this = {};
     bless($this, $class);
     $this->_init($node);
     return $this;
}

sub _init {
  my ($this, $node) = @_;
#  $this->SUPER::_init();
  
  $this->read($node);
  
}

sub read {
    my ($this, $node) = @_;
    if($node->hasAttribute('type')){
	$this->{type} = $node->getAttribute('type');
	my @moduleinit= $node->findnodes(".//*");
	foreach my $pn (@moduleinit){
	    my $name = $pn->nodeName();
	    if($name eq "init_path" or $name eq "cmd_path"){
		my $lang = $pn->getAttribute('lang');
		$this->{init}{$name}{$lang} = $pn->textContent();
	    }elsif($name eq "modules"){
# The data structure in the commands element of the Modules hash is perhaps a bit complicated 
# but it preserves the order dependence of module commands and allows for dependence on 
# other attributes such as compiler or mpilib
# it is an array of hashs of module actions, each action  may operate on mutiple libraries so
# thats another list.   attributes are stored as type=value where value may contain
# regular expressions.  
#  
#
		my @cmd_list;
		my @attlist;
		my $thash={};
		my $ahash=$thash;
		if($pn->hasAttributes()){
		    @attlist = $pn->attributes();
		    foreach my $att (@attlist){
			$ahash->{$att}={};
			$ahash=$ahash->{$att};
		    }
		}
		my @command_nodes = $pn->findnodes(".//command");
		foreach my $cmd (@command_nodes){
		    push(@{$ahash->{$cmd->getAttribute('name')}},$cmd->textContent());
		}
		
		foreach (keys %$thash){
		    push(@cmd_list, {$_=>$thash->{$_}});
		}
		push(@{$this->{commands}},@cmd_list);
		
	    }
	}
    }

}

sub load
{
    my($this, $attributes) = @_;

     if($this->{type} eq "module"){
	$this->load_modules($attributes);
    }elsif($this->{type} eq "dotkit"){
	$this->load_dotkit();
    }elsif($this->{type} eq "soft"){
	$this->load_soft();
    }elsif($this->{type} eq "none"){
	$this->load_none();
    }else{
	$logger->logdie("Unrecognized module_system type $this->{type}");
    }
    
}

sub load_modules
{
    my($this, $attributes) = @_;


    if(defined $this->{init}{init_path}{perl}){
	require $this->{init}{init_path}{perl};

      LIST: foreach my $cmdlist (@{$this->{commands}}){
	  my @cmdlist;
	  my $hashref = $cmdlist;
	  foreach my $cmd (keys %{$hashref}){
	      if($cmd =~ /=/){
		  while($cmd =~ /\s*(.*)\s*=\s*\"(!)?(.*)\"\s*/){
		      my $type = $1;
		      my $neg = defined $2 ? 1: 0;
		      my $val = $3;
		      if(defined $attributes->{$type}){
			  if($attributes->{$type} =~ /$val/ or ($neg && $attributes->{$type} !~ /$val/)){
			      if(ref( $hashref->{$cmd}) eq 'HASH'){
				  $hashref = $hashref->{$cmd};
				  my @kl = keys %{$hashref};
				  $cmd = $kl[0];
			      }
			      
			  }else{
			      next LIST;
			  }
			  
		      }else{
			  $logger->warn("attribute $type not found");
			  next LIST;
		      }
		  }

	      }
	      @cmdlist = @{$hashref->{$cmd}};
	        
	      
	      foreach my $actupon (@cmdlist){
		  $logger->info("$cmd $actupon");
		  module("$cmd $actupon");
		  
	      }
	      
	  }
      }
	
    }
    module("list");
}
sub load_soft
{
    my($this) = @_;
}
sub load_dotkit
{
    my($this) = @_;
}
sub load_none
{
    my($this) = @_;
}
   



1;
 
