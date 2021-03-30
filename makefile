linux:
	bison -dy json.y 
	flex json.l
	gcc lex.yy.c y.tab.c
	./a.out
windows:
	yacc -dy json.y 
	lex json.l
	gcc lex.yy.c y.tab.c
	./a.exe
	
clean:
	rm mainc.o
