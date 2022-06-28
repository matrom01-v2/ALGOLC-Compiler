# makefile
#
# makefile for lab9
#
# make and run updated files to generate and parse an abstract syntax tree, then emit MIPS runnable MIPS
# code to a file 
#
# Mateo Romero
# 
# April 2022


all : lab9

lab9: lab9.l lab9.y ast.c ast.h symtable.h symtable.c emit.h emit.c
	lex lab9.l
	yacc -d lab9.y
	gcc -o lab9 y.tab.c lex.yy.c ast.c symtable.c emit.h emit.c

test: 
	./lab9 -o foo < test.txt

debug: all
	./lab9 -o -d < test.txt	

compile: lab9
	./lab9 -o foo < test.txt

run:
	java -jar Mars4_5.jar sm foo.asm
	
clean: 
	rm -f lab9
	rm -f ./-d.asm