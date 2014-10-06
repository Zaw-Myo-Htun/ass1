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
	if($line =~ /^\s*(if|while)\s+(.*):([^:]+)/ ){
	putClosingCarlyBracket($line);  #have to be here, can't be after runSubsets... (to skip the first while, if , for, etc line)
	$result = runSubsets($line);
	changeSTDIN();
	$result = putsemicolon($result);
	$result = putDollarSign($result);
	$result = printsubset($result);
	changeSTDWrite();
	$result = putsemicolon($result);
	print "$result";
	}elsif (($line =~ /^#!/ && $. == 1) || ($line =~ /^\s*#/ || $line =~ /^\s*$/)){
		$result = subset0($line);
		$result = putsemicolon($result);
		print "$result";
	}else{
	my @lines = split /\;/, $line;
	foreach my $l (@lines) {
	putClosingCarlyBracket($l);  #have to be here, can't be after runSubsets... (to skip the first while, if , for, etc line)
	$result = runSubsets($l);
	changeSTDIN();
	$result = putsemicolon($result);
	$result = putDollarSign($result);
	$result = printsubset($result);
	changeSTDWrite();
	$result = putsemicolon($result);
	print "$result";
	}
	}
	if($lastLine ne "" && $lastLine !~ /^[a-zA-Z]+/){
		putLastClosingCarlyBracket();
	}
}

sub putDollarSign{					#put dollar in front of variable
	$pythonString = "@_";
	%vars = ();						#key - end position of variables found(matched regex) in line, value - variable names
	@openQuotes = ();
	@closeQuotes = ();
	$openOrClose = 0;
	$index = 0;
	$InsideQuotes = 0;
	$num = 0;
	foreach my $var (@variables){
			while($pythonString =~ m/(.?)"/g){  #get the positons of " to be used below to make sure that the string inside the " -
											#that have the same name as variable won't be treated as variable and will not push
											 # to %vars
				if($1 eq "\""){
					@abc = ();
					push @abc,pos($pythonString)-1;
					push @abc,pos($pythonString);
					foreach $ab(@abc){
						if ($openOrClose == 0){
							push @openQuotes, $ab;
							$openOrClose = 1;
						}else{
							push @closeQuotes, $ab;
							$openOrClose = 0;
						}
					}
				}
				if($1 ne "\"" && $1 ne "\\"){
					if ($openOrClose == 0){
						push @openQuotes, pos($pythonString);
						$openOrClose = 1;
					}else{
						push @closeQuotes, pos($pythonString);
						$openOrClose = 0;
					}
				}
			}
			while($pythonString =~ m/^$var[^a-zA-Z]/g){
				$InsideQuotes = 0;
				for($i = 0; $i < scalar(@openQuotes); $i++){
					if(pos($pythonString)-1 > $openQuotes[$i] && pos($pythonString)-1 < $closeQuotes[$i]){
						$InsideQuotes = 1;
						last;
					}
				}
				if($InsideQuotes == 0){
					$vars{pos($pythonString)} = $var;
				}
			}
			
			while($pythonString =~ m/([^a-zA-Z])$var([^a-zA-Z])/g){
				$InsideQuotes = 0;
				if($1 ne "\$"){ 
					for($i = 0; $i < scalar(@openQuotes); $i++){
						if(pos($pythonString)-1 > $openQuotes[$i] && pos($pythonString)-1 < $closeQuotes[$i]){
							$InsideQuotes = 1;
							last;
						}
					}
					if($InsideQuotes == 0){
						$vars{pos($pythonString)} = $var;
					}
				}
			}		
	}
	foreach my $p (sort {$a<=>$b} keys %vars ){
		$lenOfVar = length($vars{$p})+1;
		$index = $p - $lenOfVar + $num;			#index - index of first character of variable
		substr($pythonString,$index,0,"\$");
		$num++;									#add one because length of result line have been added $
	}
	return $pythonString;
}

sub putsemicolon{					#put ; every single line apart from those start with #!,#,},etc or end with },etc or empty line
	$pythonString = "@_";
	my @lines = split /\n/, $pythonString;	
	$pythonString = "";
	foreach my $line (@lines) {
		if(not($line =~ /^#!/ && $. == 1) && not($line =~ /^\s*#/ || $line =~ /^\s*$/) && not($line =~ /(^[\}]|[\{;\}]$)/)){
			$line .= ";";
		}
		$pythonString .= "$line\n";
	}
	return $pythonString;
}

sub changeSTDIN{					# change sys.stdin.readline to STDIN ...
	if($result =~ /.*sys.stdin.readline\(\)/){
		 $result =~ s/sys.stdin.readline\(\)/<STDIN>/g;
	}
}

sub changeSTDWrite{
	if($result =~ /^(\s*)sys.stdout.write\((.*)\)/){
		$result = "$1print $2\n"; 
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
	if($pythonString =~ /^\s*[^0-9][a-zA-Z_0-9]*\s*=\s*/){
		$pythonString = subset1($pythonString);
	}
	if ($pythonString =~ /^\s*(if|while)\s+(.*):([^:]+)/ || $pythonString =~ /^\s*(break|continue)/){
		$pythonString = subset2($pythonString);
	}
	if($pythonString =~ /^\s*import\s{1}.*/ || $pythonString =~ /^(\s*)sys.stdout.write\((.*)\)/ || 
	$pythonString =~ /(.*\W)(int\()(.*)(\))/ || $pythonString =~ /.*:$/){
		$pythonString = subset3($pythonString);
	}
	return $pythonString;
}

sub printsubset{
	$pythonString = "@_";
	chomp $pythonString;
	$pythonString =~ s/;$//;
	if ($pythonString =~ /^(\s*)(print\s*)/){
		@commas = ();	
		@openQuotes = ();
		@closeQuotes = ();
		$openOrClose = 0;
		$InsideQuotes = 0;
		while($pythonString =~ m/(.?)"/g){  #get the positons of " to be used below to make sure that the string inside the " -
											#that have the same name as variable won't be treated as variable and will not push
											 # to %vars
			if($1 eq "\""){
				@abc = ();
				push @abc,pos($pythonString)-1;
				push @abc,pos($pythonString);
				foreach $ab(@abc){
					if ($openOrClose == 0){
						push @openQuotes, $ab;
						$openOrClose = 1;
					}else{
						push @closeQuotes, $ab;
						$openOrClose = 0;
					}
				}
			}
			if($1 ne "\"" && $1 ne "\\"){
				if ($openOrClose == 0){
					push @openQuotes, pos($pythonString);
					$openOrClose = 1;
				}else{
					push @closeQuotes, pos($pythonString);
					$openOrClose = 0;
				}
			}
		}
		
		while($pythonString =~ m/,/g){
			$InsideQuotes = 0;
			for($i = 0; $i < scalar(@openQuotes); $i++){
				if(pos($pythonString) > $openQuotes[$i] && pos($pythonString) < $closeQuotes[$i]){
					$InsideQuotes = 1;
					last;
				}
			}
			if($InsideQuotes == 0){
				push @commas, pos($pythonString);
			}
		}
		foreach my $c (@commas){
		$index = $c - 1;		
		substr($pythonString,$index,1," ");
		}
	}
	if ($pythonString =~ /^(\s*)(print\s*)\((.*)\)(\s*$)/){
		$pythonString = "$1$2$3$4";
	}
	if ($pythonString =~ /^(\s*)print\s*"(.*)"\s*$/) {
		$pythonString = "$1print \"$2\\n\"";
	}elsif($pythonString =~ /^(\s*)print$/){
		$pythonString = "$1print \"\\n\"";
	}elsif ($pythonString =~ /^(\s*)print\s*(.*)([+\-*\/%])+(.*)\s*$/) {
		$pythonString = "$1print $2$3$4, \"\\n\"";
	}elsif($pythonString =~ /^(\s*)print\s*(.*)\s*$/){
		$pythonString = "$1print \"$2\\n\"";
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
	}
	return $perlLine;
	#elsif ($pythonLine =~ /^(\s*)print\s+(.*)/) {					# if print statement
	#	#$perlLine = "$1print \"$2\\n\"";
	#	$spaceInFront = $1;
	#	$printString = "";
	#	if($2 =~ /^\((.*)\)/){
	#		$printString = $1;
	#	}
	#	$perlLine = "${spaceInFront}print \"${printString}\\n\"";
	#}
	
	
	
	
	#elsif($pythonLine =~ /^(\s*)print$/){
	#	$perlLine = "$1print \"\\n\"";
	#}elsif ($pythonLine =~ /^(\s*)print\s*(.*)([+\-*\/%])+(.*)\s*$/){
	#	$perlLine = "$1print $2$3$4, \"\\n\"";
	#}elsif($pythonLine =~ /^(\s*)print\s*(.*)\s*$/){
	#	$perlLine = "$1print \"$2\\n\"";
	#}
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
	if ($pythonLine =~ /^\s*(if|while)\s+(.*):([^:]+)/){   #single line if and while
		$line1 = "$1 (" . runSubsets($2) . "){\n";
		@lines = split(/;/,$3);
		foreach $l(@lines){
			$string = runSubsets($l);
			$string = putsemicolon($string);
			$string = putDollarSign($string);
			$string = printsubset($string);
			$line2 .= $string . "\n";
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
	if($pythonLine =~ /^\s*import\s{1}.*/){
		$perlLine = "";
	}
	#if($pythonLine =~ /^(\s*)sys.stdout.write\((.*)\)/){
	#	$perlLine = "$1print $2\n"; 
	#}
	if($pythonLine =~ /(.*\W)(int\()(.*)(\))/){
		$pythonLine = $1 . $3;
		$perlLine = $1 . $3;
	}
	if($pythonLine =~ /.*:$/){
		$nOfOpeningCarlyBracket++;
		$perlLine =~ s/:$/{/;
		if ($pythonLine =~/^(\s*)(if|while|elif|else|for)\s+(.*):$/ || $pythonLine =~ /^(\s*)(else)\s*(.*):$/){
			if($2 eq "for"){
				if($pythonLine =~ /^(\s*)for\s+([^0-9][a-zA-Z_0-9]*)\s+in\s+range\s*\(\s*(.+)\s*,\s*(.+)\s*\)/){
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

