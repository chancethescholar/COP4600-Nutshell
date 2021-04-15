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
#include "global.h"

int chdir();
char* getcwd();

int yylex(void);
int yyerror(char *s);
int runSetEnv(char* variable, char* word);
int runPrintEnv();
int runUnsetEnv(char *variable);
int runCDnoargs(void);
int runCD(char* arg);
int runSetAlias(char *name, char *word);
int runListAlias(void);
int runRemoveAlias(char *name);
int runPipe(char* firstCom, char* firstArg, char* secondCom, char* secondArg);
int runNonBuiltin(char* command, char* arg);
int runNonBuiltInTwo(char* command, char* arg1, char* arg2);
int runNonBuiltInThree(char* command, char* arg1, char* arg2, char* arg3);
int runNonBuiltInNone(char* command);

Node* head = NULL;
int aliasSize = 0;
%}

%union {char *string;}

%start cmd_line
%token <string> STRING SETENV PRINTENV UNSETENV CD ALIAS UNALIAS BYE END LS PWD WC SORT PAGE CAT
%token <string> CP MV PING PIPE DATE SSH RM echoo TOUCH GREP ENV GT LT GTGT ERROR1 BASH

%%
cmd_line    :
	BYE END									{exit(1); return 1; }
	| SETENV STRING STRING END				{runSetEnv($2, $3); return 1;}
	| PRINTENV END							{runPrintEnv(); return 1;}
	| UNSETENV STRING END					{runUnsetEnv($2); return 1;}
	| CD END								{runCDnoargs(); return 1;}
	| CD STRING END							{runCD($2); return 1;}
	| ALIAS STRING STRING END				{runSetAlias($2, $3); return 1;}
	| ALIAS	END								{runListAlias(); return 1;}
	| UNALIAS STRING END					{runRemoveAlias($2); return 1;}
	| STRING STRING PIPE STRING STRING END 	{runPipe($1, $2, $4, $5); return 1;}
	| STRING STRING END							{runNonBuiltin($1, $2); return 1;}
	| STRING STRING STRING END			{runNonBuiltInTwo($1, $2, $3); return 1;}
	| STRING STRING STRING STRING END			{runNonBuiltInThree($1, $2, $3, $4); return 1;}
	| STRING END										{runNonBuiltInNone($1); return 1;}

%%
int yyerror(char *s)
{
  printf("%s\n",s);
  return 0;
}


int runSetEnv(char* variable, char* word)
{
	if(strcmp(variable, "PWD") == 0)
	{
		strcpy(varTable.word[0], word);
		return 1;
	}
		
	else if(strcmp(variable, "HOME") == 0)
	{
		strcpy(varTable.word[1], word);
		return 1;
	}
		
	else if(strcmp(variable, "PROMPT") == 0)
	{
		strcpy(varTable.word[2], word);
		return 1;
	}
		
	else if(strcmp(variable, "PATH") == 0)
	{
		strcpy(varTable.word[3], word);
		return 1;
	}
		
	setenv(variable, word, 1);
	var_count++;
	return 1;

}

int runPrintEnv()
{
	for(int i = 0; i < varIndex; i++) 
	{
		printf("%s=", varTable.var[i]);
		printf("%s\n", varTable.word[i]);
	}
	
	int count = 0;
	int i = 0;
	while(environ[i])
	{
		count++;
		i++;
	}
	
	i = count - var_count;
	while(environ[i]) 
	{
	  printf("%s\n", environ[i++]);
	}
	
    return 1;
}

int runUnsetEnv(char *variable)
{
	if(strcmp(variable, "PWD") == 0 || strcmp(variable, "HOME") == 0 || strcmp(variable, "PROMPT") == 0 || strcmp(variable, "PATH") == 0)
	{
		fprintf(stderr, "Error: Cannot unset %s\n", variable);
		return 0;
	}
		
	unsetenv(variable);
	var_count--;
	return 1;
}

int runCDnoargs(void)
{
	int result = chdir(getenv("HOME"));
	if(result != 0)
	{
		printf("No such directory");
	}
	return 1;
}

int runCD(char* arg)
{
	if (arg[0] != '/')
	{ // arg is relative path
		strcat(varTable.word[0], "/");
		strcat(varTable.word[0], arg);

		if(chdir(varTable.word[0]) == 0) {
			return 1;
		}
		else {
			getcwd(cwd, sizeof(cwd));
			strcpy(varTable.word[0], cwd);
			printf("Directory not found\n");
			return 1;
		}
	}
	else { // arg is absolute path
		if(chdir(arg) == 0){
			strcpy(varTable.word[0], arg);
			return 1;
		}
		else {
			printf("Directory not found\n");
                        return 1;
		}
	}
}

int runSetAlias(char *name, char *word) 
{
	if(strcmp(name, word) == 0)
	{
		printf("Error, expansion of \"%s\" would create a loop.\n", name);
		return 1;
	}

	Node* current = head;
	for(int i = 0; i < aliasSize; i++)
	{
		if((strcmp(current -> name, word) == 0 && strcmp(current -> word, name) == 0) || strcmp(current -> name, name) == 0)
		{
			printf("Error, expansion of \"%s\" would create a loop.\n", name);
			return 1;
		}
		current = current -> next;
	}

	if(aliasSize == 0) //if there are no aliases in the list
	{
		//create list with root pointing at beginning of list
		struct Node* root = (struct Node*)malloc(sizeof(struct Node));
		root -> name = name;
		root -> word = word;
		root -> next = NULL;
		head = root;
		//map.insert<name, word>;
	}

	else //else if there exists an alias already
	{
		//copy contents of word string to newWord string
		char* newWord = (char*)malloc((strlen(word)+1)*sizeof(char));
		strcpy(newWord, word);

		//create new node in list
		Node* node = head;
		while(node != NULL) //while not at end of list
		{
			if(node -> name == newWord) //check if word exists as an alias of a different word
			{
				newWord = node -> word; //prevents infinite-loop alias expansion
				break;
			}
			node = node -> next;
		}

		Node* current = head;

		if(current -> name == name)
		{
			current -> word = newWord;
			return 1;
		}

		while(current -> next != NULL)
		{
			if(current -> name == name)
			{
				current -> word = newWord;
				return 1;
			}
			current = current -> next;
		}

		struct Node* newNode = (struct Node*)malloc(sizeof(struct Node));
		newNode -> name = name;
		newNode -> word = newWord;
		newNode -> next = NULL;
		current -> next = newNode;
	}
	aliasSize += 1; //adjust size of alias list
	return 1;
}

int runListAlias(void) {
	if(aliasSize == 0)
	{
		fprintf(stderr, "Error: No existing aliases\n");
	}

	Node* current = head;

	for(int i = 0; i < aliasSize; i++)
	{
		//for(auto const& it: aliases)
		//{
		printf("%s=%s\n", current -> name, current -> word);
		//}
		current = current -> next;
	}
	return 1;
}

int runRemoveAlias(char *name)
{
	if(aliasSize == 0) //if no aliases exist
	{
		fprintf(stderr, "Error: Alias %s not found\n", name);
		return 0;
	}

	Node* current = head;

	if(strcmp(current -> name, name) == 0) //if alias with name found
	{
		if(current -> next != NULL)
		{
			head = current -> next;
		}

		else
		{
			head =	NULL;
		}

		free(current); //delete node
		aliasSize -= 1; //adjust size of alias list
	}

	else if(current -> next == NULL)
	{
		fprintf(stderr, "Error: Alias %s not found\n", name);
		return 0;
	}

	else
	{
		while(current -> next != NULL)
		{
			if(strcmp(current -> next -> name, name) == 0)
			{
				Node* del = current -> next;
				current -> next = del -> next;
				free(del);
				aliasSize -= 1;
				return 1;
			}
			current = current -> next;
		}
		fprintf(stderr, "Error: Alias %s not found\n", name);
		return 0;
	}
	return 1;

}

int runPipe(char* firstCom, char* firstArg, char* secondCom, char* secondArg)
{
	char* target1 = getPath(firstCom);
	char* target2 = getPath(secondCom);

	pid_t pid;
	int fd[2];

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
		dup2(fd[1], STDOUT_FILENO);
		close(fd[0]);
		close(fd[1]);
		execl(target1, firstCom, firstArg, (char*) NULL);
		fprintf(stderr, "Failed to execute %s\n", firstCom);
		exit(1);
	}
	else
	{
		pid = fork();

		if(pid == 0)
		{
				dup2(fd[0], STDIN_FILENO);
				close(fd[1]);
				close(fd[0]);
				execl(target2, secondCom, secondArg,(char*) NULL);
				fprintf(stderr, "Failed to execute %s\n", secondCom);
				exit(1);
		}
		else
		{
				int status;
				close(fd[0]);
				close(fd[1]);
				waitpid(pid, &status, 0);
		}
	}
}

int runNonBuiltin(char* command, char* arg)
{
	char* target = getPath(command);

	pid_t pid;
	int fd[1];

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
			execl(target, command, arg, NULL);
			perror("error");
			exit(1);
	}

	else
	{
			int status;
			close(fd[0]);
			close(fd[1]);
			waitpid(pid, &status, 0);
	}
	return 1;
}

int runNonBuiltInTwo(char* command, char* arg1, char* arg2)
{
	char* target = getPath(command);

	pid_t pid;
	int fd[1];
	char* args[50] = {arg1, arg2};

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
			execv(target, args);
			perror("error");
			exit(1);
	}

	else
	{
			int status;
			close(fd[0]);
			close(fd[1]);
			waitpid(pid, &status, 0);
	}
	return 1;
}

int runNonBuiltInNone(char* command)
{
	char* target = getPath(command);

	pid_t pid;
	int fd[1];

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
			execl(target, command, NULL);
			perror("error");
			exit(1);
	}

	else
	{
			int status;
			close(fd[0]);
			close(fd[1]);
			waitpid(pid, &status, 0);
	}
	return 1;
}

int runNonBuiltInThree(char* command, char* arg1, char* arg2, char* arg3)
{
	char* target = getPath(command);

	pid_t pid;
	int fd[1];
	char* args[50] = {arg1, arg2, arg3};

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
			execv(target, args);
			perror("error");
			exit(1);
	}

	else
	{
			int status;
			close(fd[0]);
			close(fd[1]);
			waitpid(pid, &status, 0);
	}
	return 1;
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
		return "/bin/touch";
	else if(strcmp(command, "pwd") == 0)
		return "/bin/pwd";
	else if(strcmp(command, "man") == 0)
		return "usr/bin/man";
}

int contains(char* string, char character)
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
