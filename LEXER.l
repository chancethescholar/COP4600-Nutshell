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

%}

%array
%option noyywrap
%x string_condition

CHAR            [.A-Za-z0-9!\/_-][.A-Za-z0-9!\/_-]*
ANYCHAR            [)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*

%%

<string_condition>{ANYCHAR}+     { yylval.string = strdup(yytext); return STRING;}
<string_condition>[\"]          {BEGIN(INITIAL);}

[ ]           { }
setenv				{ argc++; return SETENV; }
printenv			{ argc++; return PRINTENV; }
unsetenv			{ argc++; return UNSETENV; }
cd		            { argc++; return CD; }
alias		        { argc++; return ALIAS; }
unalias				{ argc++; return UNALIAS; }
bye                 { argc++; return BYE; }
"\n"		        { return END; }
[\"]                { BEGIN(string_condition); }
ls					{ argc++; return LS; }
pwd					{ argc++; return PWD; }
wc					{ argc++; return WC; }
sort				{ argc++; return SORT; }
page				{ argc++; return PAGE; }
cat					{ argc++; return CAT; }
cp					{ argc++; return CP; }
mv					{ argc++; return MV; }
ping				{ argc++; return PING; }
echo        { argc++; return ECHO; }
"|"		      { return PIPE; }
{CHAR}+     {
              argc++;
              //printf("%d\n", argc);
              if(argc == 1) //if only one word inputted, check if word has alias
              {
                if(ifAlias(yytext) && strcmp(subAliases(yytext), "ls") == 0)
                {
                  return LS;
                }

                else if(ifAlias(yytext) && strcmp(subAliases(yytext), "cd") == 0)
                {
                  return CD;
                }

                else if(ifAlias(yytext) && strcmp(subAliases(yytext), "setenv") == 0)
                {
                  return SETENV;
                }

                else if(ifAlias(yytext) && strcmp(subAliases(yytext), "printenv") == 0)
                {
                  return PRINTENV;
                }

                else if(ifAlias(yytext) && strcmp(subAliases(yytext), "alias") == 0)
                {
                  return ALIAS;
                }

                else if(ifAlias(yytext) && strcmp(subAliases(yytext), "bye") == 0)
                {
                  return BYE;
                }

                else if(ifAlias(yytext) && strcmp(subAliases(yytext), "pwd") == 0)
                {
                  return PWD;
                }
              }

              else
              {
                yylval.string = strdup(yytext);
                return STRING;
              };
            }
%%
