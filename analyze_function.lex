/* Simple lex program to analyze function. */
     
ALNUM      [a-zA-Z0-9_]*
SPACE      [[:blank:]\f\n]
%%
     
#.*\n

{SPACE}+

"if"        printf("f(\n");

"//"        {	      register int c;
		      while ( (c = input()) != '\n' && c != EOF);
		      printf(".\n");
                }

                     
"/*"        {
                      register int c;
          
                      for ( ; ; )
                          {
                          while ( (c = input()) != '*' &&
                                  c != EOF )
                              ;    /* eat up text of comment */
          
                          if ( c == '*' )
                              {
                              while ( (c = input()) == '*' )
                                  ;
                              if ( c == '/' )
                                  break;    /* found the end */
                              }
          
                          if ( c == EOF )
                              {
                              fprintf(stderr, "EOF in comment\n" );
                              break;
                              }
                          }
		}

\"              {
                      register int c;
          
                      while ((c = input()) != '"' && c != EOF) {
			      if (c == '\\') {
				      if (input() == EOF) {
					      fprintf(stderr, 
						      "EOF in string\n");
					      break;
				      }
			      }
		      }
		      printf(".\n");
                }

\'              {
                      register int c;
          
                      while ((c = input()) != '\'' && c != EOF) {
			      if (c == '\\') {
				      if (input() == EOF) {
					      fprintf(stderr, 
						      "EOF in string\n");
					      break;
				      }
			      }
		      }
		      printf(".\n");
                }

for	printf("f(\n"); 

do	printf("d(\n");

while	printf("w\n");

 /* Union, attribute worth 1. */
union|attribute|__attribute__              printf("!\n");

 /* goto, inline worth 2 */
inline|__inline__|goto              printf("!\n!\n");

 /* register, mb, FASTCALL worth 4 */
register|"mb()"|FASTCALL        printf("!\n!\n!\n!\n");

 /* asm worth 8 */
asm              printf("!\n!\n!\n!\n!\n!\n!\n!\n");

 /* Hack for some crap #if 0'd stuff in arch/alpha/kernel/smc37c669.c. */
"$"		

{ALNUM}+        printf(".\n");

"("|")"         printf(".\n");

";"             printf(";\n");

\\\n

"<<"|">>"|"=="|"!="|"||"|"&&"|"|="|"&="|"^="|"<<="|">>=" printf(".\n");

"<"|">"|"="|"!"|"|"|"&"|"^"|"~"|"["|"]"|","|"+"|"-"|"*"|"/"|"%"|"." printf(".\n");

"?"            printf("f(\n{\n");

":"            printf("}\n");

"{"            printf("{\n");

"}"            printf("}\n");
%%
     
int main(int argc, char *argv[])
{
	++argv, --argc;  /* skip over program name */
	if ( argc > 0 )
		yyin = fopen( argv[0], "r" );
	else
		yyin = stdin;
	
	yylex();
	return 0;
}

