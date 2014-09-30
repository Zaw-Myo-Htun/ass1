#!/usr/bin/perl -w
@variables = ();
$perlLine = "";
$a="";
$b="";

while ($line = <>) {
	chomp $line;
	$b = main($line);
	putDollarSign();
	putsemicolon();
	print "$b";
}

sub putDollarSign{
	foreach my $var(@variables){
		#print "$a and $var\n";
		if ($b =~ /($var)/){
			$b =~ s/$var/\$$var/g;	
		}
	}
}

sub putsemicolon{
my @lines = split /\n/, $b;
$b = "";
foreach my $line (@lines) {
	if(not($line =~ /^#!/ && $. == 1) && not($line =~ /^\s*#/ || $line =~ /^\s*$/) && $line =~ /^[^(if)\}]/){
		$line .= ";";
	}
	$b .= "$line\n";
}	
}


sub main{
	$a = "@_";
	$pythonLine = "@_";
	if (($pythonLine =~ /^#!/ && $. == 1) || ($pythonLine =~ /^\s*#/ || $line =~ /^\s*$/) || 
		($pythonLine =~ /^\s*print\s*(.*)\s*$/)){
	$a = subset0($pythonLine);
	}
	if($pythonLine =~ /^[^0-9][a-zA-Z_0-9]*\s*=\s*/ || $pythonLine =~ /^\s*print\s*(.*)([+\-*\/%])+(.*)\s*$/){
	$a = subset1($pythonLine);
	}
	if ($pythonLine =~ /^\s*if\s*(.*):(.*)/){
	$a = subset2($pythonLine);
	}
	return $a;
}


sub subset0{
	$pythonLine = "@_";
	$perlLine = "@_";
	if ($pythonLine =~ /^#!/ && $. == 1) {
		# translate #! line 
		$perlLine =  "#!/usr/bin/perl -w";
	} elsif ($pythonLine =~ /^\s*#/ || $line =~ /^\s*$/) {
		# Blank & comment lines can be passed unchanged
		$perlLine = $pythonLine;
	} elsif ($pythonLine =~ /^\s*print\s*(.*)\s*$/) {
		# Python's print print a new-line character by default
		# so we need to add it explicitly to the Perl print statement
		if ($pythonLine =~ /^\s*print\s*"(.*)"\s*$/) {
			$perlLine = "print \"$1\\n\"";
		}else{
		$perlLine = "print \"$1\\n\"";
		}
	}
	return $perlLine;
}

sub subset1{
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
	if ($pythonLine =~ /^\s*if\s*(.*):(.*)/){   #single line if
		$line1 = "if (" . main($1) . "){\n";
		$line2 = main($2) . "\n}";
		$perlLine = $line1 . $line2;
	}
	return $perlLine;
}