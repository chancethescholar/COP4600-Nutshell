#include "stdbool.h"
#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <limits.h>
#include <pwd.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/signal.h>
#include <fcntl.h>
#include <regex.h>
#include <pwd.h>
#include <glob.h>
#include <string.h>
#include <signal.h>
#include <fnmatch.h>
#include <dirent.h>

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
extern char **environ;
int var_count;

char* getPath(char* command);
int contains(char* string, char character);
