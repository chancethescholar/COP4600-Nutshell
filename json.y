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
