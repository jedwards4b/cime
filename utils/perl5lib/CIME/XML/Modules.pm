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
		my @cmd_list;
		my @attlist;
		my $thash={};
		my $ahash={};
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
		push(@cmd_list, $thash);
		push(@{$this->{commands}},@cmd_list);
		
	    }
	}
    }

}

sub load
{
    my($this) = @_;

    if($this->{type} eq "module"){
	$this->load_modules();
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
    my($this) = @_;


    if(defined $this->{init}{init_path}{perl}){
	require $this->{init}{init_path}{perl};

	foreach my $cmdlist (@{$this->{commands}}){
	    foreach my $cmd (@{$cmdlist}){
		foreach my $action (keys %$cmd){
		    if($action =~ /(.*)=(.*)/){
		    }else{
			$logger->info("$action $cmd->{$action}");
			module($action, $cmd->{$action});
		    }
		}
	    }
	}
	
    }
      
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
 
