#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <dirent.h>
#include <sys/stat.h>
#include <string.h>
#include <limits.h>
#include <sys/file.h>
#include "y.tab.h"
#include "nutshell.h"

int main(){
    printf("\tWelcome to the Nutshell\n\nnutshell> ");
    while(&free) //continuous loop to get commnds until bye is called
    {
      getCommand();
      execute();
    }
}

int getCommand()
{
  if(yyparse()) //use yyparse to parse input from user
    return 0;

	else
		return 1;
}

void execute()
{
  switch(command)
  {
	    case 1: //setenv
	        break;
      case 2: //printenv
          break;
      case 3: //unsetenv
          break;
      case 4: //cd
          break;
      case 5: //cd dir
          break;
      case 6: //alias
          break;
      case 7: //unalias
          break;
      case 8: //ls
          break;
      case 9: //ls directory
          break;
      case 10: //bye
          printf("\tgoodbye!\n");
          exit(0);
          break;
    };
}
