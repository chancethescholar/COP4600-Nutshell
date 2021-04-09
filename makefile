all: nutshell
	
nutshell: y.tab.o lex.yy.o global.h
	cc lex.yy.o y.tab.o -o nutshell

main.o: main.c global.h
	cc main.c

lex.yy.o: lex.yy.c
	cc -c lex.yy.c

y.tab.o: y.tab.c
	cc -c y.tab.c

lex.yy.c: shell.l
	lex shell.l

y.tab.c: shell.y main.c
	yacc -d shell.y
