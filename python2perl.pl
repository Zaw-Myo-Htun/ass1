#!/usr/bin/perl -w

%variables = ();					#all variables detected while processing each line
%indentation = ();					#key - number of open bracket,value - number of spaces in front
$perlLine = "";						#return from subset methods.
$result = "";						#final perl line to be printed;
$nOfOpeningCarlyBracket = 0;		#number of opening bracket use in the line (if, elsif , while , for ....)
$lastLine = "";						#used for adding closing bracket.

while ($line = <>) {
	$lastLine = $line if eof;		#get the last line to be used when closing bracket still left to be added.
	chomp $line;					
	$line =~ s/\s+$//;
	$result = main($line);
	print $result;
	if($lastLine ne "" && $lastLine !~ /^[a-zA-Z]+/){
		putLastClosingCarlyBracket();
	}
}

sub main{
	$string = "@_";
	$returnString = "";
	if (($string =~ /^#!/ && $. == 1) || ($string =~ /^\s*#/ || $string =~ /^\s*$/)){
		$string = subset0($string);
		$string = putsemicolon($string);
		$returnString = $string;
	}elsif($string =~ /^\s*(if|while)\s+(.*):([^:]+)/ ){
		putClosingCarlyBracket($string);  #have to be here, can't be after runSubsets... (to skip the first while, if , for, etc line)
		$string = runSubsets($string);
		$string = changeSTDIN($string);
		$string = putsemicolon($string);
		$string = changeLen($string);
		$string = putDollarSign($string);
		$string = printsubset($string);
		$string = changeSTDWrite($string);
		$string = putsemicolon($string);
		$returnString = $string;
	}else{
		my @lines = split /\;/, $string;
		foreach my $l (@lines) {
		putClosingCarlyBracket($l);  	#have to be here, can't be after runSubsets... (to skip the first while, if , for, etc line)
		$string = runSubsets($l);
		$string = putsemicolon($string);
		$string = changeLen($string);
		$string = putDollarSign($string);
		$string = printsubset($string);
		$string = changeSTDIN($string);
		$string = changeSTDWrite($string);
		$string = putsemicolon($string);
		$returnString .= $string;
		}
	}
	return $returnString;
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

sub runSubsets{							#for subset1,2 and 3
	$string = "@_";
	if($string =~ /^\s*[^0-9][a-zA-Z_0-9]*\s*=\s*/){
		$string = subset1($string);
	}
	if ($string =~ /^\s*(if|while)\s+(.*):([^:]+)/ || $string =~ /^\s*(break|continue)/){
		$string = subset2($string);
	}
	if($string =~ /^\s*import\s{1}.*/ || $string =~ /^(\s*)sys.stdout.write\((.*)\)/ || 
	   $string =~ /(.*\W)(int\()(.*)(\))/ || $string =~ /.*:$/){
		$string = subset3($string);
	}
	if($string =~ /^(\s*)([^0-9][a-zA-Z_0-9]*).append\((.*)\)/ || 
	   $string =~ /^(\s*)(.*)([^0-9][a-zA-Z_0-9]*).pop\(\)(.*)/ || 
	   $string =~ /(^\s*)([^0-9][a-zA-Z_0-9]*\s*=\s*)sys.stdin.readlines\(\)/){
		$string = subset4($string);
	}
	return $string;
}

sub subset0{ 
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
}

sub subset1{	# variable
	$pythonLine = "@_";
	$perlLine = "@_";
	$type = "";
	if ($pythonLine =~ /(^\s*[^0-9][a-zA-Z_0-9]*\s*=\s*)(.*)/) {	#traslate variable = value line
		$value1 = $1;
		$value2 = $2;
		if ($2 =~ /^["']/){
			$type = "string";
		}elsif($2 =~ /^\[/){
			$value2 =~ s/^\[/\(/;
			$value2 =~ s/\]$/\)/;
			$perlLine = "$value1$value2";
			$type = "array";
		}elsif($2 =~ /^\s*sys.stdin.readlines\(\)/){
			$type = "array";
		}else{
			$type = "digit";
		}
		$pythonLine =~ s/\s*=.*//;
		$pythonLine =~ s/^\s+//;
		$pythonLine =~ s/\s+$//;
		if(not exists $variables{$pythonLine}){	# get the variable name and put inside array
			$variables{$pythonLine} = $type;
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
	if($pythonLine =~ /(.*\W)(int\()(.*)(\))/){
		$pythonLine = $1 . $3;
		$perlLine = $1 . $3;
	}
	if($pythonLine =~ /.*:$/){
		$nOfOpeningCarlyBracket++;
		$perlLine =~ s/:$/{/;
		if ($pythonLine =~/^(\s*)(if|while|elif|else|for)\s+(.*):$/ || $pythonLine =~ /^(\s*)(else)\s*(.*):$/){
			if($2 eq "for"){
				if($pythonLine =~ /^(\s*)for\s+([^0-9][a-zA-Z_0-9]*)\s+in\s+.*/){
					#if(not($2 ~~ @variables)){
					if(not exists $variables{$2}){
						$variables{$2} = "digit";
						#push @variables,$2;
					}
					if($pythonLine =~ /^(\s*)for\s+([^0-9][a-zA-Z_0-9]*)\s+in\s+range\s*\(\s*(.+)\s*,\s*(.+)\s*\)/){
						$lastIndex = "$4-1";
						$perlLine = "$1foreach $2 ($3..$lastIndex){";
					}
					if($pythonLine =~ /^(\s*)for\s+([^0-9][a-zA-Z_0-9]*)\s+in\s+sys.stdin/){
						$perlLine = "$1foreach $2 (<STDIN>){";
					}
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

sub subset4{
	$pythonLine = "@_";
	$perlLine = "@_";
	if($pythonLine =~ /^(\s*)([^0-9][a-zA-Z_0-9]*).append\((.*)\)/){
		$perlLine = "$1push $2, $3";
	}elsif($pythonLine =~ /^(\s*)(.*\W)([^0-9][a-zA-Z_0-9]*).pop\(\)(.*)/){
		$perlLine = "$1$2pop $3$4";
	}
	if ($pythonLine =~ /(^\s*)([^0-9][a-zA-Z_0-9]*)\s*=\s*sys.stdin.readlines\(\)/){
		$nOfOpeningCarlyBracket++;
		$indentation{$nOfOpeningCarlyBracket} = $1;
		$perlLine = "$1while (<STDIN>){\n$1\tpush $2, \$_";
	}
	return $perlLine;
}

sub putsemicolon{					#put ; every single line apart from those start with #!,#,},etc or end with },etc or empty line
	$string = "@_";
	my @lines = split /\n/, $string;	
	$string = "";
	foreach my $line (@lines) {
		if(not($line =~ /^#!/ && $. == 1) && not($line =~ /^\s*#/ || $line =~ /^\s*$/) && not($line =~ /(^[\}]|[\{;\}]$)/)){
			$line .= ";";
		}
		$string .= "$line\n";
	}
	return $string;
}

sub putDollarSign{					#put dollar in front of variable
	$string = "@_";
	%positionOfVars = ();						#key - end position of variables found(matched regex) in line, value - variable names
	@openQuotes = ();
	@closeQuotes = ();
	$openOrClose = 0;
	$index = 0;
	$InsideQuotes = 0;				#0-not inside quotes , 1-inside quotes
	$num = 0;
	foreach my $var (keys %variables){
		while($string =~ m/(.?)"/g){  #get the positons of " to be used below to make sure that the string inside the " -
										#that have the same name as variable won't be treated as variable and will not push
										 # to %vars
			if($1 eq "\""){
				@quotes = ();
				push @quotes,pos($string)-1;
				push @quotes,pos($string);
				foreach $q(@quotes){
					if ($openOrClose == 0){
						push @openQuotes, $q;
						$openOrClose = 1;
					}else{
						push @closeQuotes, $q;
						$openOrClose = 0;
					}
				}
			}
			if($1 ne "\"" && $1 ne "\\"){
				if ($openOrClose == 0){
					push @openQuotes, pos($string);
					$openOrClose = 1;
				}else{
					push @closeQuotes, pos($string);
					$openOrClose = 0;
				}
			}
		}
		while($string =~ m/^$var[^a-zA-Z]/g){
			$InsideQuotes = 0;
			for($i = 0; $i < scalar(@openQuotes); $i++){
				if(pos($string)-1 > $openQuotes[$i] && pos($string)-1 < $closeQuotes[$i]){
					$InsideQuotes = 1;
					last;
				}
			}
			if($InsideQuotes == 0){
				$positionOfVars{pos($string)} = $var;
			}
		}
		
		while($string =~ m/([^a-zA-Z])$var([^a-zA-Z])/g){
			$InsideQuotes = 0;
			if($1 ne "\$"){ 
				for($i = 0; $i < scalar(@openQuotes); $i++){
					if(pos($string)-1 > $openQuotes[$i] && pos($string)-1 < $closeQuotes[$i]){
						$InsideQuotes = 1;
						last;
					}
				}
				if($InsideQuotes == 0){
					$positionOfVars{pos($string)} = $var;
				}
			}
		}
		
		while($string =~ m/$var([^a-zA-Z])/g){
			$InsideQuotes = 0;
			if(substr($string,pos($string)-(length($var)+2),1) ne "\$"){ 
				for($i = 0; $i < scalar(@openQuotes); $i++){
					if(pos($string)-1 > $openQuotes[$i] && pos($string)-1 < $closeQuotes[$i]){
						$InsideQuotes = 1;
						last;
					}
				}
				if($InsideQuotes == 0){
					if(not exists $positionOfVars{pos($string)}){
						$positionOfVars{pos($string)} = $var;
					}
				}
			}
		}
				
	}
	foreach my $p (sort {$a<=>$b} keys %positionOfVars ){	#put dollar sign
		$lenOfVar = length($positionOfVars{$p})+1;
		$index = $p - $lenOfVar + $num;			#index - index of first character of variable
		if($variables{$positionOfVars{$p}} eq "digit" || $variables{$positionOfVars{$p}} eq "string" ){
			substr($string,$index,0,"\$");
		}else{
			my $char = substr($string, $p-1, 1);
			if($char eq "["){
				substr($string,$index,0,"\$");
			}else{
				substr($string,$index,0,"\@");
			}
		}
		$num++;									#add one because length of result line have been added $
	}
	return $string;
}

sub printsubset{ #print subset
	$string = "@_";
	$isPrintf = 0;  			# 0 - is not printf, 1 - is printf
	$isLastComma = 0;			# 0 - the last char is not comma, 1 - the last char is comma
	chomp $string;
	$string =~ s/;$//;
	if ($string =~ /^(\s*)(print\s*)/){
		@commas = ();	
		@percentages = ();
		@openQuotes = ();
		@closeQuotes = ();
		$openOrClose = 0;
		$InsideQuotes = 0;
		while($string =~ m/(.?)"/g){  #get the positons of " to be used below to make sure that the string inside the " -
											#that have the same name as variable won't be treated as variable and will not push
											 # to %vars
			if($1 eq "\""){
				@quotes = ();
				push @quotes,pos($string)-1;
				push @quotes,pos($string);
				foreach $q(@quotes){
					if ($openOrClose == 0){
						push @openQuotes, $q;
						$openOrClose = 1;
					}else{
						push @closeQuotes, $q;
						$openOrClose = 0;
					}
				}
			}
			if($1 ne "\"" && $1 ne "\\"){
				if ($openOrClose == 0){
					push @openQuotes, pos($string);
					$openOrClose = 1;
				}else{
					push @closeQuotes, pos($string);
					$openOrClose = 0;
				}
			}
		}
		
		while($string =~ m/%\w/g){
			$InsideQuotes = 0;
			for($i = 0; $i < scalar(@openQuotes); $i++){
				if(pos($string) > $openQuotes[$i] && pos($string) < $closeQuotes[$i]){
					push @percentages, pos($string);
					$isPrintf = 1;
				}
			}
		}
		
		
		if($isPrintf == 0){
			$lengthOfString = length($string);
			while($string =~ m/,/g){
				$InsideQuotes = 0;
				for($i = 0; $i < scalar(@openQuotes); $i++){
					if(pos($string) > $openQuotes[$i] && pos($string) < $closeQuotes[$i]){
						$InsideQuotes = 1;
						last;
					}
				}
				if($InsideQuotes == 0){
					push @commas, pos($string);
				}
			}
			foreach my $c (@commas){
				if(not($lengthOfString == $c)){
					$index = $c - 1;		
					substr($string,$index,1," ");
				}else{
					$isLastComma = 1;
					$index = $c - 1;
					substr($string,$index,1,"");
				}
			}
		}
	}
	
	if($isPrintf == 1){
		if ($string =~ /^(\s*)print(\s*.*)%(\s*.*)/){
			$string = "$1printf$2. \"\\n\",$3";
		}
	}else{
		if ($string =~ /^(\s*)(print\s*)\((.*)\)(\s*$)/){
			$string = "$1$2$3$4";
		}
		if ($string =~ /^(\s*)print\s*"(.*)"\s*$/) {
			if($isLastComma == 1){
				$string = "$1print \"$2\"";
			}else{
				$string = "$1print \"$2\\n\"";
			}
		}elsif($string =~ /^(\s*)print$/){
			$string = "$1print \"\\n\"";
		}elsif ($string =~ /^(\s*)print\s*(.*)([+\-*\/%])+(.*)\s*$/){
			$InsideQuotes = 0;
			for($i = 0; $i < scalar(@openQuotes); $i++){
				if(pos($3) > $openQuotes[$i] && pos($3) < $closeQuotes[$i]){
					$InsideQuotes = 1;
					last;
				}
			}
			if($InsideQuotes == 0){
				if($isLastComma == 1){
					$string = "$1print $2$3$4";
				}else{	
					$string = "$1print $2$3$4, \"\\n\"";
				}
			}
		}elsif($string =~ /^(\s*)print\s*(.*)\s*$/){
			if($isLastComma == 1){
				$string = "$1print \"$2\"";
			}else{
				$string = "$1print \"$2\\n\"";
			}
		}
	}
	return $string;
}

sub changeLen{
	$string = "@_";
	if($string =~ /.*\Wlen\((.*)\)/){
		$value = $1;
		$value =~ s/^\s+//;
		$value =~ s/\s+$//;
		if($value =~ /^\[/ || $variables{$value} eq "array"){
			if($value =~ /^\[/){
				$string =~ s/\[//;
				$string =~ s/\]//;
			}
			$string =~ s/len/scalar/;
		}else{
			$string =~ s/len/length/;
		}
	}
	return $string;
}
sub changeSTDIN{					# change sys.stdin.readline to STDIN ...
	$string = "@_";
	if($string =~ /.*sys.stdin.readline\(\)/){
		 $string =~ s/sys.stdin.readline\(\)/<STDIN>/g;
	}
	return $string;
}

sub changeSTDWrite{
	$string = "@_";
	if($string =~ /^(\s*)sys.stdout.write\((.*)\)/){
		$string = "$1print $2\n"; 
	}
	return $string;
}
