#!/usr/bin/perl -w

@variables = ();					#all variables detected while processing each line
%indentation = ();					#key - number of open bracket,value - number of spaces in front
$perlLine = "";						#return from subset methods.
$result = "";						#final perl line to be printed;
$nOfOpeningCarlyBracket = 0;		#number of opening bracket use in the line (if, elsif , while , for ....)
$lastLine = "";						#used for adding closing bracket.

while ($line = <>) {
	$lastLine = $line if eof;		#get the last line to be used when closing bracket still left to be added.
	chomp $line;
	$line =~ s/\s+$//;
	putClosingCarlyBracket($line);  #have to be here, can't be after runSubsets... (to skip the first while, if , for, etc line)
	$result = runSubsets($line);
	changeSTDIN();
	putsemicolon();
	putDollarSign();
	print "$result";
	if($lastLine ne "" && $lastLine !~ /^[a-zA-Z]+/){
		putLastClosingCarlyBracket();
	}
}

sub putDollarSign{					#put dollar in front of variable
	%vars = ();						#key - end position of variables found(matched regex) in line, value - variable names
	$index = 0;
	$num = 0;
	foreach my $var (@variables){
			while($result =~ m/^$var[^a-zA-Z]/g){
				$vars{pos($result)} = $var;
			}
			while($result =~ m/([^a-zA-Z])$var([^a-zA-Z])/g){
				$vars{pos($result)} = $var;
			}		
	}
	foreach my $p (sort {$a<=>$b} keys %vars ){
		$lenOfVar = length($vars{$p})+1;
		$index = $p - $lenOfVar + $num;			#index - index of first character of variable
		substr($result,$index,0,"\$");
		$num++;									#add one because length of result line have been added $
	}
}

sub putsemicolon{					#put ; every single line apart from those start with #!,#,},etc or end with },etc or empty line
	my @lines = split /\n/, $result;		
	$result = "";
	foreach my $line (@lines) {
		if(not($line =~ /^#!/ && $. == 1) && not($line =~ /^\s*#/ || $line =~ /^\s*$/) && not($line =~ /(^[\}]|[\{;\}]$)/)){
			$line .= ";";
		}
		$result .= "$line\n";
	}
}

sub changeSTDIN{					# change sys.stdin.readline to STDIN ...
	if($result =~ /.*sys.stdin.readline\(\)/){
		 $result =~ s/sys.stdin.readline\(\)/<STDIN>/g;
	}
}

sub putClosingCarlyBracket{			# put } function
	foreach my $key (sort {$b <=> $a} keys %indentation ){		#sorted by descending order to process the most recent indentation
		$value = $indentation{$key};
		$value =~ /^(\s*)/;
		my $lengthOfWhiteSpace = length($1);					#lengthOfWhiteSpace - length of white space in front of the line end in { (start with for, if, etc)
 		if("@_" =~ /^(\s*)/){
			my $lengthOfWhiteSpace1 = length($1);				#lengthOfWhiteSpace1 - length of white space in front of every line
			if ($lengthOfWhiteSpace >= $lengthOfWhiteSpace1){ 	#comparing the two white spaces, add } if $lengthOfWhiteSpace >= $lengthOfWhiteSpace1
				print "$value}\n";
				delete $indentation{$key};
				$nOfOpeningCarlyBracket--;
			}
		}
	}
}

sub putLastClosingCarlyBracket{		#put } function if the last line and still left indentation
	foreach my $key (sort {$b <=> $a} keys %indentation ){
		$value = $indentation{$key};
		print "$value}\n";
		delete $indentation{$key};
		$nOfOpeningCarlyBracket--;
	}
}

sub runSubsets{
	$pythonString = "@_";
	if (($pythonString =~ /^#!/ && $. == 1) || ($pythonString =~ /^\s*#/ || $pythonString =~ /^\s*$/) || 
	($pythonString =~ /^(\s*)print\s*"(.*)"\s*$/) || $pythonString =~ /^(\s*)print$/ || 
	$pythonString =~ /^(\s*)print\s*(.*)\s*$/){
		$pythonString = subset0($pythonString);
	}
	if($pythonString =~ /^\s*[^0-9][a-zA-Z_0-9]*\s*=\s*/ || $pythonString =~ /^\s*print\s*(.*)([+\-*\/%])+(.*)\s*$/){
		$pythonString = subset1($pythonString);
	}
	if ($pythonString =~ /^\s*(if|while)\s*(.*):([^:]+)/ || $pythonString =~ /^\s*(break|continue)/){
		$pythonString = subset2($pythonString);
	}
	if($pythonString =~ /^\s*import.*/ || $pythonString =~ /^(\s*)sys.stdout.write\((.*)\)/ || 
	$pythonString =~ /(.*)(int\()(.*)(\))/ || $pythonString =~  /range\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)/|| $pythonString =~ /.*:$/){
		$pythonString = subset3($pythonString);
	}
	return $pythonString;
}


sub subset0{	# print statment
	$pythonLine = "@_";
	$perlLine = "@_";
	if ($pythonLine =~ /^#!/ && $. == 1) {
		# translate #! line 
		$perlLine =  "#!/usr/bin/perl -w";
	}elsif ($pythonLine =~ /^\s*#/ || $line =~ /^\s*$/) {
		# Blank & comment lines can be passed unchanged
		$perlLine = $pythonLine;
	}elsif ($pythonLine =~ /^(\s*)print\s*"(.*)"\s*$/) {
		$perlLine = "$1print \"$2\\n\"";
	}elsif($pythonLine =~ /^(\s*)print$/){
		$perlLine = "$1print \"\\n\"";
	}elsif ($pythonLine =~ /^(\s*)print\s*(.*)([+\-*\/%])+(.*)\s*$/) {
		$perlLine = "$1print $2$3$4, \"\\n\"";
	}elsif($pythonLine =~ /^(\s*)print\s*(.*)\s*$/){
		$perlLine = "$1print \"$2\\n\"";
	}
	return $perlLine;
}

sub subset1{	# variable
	$pythonLine = "@_";
	$perlLine = "@_";
	if ($pythonLine =~ /^\s*[^0-9][a-zA-Z_0-9]*\s*=\s*/) {	#traslate variable = value line
		$pythonLine =~ s/\s*=.*//;
		$pythonLine =~ s/^\s+//;
		$pythonLine =~ s/\s+$//;
		if(not($pythonLine ~~ @variables)){	# get the variable name and put inside array
			push @variables, $pythonLine;
		}
	}
	return $perlLine;
}

sub subset2{	# logical operators, comparison operators(numeric only), bitwise operators, single-line if, while, break ,continue
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
		$nOfOpeningCarlyBracket++;
		$perlLine =~ s/:$/{/;
		if ($pythonLine =~/^(\s*)(if|while|elif|else|for)\s*(.*):$/){
			if($2 eq "for"){
				if($pythonLine =~ /^(\s*)for\s*([^0-9][a-zA-Z_0-9]*)\s*in\s*range\s*\(\s*(.+)\s*,\s*(.+)\s*\)/){
					if(not($2 ~~ @variables)){
						push @variables,$2;
					}
				$lastIndex = "$4-1";
				$perlLine = "$1foreach $2 ($3..$lastIndex){";
				}
			}else{
				$perlLine = "$1$2 (" . runSubsets($3) . "){";
			}
			$indentation{$nOfOpeningCarlyBracket} = $1;
			if ($2 eq "else"){
				$perlLine = "$1$2\{";
			}
		}
	}
	if($perlLine =~ /^\s*(elif)/){   # pythonLine change to what is inside bracket
		$s = $1;
		if($s eq "elif"){ 
			$perlLine =~ s/elif/elsif/;
		}
	}
	return $perlLine;
}

