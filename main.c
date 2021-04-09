#include<stdio.h>
#include<string.h>
#include "global.h"

int main()
{
	printf("Welcome to the Nutshell!\n");
	while(1)
	{
			printf("nutshell> ");
			fflush(stdout);//clear output buffer

		if(yyparse())
		{
			return(1);
		}
	}
	return 0;
}

//alias name word- adds a new alias to the shell
void alias(char* name, char* word)
{
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
	aliasSize += 1; //adjust size of alias list
}

//alias- the alias command with no arguments lists all of the current aliases
void aliasPrint()
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
	if(aliasSize == 0) //if no aliases exist
	{
		printf(stderr, "Error: No alias %s found\n", name);
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
				return;
			}
			current = current -> next;
		}
		fprintf(stderr, "Error: Alias %s not found\n", name);
	}
}

//search alias list
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

	//use piping to handle commands

	//create pipe end points
	int input_fd;
	int i;
	int out_fd;

	//dup creates a copy of a file descriptor
	int origin_in = dup(0); //orgin_in is copy of stdin
	int origin_out = dup(1); //origin_out is copy of stdout
	int origin_error = dup(2); //origin_error is copy of stderr

	if(infileName)
	{
		input_fd = open(infileName, O_RDONLY); //open file in read only mode
	}

	else
	{
		//if there is no file use default input
		input_fd = dup(origin_in);
	}

	pid_t child;
	for(i = 0; i < numCommands; i++)
	{
		//loop from first command to last
		dup2(input_fd, 0); //redirect input to stdin
		close(input_fd); //close input_fd

		if (i == numCommands - 1)
		{
			//this is last commmand
			if(outfileName)
			{
				//open file
				mode_t open_mode = S_IRUSR | S_IROTH| S_IWUSR | S_IRGRP ; //I/O
				out_fd = open(outfileName, openPermission, open_mode);
			}

			else
			{
				out_fd = dup(origin_out);// use original output
			}

		}

		else //if not last command
		{
			int pipe_fd[2];
			pipe(pipe_fd);
			out_fd = pipe_fd[1];
			input_fd = pipe_fd[0];
		}

		//he difference between dup and dup2 is that dup assigns the lowest
		//available file descriptor number, while dup2 lets you choose the file
		//descriptor number that will be assigned and atomically closes and replaces
		//it if it's already taken.
		dup2(out_fd, 1);  //redirect output

		if(errFileName)
		{
			//The construct 2>file​ redirects the standard error of the program to ​file​,
			//while ​2>&1​ connects the standard error ofthe program to its standard output.
			if((out_fd = open(errFileName, O_CREAT|O_TRUNC|O_WRONLY, 0777))!= -1)//2>
			{
				dup2(out_fd, 2);
			}
			else
			dup2(STDOUT_FILENO, STDERR_FILENO); //2>&1
		}

		close(out_fd); //close out fd

		//check for commands
		if(strcmp(commands[i].comName, searchAlias(commands[i].comName))!= 0)
		{
			//search aliases for a command
			//Ex: if alias exits for list, ls
			//input of "list" in command line would cause ls command to run
			char* token;
			char* temp;
			temp = (char*)malloc((strlen(searchAlias(commands[i].comName))+1)*sizeof(char));
			strcpy(temp, searchAlias(commands[i].comName));
			//temp= tildeExpansion(temp); //works with tildeExpansion

			//using " " as delimeter
			token = strtok(temp, " "); //split string (temp) into tokens, which are sequences of
			//contiguous characters separated by any of the characters that are part
			//of delimiters

			//walk through other tokens

			//tokens used to handle commands in quotations
			commands[i].numArgs = 0;
			while(token != NULL)
			{
				commands[i].args[commands[i].numArgs] = token;
				commands[i].numArgs++;
				token = strtok(NULL, " ");
			}
			commands[i].comName = commands[i].args[0];
		}


		if(strcmp(commands[i].comName, "bye") == 0)
			exit(0); //exits program

		else if(strcmp(commands[i].comName, "cd") == 0)
		{
			int res;
			if(commands[i].numArgs >= 1 )
				res = chdir(commands[i].args[1]); //chdir changes the directory to specified path

			else
				res = chdir(getenv("HOME"));//change directory (chdir) to HOME otherwise

			if (res != 0)
				fprintf(stderr, "Error: No such file or directory!\n");
			continue;
		}

		//setenv variable word​- sets the value of the variable ​variable​ to be ​word​
		else if(strcmp(commands[i].comName, "setenv") == 0)
		{

		}

		//printenv​- prints out the values of all the environment variables, in the
		//formatvariable=value​, one entry per line.
		else if(strcmp(commands[i].comName, "printenv") == 0)
		{

		}

		//unsetenv variable​ This command will remove the binding of ​variable​.
		//If the variable is unbound, the command is ignored.
		else if(strcmp(commands[i].comName, "unsetenv") == 0)
		{

		}

		else if (strcmp(commands[i].comName, "alias") == 0)
		{
			if(commands[i].args[1] != NULL && commands[i].args[2] != NULL && commands[i].args[3] == NULL)
			{
				//alias inputted with a name and word, add alias to list
				alias(commands[i].args[1], commands[i].args[2]);
			}

			else if(commands[i].args[1] == NULL) //just alias is inputted, print all aliases
			{
				aliasPrint();
			}

			else
			{
				fprintf(stderr, "Error: Invalid command!\n");
			}
			continue;
		}

		else if(strcmp(commands[i].comName, "unalias") == 0)
		{
			if(commands[i].args[1] != NULL && commands[i].args[2] == NULL)
			{
				//unalias is inputted with name that wants to be unaliased
				unalias(commands[i].args[1]);
			}

			else
			{
				fprintf(stderr, "Error at line %d: Invalid command!\n",yylineno);
			}
			continue;
		}

		else
		{
			//if command is not any of the built in commands, we sort the arguments and fork
			child = fork();
		}

		if(child == 0)
		{
			//child process
			execv(commands[i].comName,commands[i].args);//execute non built in commands

			perror("execv");//print error
			_exit(1);
		}

		else if(child < 0)
		{
			//not child process, fork failed
			//fprintf(stderr, "child fork fail \n");
			fprintf(stderr, "Error at line %d: child fork fail!\n",yylineno);
			_exit(1); //abort child process
		}

		if(!background) //if process not running in background
		{
			waitpid(child, NULL, 0);//check status of process, waits for child to terminate
		}
	}

	//loop through simple commands
	dup2(origin_in, 0);
	dup2(origin_out, 1);
	dup2(origin_error, 2);
	close(origin_in);
	close(origin_out);
	close(origin_error);

	//clear command table
	int x;
	int y;
	for(x = 0; x < numCommands; x++)
	{
		for(y = 0; y < 500; y++)
		{
			commands[x].args[y] = NULL;
		}
		commands[x].comName = NULL;
		commands[x].numArgs = 0;
	}

	currentCom = 0;
	infileName = NULL;
	outfileName = NULL;
	errFileName = NULL;
	openPermission = 0;

	fflush(stdout);  //flush stream
}

int contain_char(char* string, char character)
{
	for(int i = 0; i != strlen(string); i++)
	{
		if (string[i] == character)
		{
			return 1;
		}
	}
	return 0;
}
