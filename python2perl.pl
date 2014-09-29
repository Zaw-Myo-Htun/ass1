#!/usr/bin/perl -w
@variables = ();
$pythonLine = "";
while ($line = <>) {
	chomp $line;
	$pythonLine = $line;
	subset0($line);
	subset1($line);
	print "$pythonLine\n";
}

sub subset0{
	$line = "@_";
if ($line =~ /^#!/ && $. == 1) {
	
		# translate #! line 
		$pythonLine =  "#!/usr/bin/perl -w";
	} elsif ($line =~ /^\s*#/ || $line =~ /^\s*$/) {
	
		# Blank & comment lines can be passed unchanged
		$line = $pythonLine;
	} elsif ($line =~ /^\s*print\s*(.*)\s*$/) {
		# Python's print print a new-line character by default
		# so we need to add it explicitly to the Perl print statement
		$pythonLine = "print \"$1\\n\";";
	}
}

sub subset1{
	$line = "@_";
if ($line =~ /^[^0-9][a-zA-Z_0-9]*\s*=\s*/) {
		$pythonLine .= ";";
		$line =~ s/\s*=.*//;
		if(not($line ~~ @variables)){
		push @variables, $line;
		}
	}
foreach my $var(@variables){
	if ($pythonLine =~ /$var/){
		$pythonLine =~ s/$var/\$$var/g;	
		}
	}
}
