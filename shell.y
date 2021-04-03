%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "main.c"

char* environmentVariable(char*);
void escape(char*);
char* tildeExpansion(char*);
int yyval();
int yywrap();

void yyerror(const char * s)
{

	fprintf(stderr, "Error at line %d: %s!\n",yylineno,s);
}

int yywrap()
{
	return 1;
}


%}


%token	<stringvalue> WORD

%token 	NOTOKEN NEWLINE GT LT PIPE ERRORF ERROR1 AND GTGT GTGTAND GTAND  TERMINATOR

%union	{
	char   *stringvalue;
}

%%



complete_command:
commands
;

commands:
command
| commands command
;

command:
pipeline io_redirection   background NEWLINE {
	//printf(" execute \n");
	//printcmdt();
	execute(); // execute  complete command in command table


}
| NEWLINE {

}
| error NEWLINE { yyerrok; }
;

pipeline:
pipeline PIPE {
	currcmd++; //another new simple command create by increase command table array index

} command_arguments
| command_arguments
;

command_arguments:
command_word arguments {

}
;

arguments:
arguments argument
| //can emputy
;
argument:
WORD { // printf(" argument %s ", $1);

	if (contain_char($1, '?') || contain_char($1, '*') )// whildcard reconize from tokens
	{
		glob_t pattern;
		if (glob($1, 0, NULL, &pattern) == 0)// find match pattern
		{
			int num;
			num = pattern.gl_pathc; //number of matching pattern

			int i;


			for (i = 0; i < pattern.gl_pathc; i++)// for loop to add each matching pattern to arguments in same simple command
			{
				commands[currcmd].numArgs++;
				commands[currcmd].args[commands[currcmd].numArgs]=strdup(pattern.gl_pathv[i]);
			}
		}
	}
	else{
		//cannot find any match pattern just add *?pattern as argument
		commands[currcmd].numArgs++;
		commands[currcmd].args[commands[currcmd].numArgs]=$1;
	}
}
;

command_word:
WORD {//printf("command is \n", $1);
	//every command star with cmd XXXXX here we inital command element
	commands[currcmd].comName=$1;
	commands[currcmd].args[0]=$1;
	commands[currcmd].numArgs = 0;

}
;

io_redirection:
io_redirection iodirect
| // can emputy
;

iodirect:
GTGT WORD {
	openPermission = O_WRONLY | O_CREAT | O_APPEND ;// APPEND mode

	outfileName=$2;
}
| GT WORD {
	openPermission = O_WRONLY  | O_TRUNC| O_CREAT; //insert is creat mode
	outfileName=$2;
}
| GTGTAND WORD {
	openPermission = O_WRONLY  | O_CREAT| O_APPEND;
	outfileName = $2;
	errFileName = $2;
}
| GTAND WORD {/*printf("    > %s \n", $2);*/
	openPermission = O_WRONLY  | O_TRUNC| O_CREAT;
	//outfileName = $2;
	errFileName = $2;
}
|
ERRORF WORD {/*printf("    2> %s \n", $2);*/
	openPermission = O_WRONLY | O_TRUNC| O_CREAT ;
	errFileName=$2;
}
|
ERROR1 {/*printf("    2>&1 %s \n", $2);*/
	errFileName="error";
}
| LT WORD {/*printf("    < %s \n", $2);*/
	infileName=$2;
}
;

background:
AND {//printf(" enter & \n");
	background = 1; //indicate background
}
| // can empty
;
%%
