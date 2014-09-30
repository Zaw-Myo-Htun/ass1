#!/usr/bin/perl -w
@variables = ();
$perlLine = "";
$a="";
$result="";

while ($line = <>) {
	chomp $line;
	#@lines = split(/;/,$line);
	#foreach $b (@lines){
	$result = runSubsets($line);
	putDollarSign();
	putsemicolon();
	print "$result";
	#}
}

sub putDollarSign{
	foreach my $var(@variables){
		if ($result =~ /($var)/){
			$result =~ s/$var/\$$var/g;	
		}
	}
}

sub putsemicolon{
my @lines = split /\n/, $result;
$result = "";

foreach my $line (@lines) {
	if(not($line =~ /^#!/ && $. == 1) && not($line =~ /^\s*#/ || $line =~ /^\s*$/) && not($line =~ /(^[\}]|[\{\}]$)/)){
		$line .= ";";
	}
	$result .= "$line\n";
}	
}


sub runSubsets{
	$a = "@_";
	$pythonLine = "@_";
	if (($pythonLine =~ /^#!/ && $. == 1) || ($pythonLine =~ /^\s*#/ || $line =~ /^\s*$/) || 
		($pythonLine =~ /^\s*print\s*(.*)\s*$/)){
	$a = subset0($pythonLine);
	}
	if($pythonLine =~ /^[^0-9][a-zA-Z_0-9]*\s*=\s*/ || $pythonLine =~ /^\s*print\s*(.*)([+\-*\/%])+(.*)\s*$/){
	$a = subset1($pythonLine);
	}
	if ($pythonLine =~ /^\s*(if|while)\s*(.*):(.*)/){
	$a = subset2($pythonLine);
	}
	return $a;
}


sub subset0{   #print
	$pythonLine = "@_";
	$perlLine = "@_";
	if ($pythonLine =~ /^#!/ && $. == 1) {
		# translate #! line 
		$perlLine =  "#!/usr/bin/perl -w";
	} elsif ($pythonLine =~ /^\s*#/ || $line =~ /^\s*$/) {
		# Blank & comment lines can be passed unchanged
		$perlLine = $pythonLine;
	} elsif ($pythonLine =~ /^\s*print\s*(.*)\s*$/) {
		$perlLine = "print \"$1\\n\"";
	}
	return $perlLine;
}

sub subset1{	#variable and arithmetic operator in print statement
	$pythonLine = "@_";
	$perlLine = "@_";
	if ($pythonLine =~ /^[^0-9][a-zA-Z_0-9]*\s*=\s*/) {	#traslate variable = value line
		$pythonLine =~ s/\s*=.*//;
		$pythonLine =~ s/^\s+//;
		$pythonLine =~ s/\s+$//;
		if(not($pythonLine ~~ @variables)){	# get the variable name and put inside array
		push @variables, $pythonLine;
		}
	}elsif ($pythonLine =~ /^\s*print\s*(.*)([+\-*\/%])+(.*)\s*$/) {
		$perlLine = "print $1$2$3, \"\\n\"";
	}
	return $perlLine;
}

sub subset2{
	$pythonLine = "@_";
	$perlLine = "@_";
	$line1 = "";
	$line2 = "";
	if ($pythonLine =~ /^\s*(if|while)\s*(.*):(.*)/){   #single line if and while
		$line1 = "$1 (" . runSubsets($2) . "){\n";
		@lines = split(/;/,$3);
		foreach $l(@lines){
		$line2 .= runSubsets($l) . "\n";
		}
		$perlLine = $line1 . $line2 . "}";
	}
	return $perlLine;
}