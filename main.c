#include<stdio.h>
#include<string.h>
#include "global.h"

int main(){
	// Ignore signal (SIG_IGN): The signal is ignored and the code execution will
	//continue even if not meaningful.
	// SIGINT Interrupt from keyboard
	signal(SIGINT, SIG_IGN);
	signal(SIGINT, setSignal);
	while(&free)
	{
		if (isatty(fileno(stdin)))
		{
			printf("nutshell> ");
			fflush(stdout);  //flush a stream
		}

		if(yyparse()){
			return(1);

		}

		else
		{
			return(0);
		}
	}
	return 0;
}

//alias name word- adds a new alias to the shell
void alias(char* name, char* word)
{
	if(aliasSize == 0)
	{
		struct Node* root = (struct Node*)malloc(sizeof(struct Node));
		root -> name = name;
		root -> word = word;
		root -> next = NULL;
		head = root;
		//map.insert<name, word>;
	}

	else
	{
		char* newWord = NULL;
		newWord = (char*)malloc((strlen(word)+1)*sizeof(char));
		strcpy(newWord, word);

		Node* node = head;
		while(node != NULL)
		{
			if(node -> name == newWord)
			{
				newWord = node -> word;
				break;
			}
			node = node -> next;
		}

		Node* current = head;

		if(current -> name == name)
		{
			current -> word = newWord;
			return;
		}

		while(current -> next != NULL)
		{
			if(current -> name == name)
			{
				current -> word = newWord;
				return;
			}
			current = current -> next;
		}

		struct Node* newNode = (struct Node*)malloc(sizeof(struct Node));
		newNode -> name = name;
		newNode -> word = newWord;
		newNode -> next = NULL;
		current -> next = newNode;
	}
	aliasSize += 1;
}

//alias- the alias command with no arguments lists all of the current aliases
void alias_print()
{
	if(aliasSize == 0)
	{
		fprintf(stderr, "Error: No existing aliases\n");
	}

	Node* current = head;

	for(int i = 0; i < aliasSize; i++)
	{
		//for(auto const& it: aliases)
		//{
		printf("%s: %s\n", current -> name, current -> word);
		//}
		current = current -> next;
	}
}

//unalias name- remove the alias for name from the alias list.
void unalias(char* name)
{
	if(aliasSize == 0)
	{
		printf(stderr, "Error: No alias %s found\n", name);
	}

	Node *current = head;

	if(strcmp(current -> name, name) == 0)
	{
		if(current -> next != NULL)
		{
			head = current -> next;
		}

		else
		{
			head =	NULL;
		}

		free(current);
		aliasSize -= 1;
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
				return;
			}
			current = current -> next;
		}
		fprintf(stderr, "Error: Alias %s not found\n", name);
	}
}

//search alias
char* searchAlias(char* name)
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

void printenv()
{

}

void execute()
{
	int numCommands = 0;
	while(commands[numCommands].comName != NULL)
	{
		numCommands++;
	}

	int input_fd;// initial input fd
	int i;
	int out_fd;

	int origin_in = dup(0);
	int origin_out = dup(1);
	int origin_error = dup(2);
	//save original in out error

	if (infileName) { 	// open file
		input_fd = open(infileName, O_RDONLY); // read only
	} else { 			// if there is not file use default input
		input_fd = dup(origin_in);
	}

	pid_t child;
	for ( i = 0; i < numCommands; i++ ) { // loop from first command to last

		dup2(input_fd, 0);//redirect input to stdin
		close(input_fd);//close input_fd

		if (i == numCommands - 1) { //this is last commmand

			if (outfileName) { //open file

				mode_t open_mode = S_IRUSR | S_IROTH| S_IWUSR | S_IRGRP ; //io
				out_fd = open(outfileName, openPermission, open_mode);
			}

			else {
				out_fd = dup(origin_out);// use original output
			}

		}

		// this is not last command, so inital pipeline
		else {
			int pipe_fd[2];
			pipe(pipe_fd);
			out_fd = pipe_fd[1];
			input_fd = pipe_fd[0];
		}

		dup2(out_fd, 1);  // redirect output

		if (errFileName) {

			// 0777 permissions rwxrwxrwx
			if((out_fd = open(errFileName, O_CREAT|O_TRUNC|O_WRONLY, 0777))!= -1)//this is  2>
			{
				dup2( out_fd, 2);
			}
			else
			dup2( STDOUT_FILENO, STDERR_FILENO); //this is 2>&1
		}

		close(out_fd); //close out fd

		//check for commands

		if(strcmp(commands[i].comName,searchAlias(commands[i].comName))!= 0)
		{
			char* token;
			char* temp;
			temp = (char *)malloc((strlen(searchAlias(commands[i].comName))+1)*sizeof(char));
			strcpy(temp,searchAlias(commands[i].comName));
			temp = tildeExpansion(temp);

			token = strtok(temp, " ");

			//walk through other tokens
			commands[i].numArgs = 0;
			while(token != NULL)
			{
				commands[i].args[commands[i].numArgs] = token;
				commands[i].numArgs++;
				token = strtok(NULL, " ");
			}
			commands[i].comName = commands[i].args[0];
		}


		if(strcmp(commands[i].comName, "bye")==0)
			exit(0);

		else if(strcmp(commands[i].comName, "cd")==0)
		{
			int ret;
			if(commands[i].numArgs >= 1 )
				ret = chdir(commands[i].args[1] );

			else
				ret = chdir( getenv("HOME") );

			if (ret != 0)
				fprintf(stderr, "Error: No such file or directory!\n");

			continue;
		}

		else if(strcmp(commands[i].comName, "setenv") == 0)
		{

		}

		else if(strcmp(commands[i].comName, "printenv") == 0)
		{

		}

		else if(strcmp(commands[i].comName, "unsetenv") == 0)
		{

		}

		else if (strcmp(commands[i].comName, "alias") == 0)
		{
			if (commands[i].args[1] != NULL && commands[i].args[2] != NULL && commands[i].args[3] == NULL)
			{
				alias(commands[i].args[1], commands[i].args[2]);
			}

			else if (commands[i].args[1] == NULL)
			{
				alias_print();
			}

			else
			{
				fprintf(stderr, "Error: Invalid command!\n");
			}
			continue;
		}

		else if (strcmp(commands[i].comName, "unalias") == 0)
		{
			if (commands[i].args[1]!=NULL && commands[i].args[2] == NULL)
			{
				unalias(commands[i].args[1]);
			}

			else
			{
				fprintf(stderr, "Error at line %d: Invalid command!\n",yylineno);
			}
			continue;
		}

		else
		{ // else we sort the arguments and fork!
			child = fork(); //after check build in now we can fork
		}

		if (child == 0) { //this is child
			execvp(commands[i].comName,commands[i].args);// execute non build in

			perror("execvp");
			_exit(1);
		}
		else if (child < 0) {
			//fprintf(stderr, "child fork fail \n");
			fprintf(stderr, "Error at line %d: child fork fail!\n",yylineno);
			_exit(1);
		}

		if (!background) {
			waitpid(child, NULL, 0);
		}
	}
	//loop all of those simple command

	dup2(origin_in, 0); //original in out error go to default
	dup2(origin_out, 1);
	dup2(origin_error, 2);
	close(origin_in);
	close(origin_out);
	close(origin_error);

	//clear command table to empty
	int z;
	int x;
	for (z = 0; z < numCommands; z++)
	{

		for(x = 0; x < 500; x++)
		{
			commands[z].args[x]=NULL;
		}
		commands[z].comName=NULL;
		commands[z].numArgs=0;

	}
	currcmd= 0;
	infileName=NULL;
	outfileName=NULL;
	errFileName=NULL;
	openPermission =0;
	background = 0;

	if (isatty(fileno(stdin)))
	{
		printf("nutshell> ");
		fflush(stdout);  //flush stream
	}
}

void escape(char* string)
{

}

char* environmentVariable(char* string)
{
	int length = strlen(string)+1;
	char* newString = (char *)malloc((length)*sizeof(char));

	char* value = (char *)malloc((length)*sizeof(char));

	int stringPtr =0;
	int i = 0;

	while(i!=length-1){
		if(string[i] == '$' && string[i+1] == '{'){
			char* variable = (char *)malloc((length)*sizeof(char));
			int variablePtr = 0;
			i = i +2;

			while (i <= length && string[i]!= '}'){
				variable[variablePtr] = string[i];
				variablePtr++;
				i++;
			}

			variable[variablePtr] = '\0';

			//search for variable value
			if(getenv(variable)!=NULL){
				value = getenv(variable);
			}else{
				strcat(value, "${");
				strcat(value, variable);
				strcat(value, "}");
			}

			int j;

			for (j = 0; j < strlen(value); ++j) {
				newString[stringPtr] = value[j];
				stringPtr++;
			}

			variablePtr = 0;

		}else{
			newString[stringPtr] = string[i];
			stringPtr++;
		}
		i++;
	}

	newString[stringPtr] = '\0';

	return newString;
}

char* tildeExpansion(char* string)
{

}

int contain_char(char* string, char character)
{
	int i = 0;
	while (i != strlen(string)){
		if (string[i] == character){
			return 1;
		}
		i++;
	}
	return 0;
}

char* combine_string(char* string1, char* string2)
{
	char* newString = (char *)malloc((strlen(string1)+strlen(string2)+1)*sizeof(char));
	strcpy(newString, string1);
	strcat(newString, string2);
	return newString;
}

void setSignal(){
	printf("\n");
	if (isatty(fileno(stdin)))
	{
		printf("nutshell> ");
		fflush(stdout);  //flush a stream
	}
	fflush(stdout);
}
