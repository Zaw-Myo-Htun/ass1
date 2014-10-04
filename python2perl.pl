#!/usr/bin/perl -w

@variables = ();
%indentation = ();
$perlLine = "";
$a = "";
$result = "";
$nOfCarlyBracket = 0;
$last = "";
while ($line = <>) {
	$last = $line if eof;
	chomp $line;
	$line =~ s/\s+$//;
	putClose($line);
	#@lines = split(/;/,$line);
	#foreach $b (@lines){
	#if($last eq ""){   # can combine if and elsif
	#putCloseBracket();
	#}elsif($last ne "" && (($last =~ /^\s*[^(elif|else)]/ && $last =~ /^[a-zA-Z]+/))){
	#putCloseBracket();
	#}
	$result = runSubsets($line);
	changeSTDIN();
	
	putsemicolon();
	putDollarSign();
	print "$result";
	if($last ne "" && $last !~ /^[a-zA-Z]+/){
	#putCloseBracket1(); 
	putClose1();
	}
	#}
}
foreach my $var(@variables){
		print "\n$var --- ";
}
sub putDollarSign{
	foreach my $var(@variables){
		#if ($result =~ /^$var[^a-zA-Z]|([^a-zA-Z])$var([^a-zA-Z])/){
			if($result =~ /^$var[^a-zA-Z]/){
			$result =~ s/$var/\$$var/g;
			}
			elsif($result =~ /([^a-zA-Z])$var([^a-zA-Z])/){
			$preVar = $1;
			$postVar = $2;
				$result =~ s/([^a-zA-Z])$var([^a-zA-Z])/$preVar\$$var$postVar/g;
			}
			if($result =~ /(".*)(\$$var)(.*")/){
				$result =~ s/(".*)(\$$var)(.*")/$1$var$3/g; #$number = $number . " $number number";
															#$number = $number . " number ";
															#variable inside " " -- > one is working more than one is not.
			}
			
		#}
	}
}

sub putsemicolon{
my @lines = split /\n/, $result;
$result = "";
foreach my $line (@lines) {
	if(not($line =~ /^#!/ && $. == 1) && not($line =~ /^\s*#/ || $line =~ /^\s*$/) && not($line =~ /(^[\}]|[\{;\}]$)/)){
		$line .= ";";
	}
	$result .= "$line\n";
}	
}

sub changeSTDIN{
	if($result =~ /.*sys.stdin.readline\(\)/){
		 $result =~ s/sys.stdin.readline\(\)/<STDIN>/g;
	}
}
sub putClose{
	foreach my $key (sort {$b <=> $a} keys %indentation ){
	 $value = $indentation{$key};
	 $value =~ /^(\s*)/;
	 my $lengthOfWhiteSpace = length($1);
 	 if("@_" =~ /^(\s*)/){
			my $lengthOfWhiteSpace1 = length($1);
			if ($lengthOfWhiteSpace >= $lengthOfWhiteSpace1){
				print "$value}\n";
				delete $indentation{$key};
			}
		}
	}
}
sub putClose1{
	foreach my $key (sort {$b <=> $a} keys %indentation ){
		$value = $indentation{$key};
		print "$value}\n";
		delete $indentation{$key};
	}
}
sub putCloseBracket{
	if($nOfCarlyBracket>0 && (($line =~ /^\s*[^(elif|else)]/ && $line =~ /^[a-zA-Z]+/))){
		while($nOfCarlyBracket>0){
			print "}\n";
			$nOfCarlyBracket--;
		}
	}
}

sub putCloseBracket1{
	if($nOfCarlyBracket>0 && $last !~ /^[a-zA-Z]+/){
		while($nOfCarlyBracket>0){
			print "}\n";
			$nOfCarlyBracket--;
		}
	}
}

sub runSubsets{
	$a = "@_";
	$pythonLine1 = "@_";
	if (($pythonLine1 =~ /^#!/ && $. == 1) || ($pythonLine1 =~ /^\s*#/ || $line =~ /^\s*$/) || 
	($pythonLine1 =~ /^(\s*)print\s*"(.*)"\s*$/) || $pythonLine1 =~ /^(\s*)print$/ || $pythonLine1 =~ /^(\s*)print\s*(.*)\s*$/){
	$a = subset0($pythonLine1);
	}
	if($pythonLine1 =~ /^\s*[^0-9][a-zA-Z_0-9]*\s*=\s*/ || $pythonLine1 =~ /^\s*print\s*(.*)([+\-*\/%])+(.*)\s*$/){
	$a = subset1($pythonLine1);
	}
	if ($pythonLine1 =~ /^\s*(if|while)\s*(.*):([^:]+)/ || $pythonLine1 =~ /^\s*(break|continue)/){
	$a = subset2($pythonLine1);
	}
	if($pythonLine1 =~ /^\s*import.*/ || $pythonLine1 =~ /^(\s*)sys.stdout.write\((.*)\)/ || 
	$pythonLine1 =~ /(.*)(int\()(.*)(\))/ || $pythonLine1 =~  /range\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)/|| $pythonLine1 =~ /.*:$/){
	$a = subset3($pythonLine1);
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
	} elsif ($pythonLine =~ /^(\s*)print\s*"(.*)"\s*$/) {
		$perlLine = "$1print \"$2\\n\"";
	}elsif($pythonLine =~ /^(\s*)print$/){
		$perlLine = "$1print \"\\n\"";
	}elsif($pythonLine =~ /^(\s*)print\s*(.*)\s*$/){
		$perlLine = "$1print \"$2\\n\"";
	}
	return $perlLine;
}

sub subset1{	#variable and arithmetic operator in print statement
	$pythonLine = "@_";
	$perlLine = "@_";
	if ($pythonLine =~ /^\s*[^0-9][a-zA-Z_0-9]*\s*=\s*/) {	#traslate variable = value line
		$pythonLine =~ s/\s*=.*//;
		$pythonLine =~ s/^\s+//;
		$pythonLine =~ s/\s+$//;
		if(not($pythonLine ~~ @variables)){	# get the variable name and put inside array
		push @variables, $pythonLine;
		}
	}elsif ($pythonLine =~ /^(\s*)print\s*(.*)([+\-*\/%])+(.*)\s*$/) {
		$perlLine = "$1print $2$3$4, \"\\n\"";
	}
	return $perlLine;
}

sub subset2{
	$pythonLine = "@_";
	$perlLine = "@_";
	$line1 = "";
	$line2 = "";
	if ($pythonLine =~ /^\s*(if|while)\s*(.*):([^:]+)/){   #single line if and while
		$line1 = "$1 (" . runSubsets($2) . "){\n";
		@lines = split(/;/,$3);
		foreach $l(@lines){
		$line2 .= runSubsets($l) . "\n";
		}
		$perlLine = $line1 . $line2 . "}";
	}elsif($pythonLine =~ /^\s*(break|continue)/){
		if($1 eq "break"){
		$pythonLine =~ s/break/last/;
		}elsif($1 eq "continue"){
		$pythonLine =~ s/continue/next/;
		}
		$perlLine = $pythonLine;
	}
	return $perlLine;
}

sub subset3{
	$pythonLine = "@_";
	$perlLine = "@_";
	if($pythonLine =~ /^\s*import.*/){
		$perlLine = "";
	}
	if($pythonLine =~ /^(\s*)sys.stdout.write\((.*)\)/){
		$perlLine = "$1print $2\n"; 
	}
	if($pythonLine =~ /(.*)(int\()(.*)(\))/){
		$pythonLine = $1 . $3;
		$perlLine = $1 . $3;
	}
	if($pythonLine =~ /.*:$/){
		$nOfCarlyBracket++;
		$perlLine =~ s/:$/{/;
		if ($pythonLine =~/^(\s*)(if|while|elif|else|for)\s*(.*):$/){
			if($2 eq "for"){
				if($pythonLine =~ /^(\s*)for\s*([^0-9][a-zA-Z_0-9]*)\s*in\s*range\s*\(\s*(.+)\s*,\s*(.+)\s*\)/){
					if(not($2 ~~ @variables)){
						push @variables,$2;
					}
				$lastIndex = "$4-1";
				$perlLine = "$1foreach $2 ($3..$lastIndex){";
				print $perlLine;
				}
			}else{
				$perlLine = "$1$2 (" . runSubsets($3) . "){";
			}
			$indentation{$nOfCarlyBracket} = $1;
			if ($2 eq "else"){
				$perlLine = "$1$2\{";
			}
		}
	}
	#if($pythonLine =~ /range\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)/){
	#	$lastIndex = $2-1;
	#	print "  $1 $lastIndex abcdef";
	#}
	if($perlLine =~ /^\s*(elif)/){   # pythonLine change to what is inside bracket
		$s = $1;
		if($s eq "elif"){ 
		#	$perlLine =~ s/$1/}elsif/;
			$perlLine =~ s/elif/elsif/;
		}
		#else{
		#	$perlLine =~ s/$1/}$s/;
		#}
		#$nOfCarlyBracket--;
	}
	return $perlLine;
}

