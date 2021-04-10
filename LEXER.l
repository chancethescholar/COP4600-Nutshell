%{
#include "PARSER.tab.h"
#include <string.h>
#include<stdio.h>
#include "global.h"

int argc = 0;

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
    if(strcmp(current -> name, name) == 0) {
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

[ ]		            { }
setenv				{ return SETENV; }
printenv			{ return PRINTENV; }
unsetenv			{ return UNSETENV; }
cd		            { return CD; }
alias		        { return ALIAS; }
unalias				{ return UNALIAS; }
bye                 { return BYE; }
"\n"		        { return END; }
[\"]                { BEGIN(string_condition); }
ls					{ return LS; }
pwd					{ return PWD; }
wc					{ return WC; }
sort				{ return SORT; }
page				{ return PAGE; }
cat					{ return CAT; }
cp					{ return CP; }
mv					{ return MV; }
ping				{ return PING; }
" "         { argc++; }
[\t\n]      { argc++; }
{CHAR}+     {
                printf("yytext: %s\n", yytext);
                yylval.string = strdup(yytext);
                return STRING;
              //printf("%d\n", argc);
            }

%%
