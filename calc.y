%{
    /*
     * calc.y
     * Dave Farnham (11/94)
     */

#include <stdio.h>
#include <unistd.h>
#include <math.h>
#include <string.h>
#define YYSTYPE double // data type of yacc stack

#define LAST_EVAL 26
YYSTYPE rad_deg = 1;  // Either 1.0 or pi/180 for radians or degrees
int precision = 16;   // Digits of decimal precision
YYSTYPE reg[27];      // Registers/variables a-z with '_' holding the last evaluated value

extern void yyerror(char *);
extern int yylex();

long fact(long);

%}
%token NUMBER LSHIFT RSHIFT VARIABLE
%token SINE COSINE TANGENT ASINE ACOSINE ATANGENT SQRT ABS POW
%token EXP LOG LOG2 LOG10
%token BIN
%left '|'           // bitwise OR
%left '^'           // bitwise XOR
%left '&'           // bitwise AND
%left LSHIFT RSHIFT // bitwise left, right shift
%left '+' '-'       // left associative, same precedence
%left '*' '/' '%'   // left associative, higher precedence
%left '~'           // one's compliment
%right POW          // exponentiation
%left '!'           // factorial
%left UNARYMINUS UNARYPLUS
%%
eval:
        | eval '\n'      { ; }
        | eval BIN '\n' { // display the last result in base-2 
                          unsigned int n = (unsigned int)reg[LAST_EVAL];
                          int found_first_non_zero = 0;
                          for (int i = 31; i >= 0; i--) {
                              int bit = n >> i & 1;
                              if (!found_first_non_zero && bit) {
                                  found_first_non_zero = 1;
                              }
                              if (found_first_non_zero) {
                                  putchar('0' + bit);
                              }
                          }
                          if (!found_first_non_zero) {
                              putchar('0');
                          }
                          putchar('\n');
                        }
        | eval expr '\n' { reg[LAST_EVAL] = $2; // variable '_' holds the last evaluation
                           if ((YYSTYPE)((long)$2) == $2) {
                               printf("%ld\n", (long)$2);
                           } else {
                               char buf[BUFSIZ];
                               snprintf(buf, BUFSIZ, "%.*lf", precision, $2);
                               // trim trailing zeros
                               int i = strlen(buf) - 1;
                               while (i > 0 && buf[i] == '0') {
                                   buf[i--] = '\0';
                               }
                               printf("%s\n", buf);
                           }
                         }
        | eval VARIABLE '=' expr '\n' { reg[(int)$2] = $4;  }
        | eval error '\n'             { yyerrok; yyclearin; }
        ;

expr:     NUMBER                    { $$ = $1;                   }
        | VARIABLE                  { $$ = reg[(int)$1];         }
        | '-' expr %prec UNARYMINUS { $$ = -$2;                  }
        | '+' expr %prec UNARYPLUS  { $$ = $2;                   }
        | expr '!'                  { $$ = fact((long)$1);       }
        | expr POW expr             { $$ = pow($1, $3);          }
        | '~' expr                  { $$ = ~(long)$2;            }
        | expr '*' expr             { $$ = $1 * $3;              }
        | expr '/' expr             { $$ = $1 / $3;              }
        | expr '%' expr             { $$ = (long)$1 % (long)$3;  }
        | expr '+' expr             { $$ = $1 + $3;              }
        | expr '-' expr             { $$ = $1 - $3;              }
        | expr LSHIFT expr          { $$ = (long)$1 << (long)$3; }
        | expr RSHIFT expr          { $$ = (long)$1 >> (long)$3; }
        | expr '&' expr             { $$ = (long)$1 & (long)$3;  }
        | expr '^' expr             { $$ = (long)$1 ^ (long)$3;  }
        | expr '|' expr             { $$ = (long)$1 | (long)$3;  }
        | '(' expr ')'              { $$ = $2;                   }
        | '[' expr ']'              { $$ = $2;                   }
        | trig_expr                 { $$ = $1;                   }
        | other_math_expr           { $$ = $1;                   }
        ;

trig_expr:  SINE     '(' expr ')' { $$ = sin($3 * rad_deg);  }
          | COSINE   '(' expr ')' { $$ = cos($3 * rad_deg);  }
          | TANGENT  '(' expr ')' { $$ = tan($3 * rad_deg);  }
          | ASINE    '(' expr ')' { $$ = asin($3) / rad_deg; }
          | ACOSINE  '(' expr ')' { $$ = acos($3) / rad_deg; }
          | ATANGENT '(' expr ')' { $$ = atan($3) / rad_deg; }
        ;

other_math_expr:  SQRT  '(' expr ')' { $$ = sqrt($3);  }
                | ABS   '(' expr ')' { $$ = fabs($3);  }
                | EXP   '(' expr ')' { $$ = exp($3);   }
                | LOG   '(' expr ')' { $$ = log($3);   }
                | LOG2  '(' expr ')' { $$ = log2($3);  }
                | LOG10 '(' expr ')' { $$ = log10($3); }
        ;
%%
        /* end of grammar */

#include "lex.yy.c"

static char *progname; // for error messages

long
fact(long n) {
    if (n < 0) {
        yyerror("warning: NaN produced, returning 0");
        return 0;
    } else if (n < 1) {
        return 1;
    } else {
        return n * fact(n-1);
    }
}

void
yyerror(char *s) {
    fprintf(stderr, "%s: %s\n", progname, s);
}

int
main(int argc, char *argv[]) {
    srand48(arc4random());
    progname = argv[0];
    if (isatty(0)) {
        printf("calc: 11/94 (Dave Farnham)\nQuit with ^D,quit\n");
    }
    yyparse();
    exit(0);
}
