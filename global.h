#ifndef GLOBAL_H
#define GLOBAL_H

#include<stdio.h>
#include<stdlib.h>
#include<unistd.h>
#include<sys/types.h>
#include<sys/wait.h>
#include<sys/signal.h>
#include<fcntl.h>
#include<regex.h>
#include<pwd.h>
#include<glob.h>
#include<string.h>
#include<signal.h>

extern int yylineno;
extern char** environ;

typedef struct Node
{
	char* name;
	char* word;

	struct Node* next;
} Node;

Node* head = NULL;
int aliasSize = 0; //size of alias list
//std::map<char*, char*> aliases;

char* infileName = NULL;  //in file description
char* outfileName = NULL;	//out file description
char* errFileName = NULL; //error file  description
int openPermission = 0; //open option
int background = 0;

typedef struct command
{
	char* comName; //command name
	int numArgs; //number of arguments

	char* args[500]; //inital argment string arrary

} COMMAND;

COMMAND commands[500]; //initial command table

int currentCom = 0; //current commad index

void yyerror(const char * s);
int yylex();
int yyparse();
void aliasPrint();
void alias(char*, char*);
void unalias(char*);
char* searchAlias(char*);
void printenv();
void execute(); //to execute commands
void prompt();
void setSignal();
int contain_char(char*, char);

#endif
