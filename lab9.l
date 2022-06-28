/*                
                    LEX routine to match and  send tokens to YACC.
                    YACC will then check if the input syntax is correct for
                    ALGOL-C language.

                    - Mateo Romero 
                      February 2022    

                    Last update: 4/13/2022
*/
%{

int mydebug=0;
int lineCount = 1;
#include "ast.h"
#include "y.tab.h"
%}


%%
int       {return(T_INT);}
void		  {return(T_VOID);}
boolean		{return(T_BOOLEAN);}
begin 		{return(T_BEGIN);}
end			  {return(T_END);}
of 			  {return(T_OF);}
read		  {return(T_READ);}
if        {return(T_IF);}
then      {return(T_THEN);}
else      {return(T_ELSE);}
while     {return(T_WHILE);}
do        {return(T_DO);}
return    {return(T_RETURN);}
write     {return(T_WRITE);}
true      {return(T_TRUE);}
false     {return(T_FALSE);}
and       {return(T_AND);}
or        {return(T_OR);}
not       {return(T_NOT);}
\".*\"    {yylval.string = strdup(yytext); return (T_QUOTED_STRING);}

"=="      {return(T_EQUALS);} /* these were needed since YACC was having shift reduce errors. */
">="      {return(T_GREQ);}
"<="      {return(T_LSEQ);}
"!="      {return(T_NOTEQ);}





[a-zA-Z_][a-zA-Z0-9_]*		{ if (mydebug) fprintf(stderr,"ID found\n");  // updated to recongize our  variable names
                        	 yylval.string=strdup(yytext); 
						 return(T_ID);
						}

[0-9][0-9]*	{if (mydebug) fprintf(stderr,"Digit found\n"); 
                       yylval.value=atoi((const char *)yytext); return(T_NUM);} 

[ \t]		{}


[ ;[\],()<>=!\+\-\* /] 	{ if (mydebug) fprintf(stderr,"return a token %c\n",*yytext);  // added in ; so lex can recognize declarations, as well as operators 
                       return (*yytext);}

\n 		{ lineCount++;} /* increment line count for debugging */

\/\/.*      { /*comments, do nothing */ }


%%

int yywrap(void)
{ return 1;}
