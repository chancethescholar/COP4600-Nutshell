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
int getcwd();

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
int runMV(char* filepath, char* destination);

Node* head = NULL;
int aliasSize = 0;
%}

%union {char *string;}

%start cmd_line
%token <string> STRING SETENV PRINTENV UNSETENV CD ALIAS UNALIAS BYE END LS PWD WC SORT PAGE CAT CP MV PING

%%
cmd_line    :
	BYE END						{exit(1); return 1; }
	| SETENV STRING STRING END	{runSetEnv($2, $3); return 1;}
	| PRINTENV					{runPrintEnv(); return 1;}
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
	| PING END 					{return 1;}
	//| ECHO END 				{return 1;}

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

    for (int i = 0; i < aliasIndex; i++)
    {
        if((strcmp(aliasTable.name[i], name) == 0) && (strcmp(aliasTable.word[i], word) == 0)){
            printf("Error, expansion of \"%s\" would create a loop.\n", name);
            return 1;
        }
        else if(strcmp(aliasTable.name[i], name) == 0) {
            strcpy(aliasTable.word[i], word);
            return 1;
        }
    }
    strcpy(aliasTable.name[aliasIndex], name);
    strcpy(aliasTable.word[aliasIndex], word);
    aliasIndex++;
	
	if(strcmp(name, word) == 0)
	{
		printf("Error, expansion of \"%s\" would create a loop.\n", name);
		return 1;
	}

	if(aliasSize == 0) //if there are no aliases in the list
	{
		//create list with root pointing at beginning of list
		struct Node* root = (struct Node*)malloc(sizeof(struct Node));
		root -> name = name;
		root -> word = word;
		root -> next = NULL;
		head = root;
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
		printf("%s %s\n", current -> name, current -> word);
		//}
		current = current -> next;
	}
	return 1;
}

int runRemoveAlias(char *name)
{
	//printf("%s\n", name);
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
		printf("Error: Alias %s not found\n", name);
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
	DIR* dir;
	dir = opendir(directory);
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

int runMV(char* filepath, char* destination)
{
	/*bool directory;
	for(int i = 0; i < filepath.size(); i++)
	{
		if(filepath(i) == '/')
			directory = true;
	}
	if(directory == false)
	{*/
	return 1;
		
}
