CC     = gcc
CFLAGS = -O2 -Wall -Wno-unused-function
LEXER  = flex -l
#LEXER  = /usr/bin/lex
PARSER = bison -y
#PARSER = /usr/bin/yacc
RM     = /bin/rm -f

calc: calc.y calc.l
	$(LEXER) calc.l
	$(PARSER) calc.y
	$(CC) $(CFLAGS) y.tab.c -o $@ -lm -lreadline

clean:
	$(RM) calc y.tab.c lex.yy.c
