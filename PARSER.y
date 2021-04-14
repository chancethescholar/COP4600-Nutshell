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
int runLS(void);
int runLSDIR(char* directory);
int runCAT(char* file);
int runWC(char* file);
int runMV(char* source, char* destination);
int runPipe(char* firstCom, char* firstArg, char* secondCom, char* secondArg);
int getDateTime();
int runSSH(char* address);
int runRemove(char* arg);
int runPWD(void);
int runEcho(char* arg);
int runCP(char* s, char* d);
int runTOUCH(char* arg);
int runGrep(char* arg, char* filename);


Node* head = NULL;
int aliasSize = 0;
%}

%union {char *string;}

%start cmd_line
%token <string> STRING SETENV PRINTENV UNSETENV CD ALIAS UNALIAS BYE END LS PWD
%token <string> WC SORT PAGE CAT CP MV PING PIPE DATE SSH RM echoo TOUCH GREP ENV

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
	| LS END								{runLS(); return 1;}
	| LS STRING END							{runLSDIR($2); return 1;}
	| PWD END 								{runPWD(); return 1;}
	| WC STRING END 						{runWC($2); return 1;}
	| SORT END 								{return 1;}
	| PAGE END 								{return 1;}
	| CAT STRING END 						{runCAT($2); return 1;}
	| CP STRING STRING END 					{runCP($2,$3); return 1;}
	| MV STRING STRING END 					{runMV($2,$3); return 1;}
	| PING END								{printf("ping: usage error: Destination address required\n"); return 1;}
	| STRING STRING PIPE STRING STRING END 	{runPipe($1, $2, $4, $5); return 1;}
	| DATE END								{getDateTime(); return 1;}
	| SSH STRING END						{runSSH($2); return 1;}
	| RM STRING END							{runRemove($2); return 1;}
	| echoo STRING END						{runEcho($2); return 1;}
	| TOUCH STRING END						{runTOUCH($2); return 1;}
	| GREP STRING STRING END				{runGrep($2, $3); return 1;}
	| ENV STRING END						{printf("hello"); return 1; }

%%
int runGrep(char* arg, char* filename)
{
	pid_t pid;
	int fd[2];

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
		execl("/bin/grep","grep", arg, filename, NULL);
		perror("grep error");
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
int runTOUCH(char* arg)
{
	pid_t pid;
	int fd[2];

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
		execl("/bin/touch","touch", arg, NULL);
		perror("touch error");
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
int runCP(char* s, char* d)
{
	pid_t pid;
	int fd[2];

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
		execl("/bin/cp","cp", s, d, NULL);
		perror("cp error");
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

int runEcho(char* arg)
{
	pid_t pid;
	int fd[2];

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
		execl("/bin/echo", "/bin/echo", arg, NULL);
		perror("echo error");
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

int runPWD(void)
{
	pid_t pid;
	int fd[2];

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
		execl("/bin/pwd", "/bin/pwd", NULL, NULL);
		perror("pwd error");
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

int runLS(void)
{
	DIR* dir;
  dir = opendir(".");
  struct dirent* dp;
  if(dir)
  {
  	while((dp = readdir(dir)) != NULL)
    {
    	printf("%s\t", dp -> d_name);
    }
		printf("\n");
    closedir(dir);
  }
  else
  	printf("The directory cannot be found");
	return 1;
}

int runLSDIR(char* directory)
{
	pid_t pid;
	int fd[1];

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
		execl("/bin/ls", "ls", directory, NULL);
		perror("ls error");
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

int runCAT(char* file)
{
	pid_t pid;
	int fd[2];

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
		execl("/bin/cat", "cat", file, NULL);
		perror("cat error");
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

int runWC(char* file)
{
	char ch;
	int char_count = 0, word_count = 0, line_count = 0;
	int in_word = 0;
	int bytes;

	FILE *fp;
	fp = fopen(file, "r");

	if(fp == NULL)
	{
		printf("Could not open the file %s\n", file);
		return 1;
	}

	while ((ch = fgetc(fp)) != EOF)
	{
		char_count++;

		if(ch == ' ' || ch == '\t' || ch == '\0' || ch == '\n')
		{
			if (in_word)
			{
				in_word = 0;
				word_count++;
			}

			if(ch = '\0' || ch == '\n') line_count++;

		}
		else
		{
			in_word = 1;
		}
	}
	fclose(fp);
	fp = fopen(file, "r");
	for(bytes = 0; getc(fp) != EOF; ++bytes);
	printf("%d %d %d %s\n",line_count,word_count,bytes,file);

	return 1;
}

int runMV(char* source, char* destination)
{
	pid_t pid;
	int fd[2];

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
		execl("/bin/mv","mv", source, destination, NULL);
		perror("mv error");
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

int runPipe(char* firstCom, char* firstArg, char* secondCom, char* secondArg)
{
	pid_t pid;
	int fd[2];

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
		dup2(fd[1], STDOUT_FILENO);
		close(fd[0]);
		close(fd[1]);
		execlp(firstCom, firstCom, firstArg, (char*) NULL);
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
				execl(secondCom, secondCom, secondArg,(char*) NULL);
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

int getDateTime()
{
	time_t T= time(NULL);
	struct  tm tm = *localtime(&T);
	printf("%02d/%02d/%04d %02d:%02d:%02d\n",tm.tm_mday, tm.tm_mon+1, tm.tm_year+1900,tm.tm_hour, tm.tm_min, tm.tm_sec);
	return 1;
}

int runSSH(char* address)
{
	pid_t pid;
	int fd[1];

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
		execl("ssh", "ssh", address, NULL);
		printf("ssh: connect to host %s\n", address);
		perror("Connection refused");
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

int runRemove(char* arg)
{
	pid_t pid;
	int fd[2];

	pipe(fd);
	pid = fork();

	if(pid == 0)
	{
		execl("/bin/rm", "/bin/rm", arg, NULL);
		perror("rm error");
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
