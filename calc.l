%{
    /*
     * calc.l
     * Dave Farnham (11/94)
     *
     * %option nounput:  supresses "yyunput defined but not used"
     */

    #include <readline/readline.h>
    #include <readline/history.h>
    #define YY_INPUT(buf, result, max_size) result = readline_input(buf, max_size);
    static int readline_input(char *buf, int size) {
        if (feof(yyin)) return YY_NULL;
        char *line = readline("> ");
        if (!line) return YY_NULL;
        snprintf(buf, size, "%s\n", line);
        if (strlen(line) > 0) add_history(line);
        free(line);
        return strlen(buf);
    }

    #define PI 3.141592653589793238462643383279502884197169399371
%}

%option noyywrap
%option nounput

D [0-9]
%%
[ \t] ;  /* Ignore spaces and tabs */

(sin|SIN)                     { return(SINE);     }
(cos|COS)                     { return(COSINE);   }
(tan|TAN)                     { return(TANGENT);  }
(asin|ASIN)                   { return(ASINE);    }
(acos|ACOS)                   { return(ACOSINE);  }
(atan|ATAN)                   { return(ATANGENT); }
(sqrt|SQRT)                   { return(SQRT);     }
(abs|ABS)                     { return(ABS);      }
(quit|QUIT|stop|STOP|end|END) { exit(0);          }
(pi|PI)                       { yylval = PI; return(NUMBER); }
(exp|EXP)                     { return(EXP);      }
(log|LOG|ln|LN)               { return(LOG);      }
(log2|LOG2)                   { return(LOG2);     }
(log10|LOG10)                 { return(LOG10);    }
\*\*                          { return(POW);      }
\<\<                          { return(LSHIFT);   }
\>\>                          { return(RSHIFT);   }

[a-z]{1}                      { yylval = (double)(yytext[0]-'a'); return(LETTER); }
\_                            { yylval = 26.0; return(LETTER); }

(prec|PREC)[ ][0-9]+          { precision = strtol(yytext+5, (char **)NULL, 0); }
(rad|RAD)                     { rad_deg = 1.0; printf ("Radian mode:\n"); }
(deg|DEG)                     { rad_deg = PI / 180.0; printf ("Degree mode:\n"); }

[b][01]+                    { yylval = (double)strtoul(yytext+1, (char **)NULL, 2); return(NUMBER); }
0[0-7]+                   | /* Octal and hex constants */
0[Xx][a-fA-F0-9]+           { yylval = (double)strtol(yytext, (char **)NULL, 0);
                                       return(NUMBER); }

{D}+\.?{D}*               | /* Handle constants and exponential notation */
{D}*\.{D}+                |
{D}+\.?{D}*[eE][+-]?{D}+  |
{D}*\.{D}+[eE][+-]?{D}+   { yylval = atof(yytext); return(NUMBER); }

[^ \t]                    return((int)yytext[0]); /* anything else just return it */
%%
/*
 * uncomment and remove '%option noyywrap' above if yywrap() is required
 *
   #undef yywrap
   yywrap(){};
 */
