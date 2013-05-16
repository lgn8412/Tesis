#!/usr/bin/perl -w

 use strict;
 use Parse::RecDescent;
 use Data::Dumper;

 use vars qw(%VARIABLE);

 # Enable warnings within the Parse::RecDescent module.
 $::RD_ERRORS = 1; # Make sure the parser dies when it encounters an error
 $::RD_WARN   = 1; # Enable warnings. This will warn on unused rules &c.
 $::RD_HINT   = 1; # Give out hints to help fix problems.
 #$::RD_TRACE  = 1; # Trace the whole thing
 my $grammar = <<'_EOGRAMMAR_';

   # Terminals (macros that can't expand further)
   #

   startrule:	statement(s /;/) eofile
 
   statement:	for_statement
		| while_statement
		| if_statement
		| instruction
	#el newline es opcional, pero si existe, debe haber identación
	#revisar que dentro de statement haya identacion correspondiente

   for_statement:	/for/ VARIABLE /in/ LIST ':' '\n' '\t' statement     

   while_statement:	/while/ expression ':' '\n' '\t' statement

   if_statement:	/if/ expression ':' '\n' '\t' statement

   instruction: print_instruction
              	| assign_instruction
                
   print_instruction:	/print/i expression 
                      	{ print $item{expression}."\n" }
   assign_instruction:	VARIABLE "=" expression
                      	{ $main::VARIABLE{$item{VARIABLE}} = $item{expression} }
   
   expressions:	expression 
		| expression',' expressions   

   expression:	 /abs/i expression
             	{ $return = abs($item{expression}) }
             	| /sqrt/i expression
             	{ $return = sqrt($item{expression}) }
             	| '(' expression ')'
             	{ $return = $item{expression} } 
             	| INTEGER OP expression
             	{ $return = main::expression(@item) }
             	| STRING '+' expression
	     	{ $return = main::concat(@item) }              
             	| VARIABLE OP expression
             	{ $return = main::expression(@item) }
		| INTEGER COMP_OP expression
		{ $return = main::expression(@item) }
		| VARIABLE COMP_OP expression
		{ $return = main::expression(@item) }
             	| INTEGER
             	| VARIABLE
             	{ $return = $main::VARIABLE{$item{VARIABLE}} }
		| LIST '=' '[' expressions ']'
		{ $return = $main::LIST{$item{LIST} } }
             	| STRING
		|
              
  
   COMP_OP:	'<' | '>' | '==' | '>=' | '<=' | '!=' # Comparison operators
   OP:		m([-+*/%])      # Mathematical operators
   INTEGER:	/[+-]?[0-9]*\.?[0-9]+/     # Signed integers
   VARIABLE:	/\w[a-z0-9_]*/i # Variable
   LIST:	/\w[a-z0-9_]*/i '[]' #Lista o array	
   STRING:	/'.*?'/
   eofile:	/^\Z/
 

_EOGRAMMAR_

 sub expression {
   shift;
   my ($lhs,$op,$rhs) = @_;
   $lhs = $VARIABLE{$lhs} if $lhs=~/[^-+(\.)0-9]/;
   return eval "$lhs $op $rhs";
 }
 sub concat {
  shift;
  my ($lhs,$op,$rhs) = @_;
  $lhs =~ s/^'(.*)'$/$1/;
  $rhs =~ s/^'(.*)'$/$1/;

return "$lhs$rhs"
}

 my $parser = Parse::RecDescent->new($grammar);

 print "a=2\n";			$parser->startrule("a= 'hola '   + 3.2 ");
 print "1!=2\n";		$parser->startrule("print(1==2)");		
 print "b=1+2.2\n";		$parser->startrule("b=1+2.2");
 print "print(a)\n";		$parser->startrule("print(a)");
 print "print(b)\n";		$parser->startrule("print(b)");
 print "print(2+2/4)\n";	$parser->startrule("print(2+2/4)");
 print "print(2+(-2/4))\n";	$parser->startrule("print(2+(-2/4))");
 print "a = 5 ; print(a)\n";	$parser->startrule("a = 5 ; print(a)");
 print "print abs(-2)\n";	$parser->startrule("print abs(-2)");
 print "print sqrt(3)\n";	$parser->startrule("print sqrt(3)");

