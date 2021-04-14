%{
#include "PARSER.tab.h"
#include <string.h>
#include<stdio.h>
#include "global.h"

int yyparse();

int argc = 0; //keeps track of number of words in input

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

char* envExpansion(char* arg)
{ 
	char sub[1000];
	
	int size = 0;
	while(arg[size] != '\0')
	{
		size++;
	}

	int position = 2, temp = 0;
	while (temp < size - 3) 
	{
		sub[temp] = arg[position+temp];
		temp++;
	}
	sub[temp] = '\0';
	
	
	if(strcmp(sub, "PWD") == 0)
		return varTable.word[0];
		
	else if(strcmp(sub, "HOME") == 0)
		return varTable.word[1];
		
	else if(strcmp(sub, "PROMPT") == 0)
		return varTable.word[2];
		
	else if(strcmp(sub, "PATH") == 0)
		return varTable.word[3];
	
	return getenv(sub);
}

%}

%array
%option noyywrap
%x string_condition

CHAR            [.A-Za-z0-9!\/_-][.A-Za-z0-9!\/_-]*
ANYCHAR         [:)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][:)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
PATH			[:)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~-][:)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~-]*

%%

<string_condition>{ANYCHAR}+    { yylval.string = strdup(yytext); return STRING;}
<string_condition>[\"]          { BEGIN(INITIAL);}
[$][{]{CHAR}+[}]				{ argc++; yylval.string = envExpansion(yytext); return STRING;}

[ ]           { }
">"					{argc++; return GT;}
"<"					{argc++; return LT;}
">>"				{argc++; return GTGT;}
"2>&1"				{argc++; return ERROR1;}
"&"					{argc++; return BASH;}
echo				{ argc++; return echoo; }
setenv				{ argc++; return SETENV; }
printenv			{ argc++; return PRINTENV; }
unsetenv			{ argc++; return UNSETENV; }
cd		            { argc++; return CD; }
alias		        { argc++; return ALIAS; }
unalias				{ argc++; return UNALIAS; }
bye                 { argc++; return BYE; }
"\n"            	{ return END; }
[\"]                { BEGIN(string_condition); }
"|"             	{ return PIPE; }
{CHAR}+         	{
	                  argc++;
	                  if(ifAlias(yytext) && argc == 1)
	                  {
	                    //alias expansion
	                    while(ifAlias(yytext))
	                    {
	                      char* yycopy = strdup(subAliases(yytext));

	                      for(int i = strlen(yycopy) - 1; i >= 0; --i)
	                        unput(yycopy[i]);
	                      free(yycopy);

	                      strcpy(yytext, subAliases(strdup(yytext)));
	                    }
	                    argc++;
	                  }

	                  else
	                  {
	                    yylval.string = strdup(yytext);
	                    return STRING;
	                  }
	                }
%%
