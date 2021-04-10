CC=/usr/bin/cc

all:  bison-config flex-config main

bison-config:
	bison -d PARSER.y

flex-config:
	flex LEXER.l

main:
	$(CC) main.c PARSER.tab.c lex.yy.c -o main

clean:
	rm PARSER.tab.c PARSER.tab.h lex.yy.c main
