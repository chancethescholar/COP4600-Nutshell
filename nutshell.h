 #include <stdio.h>
 #include <string.h>

int builtin; //Determines if command is built in or not
int command = -1;

void yerror();
int yylex();
int yyparse();
int chdir(); //change directory

int getCommand();
void execute();

