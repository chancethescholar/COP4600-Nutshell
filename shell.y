%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <dirent.h>
#include <sys/stat.h>
#include <string.h>
#include <limits.h>
#include <sys/file.h>
#include "main.c"

void yyerror(const char* s)
{

	fprintf(stderr, "Error at line %d: %s!\n", yylineno, s);
}

int yywrap()
{
	return 1;
}

%}

%token	<stringvalue> WORD

%token 	NOTOKEN NEWLINE LS GT LT PIPE ERRORF ERROR1 AND GTGT GTGTAND GTAND  TERMINATOR

%union
{
	char   *stringvalue;
}

%%

commands:
		| commands command{printf("%s","nutshell> ");};

command:
		command_ls;

command:
pipeline io_redirection   background NEWLINE {
	execute(); // execute, complete command in command table


}
| NEWLINE {

}
| error NEWLINE { yyerrok; }
;

command_ls:
LS NEWLINE
{
		DIR *dir;
		dir = opendir(".");
		struct dirent *dp;
		if(dir)
		{
				while((dp = readdir(dir)) != NULL)
				{
						printf("%s\n", dp -> d_name);
			  }
				closedir(dir);
		}
		else
				printf("not valid");
};


pipeline:
pipeline PIPE
{
	currentCom++; //another new simple command create by increase command table array index

} command_arguments
| command_arguments
;

command_arguments:
command_word arguments {

}
;

arguments:
arguments argument
| //can be empty
;
argument:
WORD
{
	if(contain_char($1, '?') || contain_char($1, '*') )// whildcard reconize from tokens
	{
		glob_t pattern;
		if(glob($1, 0, NULL, &pattern) == 0)// find match pattern
		{
			int num;
			num = pattern.gl_pathc; //number of matching pattern

			int i;


			for(i = 0; i < pattern.gl_pathc; i++)// for loop to add each matching pattern to arguments in same simple command
			{
				commands[currentCom].numArgs++;
				commands[currentCom].args[commands[currentCom].numArgs] = strdup(pattern.gl_pathv[i]);
			}
		}
	}
	else
	{
		//cannot find any match pattern just add *?pattern as argument
		commands[currentCom].numArgs++;
		commands[currentCom].args[commands[currentCom].numArgs] = $1;
	}
}
;

command_word:
WORD
{
	//every command star with cmd XXXXX here we initial command element
	commands[currentCom].comName = $1;
	commands[currentCom].args[0] = $1;
	commands[currentCom].numArgs = 0;

}
;

io_redirection:
io_redirection iodirect
| // can be empty
;

iodirect:
GTGT WORD
{
	openPermission = O_WRONLY | O_CREAT | O_APPEND ;// APPEND mode

	outfileName = $2;
}

| GT WORD
{
	openPermission = O_WRONLY  | O_TRUNC| O_CREAT; //insert is creat mode
	outfileName = $2;
}

| GTGTAND WORD
{
	openPermission = O_WRONLY  | O_CREAT| O_APPEND;
	outfileName = $2;
	errFileName = $2;
}

| GTAND WORD
{
	openPermission = O_WRONLY  | O_TRUNC| O_CREAT;
	//outfileName = $2;
	errFileName = $2;
}

| ERRORF WORD
{
	openPermission = O_WRONLY | O_TRUNC| O_CREAT ;
	errFileName = $2;
}

| ERROR1
{
	errFileName = "error";
}

| LT WORD
{
	infileName = $2;
}
;

background:
AND
{
	background = 1; //indicate background
}
| //can be empty
;
%%
