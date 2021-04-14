#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "global.h"
#include <unistd.h>

char *getcwd(char *buf, size_t size);
int yyparse();

int main()
{
    aliasIndex = 0;
    varIndex = 0;
	var_count = 0;

    getcwd(cwd, sizeof(cwd));


    strcpy(varTable.var[varIndex], "PWD");
    strcpy(varTable.word[varIndex], cwd);
	setenv("PWD", cwd, 0);
    varIndex++;
	
    strcpy(varTable.var[varIndex], "HOME");
    strcpy(varTable.word[varIndex], cwd);
	setenv("HOME", cwd, 0);
    varIndex++;
	
    strcpy(varTable.var[varIndex], "PROMPT");
    strcpy(varTable.word[varIndex], "shell");
	setenv("PROMPT", "shell", 0);
    varIndex++;
	
    strcpy(varTable.var[varIndex], "PATH");
    strcpy(varTable.word[varIndex], ".:/bin");
	setenv("PATH", ".:/bin", 0);
    varIndex++;

    system("clear");
    while(1)
    {
        printf("[%s]>> ", varTable.word[2]);
        yyparse();
        argc = 0;
    }

    return 0;
}
