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

void yyerror(const char *str)
{
    fprintf(stderr, "Error: %s\n",str);
}

int yywrap()
{
    return 1;
}

%}

%token SETENV PRINTENV UNSETENV CD LS EOLN ALIAS UNALIAS BYE FLAG WORD
%token NUMBER FILENAME SEMICOLON OPEN_PAREN CLOSE_PAREN OPEN_CARAT CLOSE_CARAT PIPE QUOTE BACKSLASH AMPERSAND
%token BACKSLASH LESSTHAN GREATERTHAN PIPE DOUBLEQUOTE AMPERSAND
%token HOME_AND_PATH HOME ROOT DOT_DOT
%token TILDE

%union
{
    int number;
    char* string;
}

%token <number> NUMBER
%token <string> FILENAME
%token <string> WORD
%token <string> TILDE

%%

commands: /* empty */
     | commands command{printf("\n%s","nutshell> ");};

command:
    setenv_case|printenv_case|unsetenv_case|cd_case|ls_case|EOLN_case|alias_case|unalias_case|bye_case|number_case|filename_case|tilde_case|metach_case;

setenv_case:

printenv_case:

unsetenv_case:

tilde_case:

cd_case:
    |CD EOLN
    {
        builtin = 1;
        printf("\tDirectory changed to Home\n");
        chdir(getenv("HOME"));
    }

    |CD HOME EOLN
    {
        builtin = 1;
        printf("\tDirectory changed to Home\n");
        chdir(getenv("HOME"));
    }

    |CD ROOT EOLN
    {
         builtin = 1;
         printf("\tDirectory changed to root\n");
         chdir("/");
    }

    |CD TILDE EOLN
    {

    }

    |CD FILENAME EOLN
    {

    };

EOLN_case:

ls_case:
    LS EOLN
    {
        builtin = 0;
        DIR *directory;
        directory = opendir(".");
    	struct dirent *dp;
    	if(directory)
        {
    		while((dp = readdir(directory)) != NULL)
            {
    	        printf("%s\n", dp -> d_name);
    		}
    		closedir(directory);
    	}

    	else
    		printf("not valid");
    }

    |LS FILENAME EOLN
    {
        builtin = 0;
        DIR *directory;
        directory = opendir($2);
        struct dirent *dp;
        if(directory)
        {
            while((dp = readdir(directory)) != NULL)
            {
                printf("%s\n", dp -> d_name);
            }
            closedir(directory);
         }

         else
            printf("not valid");
    };

alias_case:

unalias_case:

bye_case:
    BYE
    {
        printf("\t goodbye! \n");
        exit(0);
    };

number_case:

filename_case:

word_case:

metach_case:

lessthan:

greaterthan:

pipe:

doublequote:

backslash:

ampersand:


%%
