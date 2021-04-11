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
int runPrintEnv(void);
int runUnsetEnv(char *variable);
int runCD(char* arg);
int runSetAlias(char *name, char *word);
int runListAlias(void);
int runRemoveAlias(char *name);
int runLS(void);
int runLSDIR(char* directory);
int runCAT(char* file);
int runWC(char* file);
int runMV(char* source, char* destination);
int runEcho(char* string);
int runPing(char* address);
int runPipe(char* firstCom, char* firstArg, char* secondCom, char* secondArg);
int getDateTime();
int runSSH(char* address);
int runRemove(char* arg);

Node* head = NULL;
int aliasSize = 0;
%}

%union {char *string;}

%start cmd_line
%token <string> STRING SETENV PRINTENV UNSETENV CD ALIAS UNALIAS BYE END LS PWD
%token WC SORT PAGE CAT CP MV PING PIPE ECHO DATE SSH RM

%%
cmd_line    :
	BYE END						{exit(1); return 1; }
	| SETENV STRING STRING END	{runSetEnv($2, $3); return 1;}
	| PRINTENV END					{runPrintEnv(); return 1;}
	| UNSETENV STRING END		{runUnsetEnv($2); return 1;}
	| CD STRING END				{runCD($2); return 1;}
	| ALIAS STRING STRING END	{runSetAlias($2, $3); return 1;}
	| ALIAS	END					{runListAlias(); return 1;}
	| UNALIAS STRING END		{runRemoveAlias($2); return 1;}
	| LS END					{runLS(); return 1;}
	| LS STRING END				{runLSDIR($2); return 1;}
	| PWD END 					{printf("%s\n", varTable.word[0]); return 1;}
	| WC STRING END 			{runWC($2); return 1;}
	| SORT END 					{return 1;}
	| PAGE END 					{return 1;}
	| CAT STRING END 			{runCAT($2); return 1;}
	| CP END 					{return 1;}
	| MV STRING STRING END 		{runMV($2,$3); return 1;}
	| PING END							{printf("ping: usage error: Destination address required\n"); return 1;}
	| STRING STRING PIPE STRING STRING END 					{runPipe($1, $2, $4, $5); return 1;}
	//| ECHO STRING END 				{runEcho($2); return 1;}
	| DATE END										{getDateTime(); return 1;}
	| SSH STRING END							{runSSH($2); return 1;}
	| RM STRING END								{runRemove($2); return 1;}

%%

int yyerror(char *s)
{
  printf("%s\n",s);
  return 0;
}


int runSetEnv(char* variable, char* word)
{
	if(strcmp(variable, word) == 0)
	{
		printf("Error, expansion of \"%s\" would create a loop.\n", variable);
		return 1;
	}

	for (int i = 0; i < varIndex; i++)
	{
		if((strcmp(varTable.var[i], variable) == 0) && (strcmp(varTable.word[i], word) == 0)){
			printf("Error, expansion of \"%s\" would create a loop.\n", variable);
			return 1;
		}
		else if(strcmp(varTable.var[i], variable) == 0) {
			strcpy(varTable.word[i], word);
			return 1;
		}
	}
	strcpy(varTable.var[varIndex], variable);
	strcpy(varTable.word[varIndex], word);
	varIndex++;

	return 1;

}

int runPrintEnv(void)
{
	for(int i = 0; i < varIndex; i++) {
		printf("%s=", varTable.var[i]);
		printf("%s\n", varTable.word[i]);
	}
	return 1;
}

int runUnsetEnv(char *variable)
{
	char reset[100];
	for(int i = 0; i < varIndex; i++)
	{
		if(strcmp(varTable.var[i], variable ) == 0)
		{
			strcpy(varTable.var[i], reset);
			strcpy(varTable.word[i], reset);
			varIndex--;
			return 1;
		}
	}
	printf("Error, %s not found.\n", variable);
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

int runSetAlias(char *name, char *word) {
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
		printf("Error: No alias %s found\n", name);
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
                        printf("%s\n", dp -> d_name);
              	}
                closedir(dir);
        }
        else
                printf("not valid");
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
	FILE *fp;
	fp = fopen(file, "r");
	char line[256];

    while (fgets(line, sizeof(line), fp)) {
        printf("%s", line);
    }
    fclose(fp);
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
	bool src_isFile = false;
	bool destn_isFile = false;

	DIR* src_directory = opendir(source);
	DIR* destn_directory = opendir(destination);

	if(src_directory == NULL)
		src_isFile = true;

	if(destn_directory == NULL)
		destn_isFile = true;

	if(src_isFile == true && destn_isFile == true)
	{
		FILE *fp1;
		FILE *fp2;
		fp1 = fopen(source, "r");
		fp2 = fopen(destination, "w");
		char ch;

		while ((ch = fgetc(fp1)) != EOF)
		{
			fputc(ch, fp2);
		}
		fclose(fp1);
		fclose(fp2);
		remove(source);
	}
	else if(src_isFile == true && destn_isFile == false)
	{
		char* slash = "/";

		FILE *fp1;
		FILE *fp2;

		strcat(destination, slash);
		strcat(destination, source);

		fp1 = fopen(source, "r");
		fp2 = fopen(destination, "w");
		char ch;

		while ((ch = fgetc(fp1)) != EOF)
		{
			fputc(ch, fp2);
		}
		fclose(fp1);
		fclose(fp2);
		remove(source);
	}
	/*else if(src_isFile == false && destn_isFile == false)
	{
		char *substr;
		int index = 0;
		int count = 0;
		for(int i = 0; i < strlen(source); i++)
		{
			if(source[i] == '/')
			{
				index = i;
				count = 0;
			}
			count++;
		}
		strnpy(substr, source[index + 1], count];
		printf("%s", substr);
		/*FILE *fp1;
		FILE *fp2;

		fp1 = fopen(source, "r");
		fp2 = fopen(destination, "w");
		char ch;

		while ((ch = fgetc(fp1)) != EOF)
		{
			fputc(ch, fp2);
		}
		fclose(fp1);
		fclose(fp2);
		remove(source);

	}*/
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

int runEcho(char* string)
{
	printf("%s\n", string);
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
	int fd[1];

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
}
