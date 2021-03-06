%{
#include <string.h>
#include "PARSER.tab.h"
#include "global.h"

int argc = 0;

char* envExpansion(char* arg)
{
    char sub[1000];

    int size = 0;
    while(arg[size] != '\0')
    {
        size++;
    }

    if(arg[0] == '\"')
    {
        int position = 3, temp = 0;
        while (temp < size - 5)
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
    }
    else
    {
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
    }
    return getenv(sub);
}
%}

%array
%option noyywrap
%x string_condition
%option yylineno

CHAR            [.A-Za-z0-9!\/_-][.A-Za-z0-9!\/_-]*
ANYCHAR         [:)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][:)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
PATH			[:)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~-][:)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~-]*

%%

<string_condition>{ANYCHAR}+    { yylval.string = strdup(yytext); return STRING;}
<string_condition>[\"]          { BEGIN(INITIAL);}
[$][{]{CHAR}+[}]				{ argc++; yylval.string = envExpansion(yytext); return STRING;}
["][$][{]{CHAR}+[}]["]          { argc++; yylval.string = envExpansion(yytext); return STRING;}


[ ]		{ }
[\"]                { BEGIN(string_condition); }
\n		{return END;}
"<"		{return LT;}
">"		{return GT;}
">>"	{return GTGT;}
">&"	{return GTAMP;}
">>&"	{return GTGTAMP;}
"|" 	{return PIPE;}
"2>"	{return ERRORF;}
"2>&1"	{return ERROR1;}
"&" 	{ return AMP;}
[\t]	{ }	//ignore tab
"EOF" {exit(0);}

{CHAR}+     		{
                  argc++;
									//printf("argCount: %d\n", argc);
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
      					  }

                  else
                  {
  									yylval.string = strdup(yytext);
  									//escape(yylval.string);
                    envExpansion(yylval.string);
  									return STRING;
                  }
    					  }

{PATH}+				{yylval.string = strdup(yytext); return STRING;}
%%
