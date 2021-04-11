#include "stdbool.h"
#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <limits.h>

struct evTable {
   char var[128][100];
   char word[128][100];
};

struct aTable {
        char name[128][100];
        char word[128][100];
};

char cwd[PATH_MAX];

struct evTable varTable;

struct aTable aliasTable;

int aliasIndex, varIndex;

char* subAliases(char* name);

typedef struct Node
{
	char* name;
	char* word;

	struct Node* next;
} Node;

Node* head;
int aliasSize; //size of alias list
int argc;
