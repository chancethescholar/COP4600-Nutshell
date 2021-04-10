%{
#include "PARSER.tab.h"
#include <string.h>
#include<stdio.h>
#include<string.h>
#include "global.h"

char* subAliases(char* name){
  int currentCom = 0;
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

  for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return aliasTable.word[i];
        }
    }
    return name;
}
bool ifAlias(char* name){
for (int i = 0; i < aliasIndex; i++) {
      if(strcmp(aliasTable.name[i], name) == 0) {
          return true;
      }
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
{CHAR}+             {
						if(ifAlias(yytext))
						{
							printf("yytext: %s\n", yytext);
							char *yycopy = strdup( subAliases(yytext) );
							for ( int i = strlen(subAliases(yytext)) - 1; i >= 0; --i )
								unput( yycopy[i] );
							free( yycopy );

						}
						else
						{
							printf("yytext: %s\n", yytext);
							yylval.string = strdup(yytext);
							return STRING;
						};
                     }
%%

