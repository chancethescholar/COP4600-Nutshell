#include <stdio.h>
#include <string.h>
#include "global.h"

int yyparse();
char *getcwd(char *buf, size_t size);

int main()
{
		char* inFileName = NULL;  //in file description
		char* outFileName = NULL;	//out file description
		char* errFileName = NULL; //error file  description
		int openPermission = 0; //open option
		int background = 0; //check & for command in background
		int currentCommand = 0; // current cmd index

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

void execute()
{
	int numBuiltinCommands = 0;
	while(commandTable[numBuiltinCommands].comName != NULL)
	{
		numBuiltinCommands++;
	}
	int input_fd;
	int out_fd;

	int origin_in = dup(0);
	int origin_out = dup(1);
	int origin_error = dup(2);

	if(inFileName)
	{
		input_fd = open(inFileName, O_RDONLY); //open file read only mode
	}

	else
	{
		//no file, use original input
		input_fd = dup(origin_in);
	}

	pid_t child;
	for(int i = 0; i < numBuiltinCommands; i++ )
	{
		//loop through commands
		dup2(input_fd, 0); //redirect input to stdin
		close(input_fd);

		if (i == numBuiltinCommands - 1)
		{
			//last commmand
			if(outFileName)
			{
				out_fd = open(outFileName, openPermission, S_IRUSR | S_IROTH| S_IWUSR | S_IRGRP);
			}

			else
			{
				//no file, use original output
				out_fd = dup(origin_out);
			}
		}

		else
		{
			//not last command, pipe to next command
			int pipe_fd[2];
			pipe(pipe_fd);
			out_fd = pipe_fd[1];
			input_fd = pipe_fd[0];
		}

		dup2(out_fd, 1); //redirect output

		if(errFileName)
		{
			if((out_fd = open(errFileName, O_CREAT|O_TRUNC|O_WRONLY, 0777)) != -1) //open with permission to edit
			{
				//2>
				dup2(out_fd, 2);
			}
			else
			{
				//2>&1
				dup2( STDOUT_FILENO, STDERR_FILENO);
			}
		}

		close(out_fd);

		//check for builtin commands
		if(strcmp(commandTable[i].comName, subAliases(commandTable[i].comName)) != 0)
		{
			char* token;
			char* temp;
			temp = (char*)malloc((strlen(subAliases(commandTable[i].comName))+1)*sizeof(char));
			strcpy(temp,subAliases(commandTable[i].comName));

			token = strtok(temp, " ");

			commandTable[i].numArgs = 0;
			while(token != NULL)
			{
				commandTable[i].args[commandTable[i].numArgs] = token;
				commandTable[i].numArgs++;
				token = strtok(NULL, " ");
			}
			commandTable[i].comName = commandTable[i].args[0];
		}

		if(strcmp(commandTable[i].comName, "bye") == 0)
		{
			exit(0);
		}

		else if(strcmp(commandTable[i].comName, "cd") == 0)
		{
			int returnVal;
			if(commandTable[i].numArgs >= 1 )
			{
				returnVal = runCD(commandTable[i].args[1]);
			}

			else
			{
				returnVal = runCDnoargs();
			}

			if(returnVal != 1)
			{
				fprintf(stderr, "Error at line %d: No such file or directory\n", yylineno);
			}
			continue;
		}

		else if(strcmp(commandTable[i].comName, "setenv") == 0)
		{
			if(commandTable[i].args[1] != NULL && commandTable[i].args[2] != NULL && commandTable[i].args[3] == NULL)
      {
				runSetEnv(commandTable[i].args[1], commandTable[i].args[2]);
			}

			else
			{
				fprintf(stderr, "Error at line %d: Command not found\n", yylineno);
			}
			continue;
		}

		else if(strcmp(commandTable[i].comName, "printenv") == 0)
		{
			if(commandTable[i].args[1] == NULL)
			{
				runPrintEnv();
			}

			else
			{
				fprintf(stderr, "Error at line %d: Command not found\n", yylineno);
			}
			continue;
		}

		else if(strcmp(commandTable[i].comName, "unsetenv") == 0)
		{
			if(commandTable[i].args[1] != NULL && commandTable[i].args[2] == NULL)
			{
				runUnsetEnv(commandTable[i].args[1]);
			}

			else
			{
				fprintf(stderr, "Error at line %d: Command not found\n", yylineno);
			}
			continue;
		}

		else if(strcmp(commandTable[i].comName, "alias") == 0)
		{
			if(commandTable[i].args[1] != NULL && commandTable[i].args[2] != NULL && commandTable[i].args[3] == NULL)
			{
				runSetAlias(commandTable[i].args[1], commandTable[i].args[2]);
			}

			else if(commandTable[i].args[1] == NULL)
			{
				runListAlias();
			}

			else
			{
				fprintf(stderr, "Error at line %d: Command not found\n", yylineno);
			}
			continue;
		}

		else if(strcmp(commandTable[i].comName, "unalias") == 0)
		{
			if(commandTable[i].args[1] != NULL && commandTable[i].args[2] == NULL)
			{
				runRemoveAlias(commandTable[i].args[1]);
			}

			else
			{
				fprintf(stderr, "Error at line %d: Command not found\n", yylineno);
			}
			continue;
		}

		else
		{
			//if non builtin, fork to execute command
			child = fork();
		}

		if(child == 0)
		{
			//child
			char* path = getPath(commandTable[i].comName);
			execv(path, commandTable[i].args); //execute non builtin command

			perror(commandTable[i].comName);
			_exit(1);
		}

		else if(child < 0)
		{
			fprintf(stderr, "Error at line %d: %s cannot be executed\n", yylineno, commandTable[i].comName);
			_exit(1);
		}

		if(!background)
		{
			waitpid(child, NULL, 0);
		}
	}
	//through built in commands

	//reset to original vals
	dup2(origin_in, 0);
	dup2(origin_out, 1);
	dup2(origin_error, 2);
	close(origin_in);
	close(origin_out);
	close(origin_error);

	//clear command table
	for(int i = 0; i < numBuiltinCommands; i++)
	{
		for(int j = 0; j < 500; j++)
		{
			commandTable[i].args[j] = NULL;
		}
		commandTable[i].comName = NULL;
		commandTable[i].numArgs = 0;
	}

	reset();
}

int containChar(char* string, char character)
{
	for(int i = 0; i < strlen(string); i++)
	{
		if(string[i] == character)
		{
			return 1;
		}
	}
	return 0;
}

void escape(char* string)
{
	char* origin = string;
	char* final = string;
	while(*origin)
	{
		*final = *origin++;
		final += (*final != '\\' || *(final + 1) == '\\');
	}
	*final = '\0';
}

void reset()
{
	currentCommand = 0;
	inFileName = NULL;
	outFileName = NULL;
	errFileName = NULL;
	openPermission = 0;
	background = 0;
	//fileno() returns int file descriptor associated with stream pointed to by stream
	//isatty() checks if fd is an open file descriptor in command line,
	//1 if fd is an open file descriptor or 0 if not
	if(isatty(fileno(stdin)))
	{
		printf("[%s]>> ", varTable.word[2]);
		fflush(stdout);
		argc = 0;
	}
}

char* subAliases(char* name)
{
  if(aliasSize == 0)
    return name;

  Node* current = head;

  for(int i = 0; i < aliasSize; i++)
  {
    if(strcmp(current -> name, name) == 0)
    {
      return current -> word;
    }
    current = current -> next;
  }

  return name;
}

bool ifAlias(char* name)
{
  Node* current = head;
  for(int i = 0; i < aliasSize; i++)
  {
    if(strcmp(current -> name, name) == 0)
    {
        return true;
    }
    current = current -> next;
  }
  return false;
}

char* getPath(char* command)
{
	if(strcmp(command, "wc") == 0)
		return "/usr/bin/wc";
	else if(strcmp(command, "grep") == 0)
		return "/usr/bin/grep";
	else if(strcmp(command, "ls") == 0)
		return "/bin/ls";
	else if(strcmp(command, "rm") == 0)
		return "/bin/rm";
	else if(strcmp(command, "cp") == 0)
		return "/bin/cp";
	else if(strcmp(command, "cat") == 0)
		return "/bin/cat";
	else if(strcmp(command, "mkdir") == 0)
		return "/bin/mkdir";
	else if(strcmp(command, "rmdir") == 0)
		return "/bin/rmdir";
	else if(strcmp(command, "mv") == 0)
		return "/usr/bin/mv";
	else if(strcmp(command, "head") == 0)
		return "/usr/bin/head";
	else if(strcmp(command, "awk") == 0)
		return "/usr/bin/awk";
	else if(strcmp(command, "sort") == 0)
		return "/usr/bin/sort";
	else if(strcmp(command, "ssh") == 0)
		return "/usr/bin/ssh";
	else if(strcmp(command, "date") == 0)
		return "/bin/date";
	else if(strcmp(command, "ping") == 0)
		return "/sbin/ping";
	else if(strcmp(command, "tty") == 0)
		return "/usr/bin/tty";
	else if(strcmp(command, "rev") == 0)
		return "/usr/bin/rev";
	else if(strcmp(command, "echo") == 0)
		return "/bin/echo";
	else if(strcmp(command, "touch") == 0)
		return "/usr/bin/touch";
	else if(strcmp(command, "pwd") == 0)
		return "/bin/pwd";
	else if(strcmp(command, "man") == 0)
		return "/usr/bin/man";
	else if(strcmp(command, "nm") == 0)
		return "/usr/bin/nm";
	else if(strcmp(command, "tail") == 0)
		return "/usr/bin/tail";
  else if(strcmp(command, "less") == 0)
  	return "/usr/bin/less";
}
