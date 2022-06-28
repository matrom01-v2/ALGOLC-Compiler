%{


/* 	
			The following is the YACC routine to parse tokens for ALGOL-C language.
			It currently checks only if the input syntax is correct based on our grammar. 
			The syntax directed semantic action implements an Abstract Syntax Tree to parse through.
			See comments for semantic action and their purposes.
	
			Mateo Romero 
			February 2022

			Latest Update: 4/29/2022 
*/


/* begin specs */
#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include "symtable.h"
#include "emit.h"
//#include "ast.h"

#define FUNCTION_MIN_SIZE 2

struct ASTNode* Program = NULL; // global variable for tree

extern int lineCount; // extern int from lex file for line
extern int mydebug; 
int level = 0; // level for scope of variables
int offset = 0;
int maxoffset = 0;
int goffset = 0; // offset for in and out of functions

int yylex();

void yyerror (s)  /* Called by yyparse on error */
     char *s;
{
  printf ("Error on line: %d \n%s\n", lineCount, s); // print out line number where syntax error occured
}


%}
/*  defines the start symbol, what values come back from LEX and how the operators are associated  */

%start program // start at P since added DECLS list

%union {
	int value;
	char *string;    // this allows lex to return an integer or a pointer to a char*
	struct ASTNode* ast_node;
	enum A_OPERATORS op;
}

// TOKENS
%token <value> T_NUM
%token <string> T_ID T_QUOTED_STRING
%token T_INT T_VOID T_BOOLEAN T_BEGIN T_END T_OF T_READ T_IF T_THEN T_ELSE T_WHILE T_DO T_RETURN T_WRITE T_TRUE T_FALSE T_AND T_OR T_NOT
%token T_EQUALS T_GREQ T_LSEQ T_NOTEQ 
%type<ast_node> declaration_list declaration var_declaration var_list fun_declaration statement params param_list param compound_stmt statement_list
%type<ast_node> local_declarations read_stmt var write_stmt call args args_list assignment_stmt iteration_stmt 
%type<ast_node> expression simple_expr additive_expr term factor return_stmt expression_stmt selection_stm 
%type<op> type_spec addop relop multop

%%	/* end specs, begin rules */

program : declaration_list { Program = $1;}  /*Program -> declaration-list */
	;

declaration_list : declaration {$$ = $1;} 
	| declaration declaration_list  { $$ = $1; $1->next = $2;}
	;

declaration : var_declaration {$$ = $1;}
			| fun_declaration {$$ = $1;}
			;

var_declaration : type_spec var_list ';' { // need to update type in varlist and pass up to parent
					$$ = $2;
					struct ASTNode* p;
					p = $$;

					while (p != NULL) {
						p->operator = $1;  // updates operators
						p->symbol->Type = $1; // update the symbol table type
						p = p->s1;
					}
				}
			   ; 

var_list : T_ID 
		{
			if(Search($1, level, 0 ) == NULL) { // search the symbol table for var, if not found insert

				$$ = AST_Create_Node(A_VARDEC); // create nodes in tree for ID's
				$$->symbol = Insert($1, 0, 0, level, 1, offset);
				$$->calculated_type = Search($1, level, 1)->Type;
				$$->name = $1;
				$$->size = 1;
				offset += 1;
			}
			else {
				yyerror($1);
				yyerror("Symbol is already in use!");
				exit(1);
			}
		}

		| T_ID '[' T_NUM ']' 
		{	
			if (Search($1, level, 0) == NULL) {

				$$ = AST_Create_Node(A_VARDEC);
				$$->symbol = Insert($1, 0, 2, level, $3, offset);
				$$->name = $1;
				$$->calculated_type = Search($1, level, 1)->Type;
				$$->size = $3; // set size to $3 to specify array

				offset += $3; // allocate memory for array size
			}
			else {
				yyerror($1);
				yyerror("Symbol is already in use!");
				exit(1);
			}
		}

		| T_ID ',' var_list {
			if (Search($1, level, 0) == NULL)  {

				$$ = AST_Create_Node(A_VARDEC);
				$$->symbol = Insert($1, 0, 2, level, 1, offset);
				$$->name = $1;
				offset += 1;
				$$->s1 = $3; // branch for var_list
			}
			else {
				yyerror($1);
				yyerror("Symbol is already in use!");
				exit(1);
			}
		}

		| T_ID '[' T_NUM ']' ',' var_list 
		{	
			if (Search($1, level, 0) == NULL) {

				$$ = AST_Create_Node(A_VARDEC);
				$$->symbol = Insert($1, 0, 2, level, $3, offset);
				$$->name = $1;
				$$->s1 = $6;
				$$->calculated_type = Search($1, level, 1)->Type;
				$$->size = $3; // set size to $3 to specify array

				offset += $3; // allocate memory for array size
			}
			else {
				yyerror($1);
				yyerror("Symbol is already in use!");
				exit(1);
			}
		}
		;

type_spec : T_INT {$$ = A_INTTYPE;}
		 | T_VOID {$$ = A_VOIDTYPE;}
		 | T_BOOLEAN {$$ = A_INTTYPE;}
		 ;
		 /* TAKING BREAK 1 HERE */

fun_declaration : type_spec T_ID '(' 
								{
									if (Search($2, level, 0) != NULL) {   // search for symbol, if not null, barf
										yyerror($2);
										yyerror("Symbol is already in use!");
										exit(1);	
									}
									Insert($2, $1, 1, level, 0, 0);	// insert vardec symbol
									goffset = offset; // update global offset
									offset = FUNCTION_MIN_SIZE;
									maxoffset = 0;
								}

					 params { 
						 		(Search($2, 0, 0))->fparms = $5; 
							} // set function params

					')' compound_stmt
				{
					// here update $ since we have semantic action in between.
					$$ = AST_Create_Node(A_FUNDEC);
					$$->operator = $1; // decl type
					$$->calculated_type = $1;
					$$->name = $2;
					$$->s1 = $5; // parameters   
					$$->s2 = $8; // this is for compound statements
					$$->symbol = Search($2, 0, 0); // symbol
					$$->symbol->mysize = maxoffset; // keep track of size of function
					$$->size = maxoffset;

					// offset -= Delete(1); 
					// level = 0; // reset level for 
					offset = goffset; 
					
				}
			    ;

params : T_VOID {$$ = NULL;}
	   | param_list {$$ = $1;}
	   ; 

param_list : param {$$ = $1;}
          | param ',' param_list 
		  {
			  $$ = $1;
			  $$->next = $3;  // link param to $3 so we keep the list
		  }
          ;

param : T_ID T_OF type_spec 
		{
			if (Search($1, level+1, 0) != NULL) {
				yyerror($1);
				yyerror("Symbol is already in use!");
				exit(1);
			}
			$$ = AST_Create_Node(A_PARAM);
			$$->name = $1;
			$$->operator = $3;
			$$->size = 0; 
			$$->calculated_type = $3;
			$$->symbol = Insert($1, $3, 0, level+1, 1, offset);
			offset += 1;
		}

	  | T_ID '['  ']' T_OF type_spec
		{
			if (Search($1, level+1, 0) != NULL) {
				yyerror($1);
				yyerror("Symbol is already in use!");
				exit(1);
			}
			$$ = AST_Create_Node(A_PARAM);
			$$->name = $1;
			$$->size = 3; // num for array, anything greater than 1, using 3
			$$->operator = $5;
			$$->symbol = Insert($1, $5, 2, level+1, 1, offset);
			offset += 1;
		}	  
      ; /* TAKING BREAK 2 HERE */

compound_stmt : T_BEGIN {level++;} local_declarations statement_list {if (mydebug) Display();} T_END
				{ $$ = AST_Create_Node(A_BLOCK);
				  $$->s1 = $3;
				  $$->s2 = $4; // these changed up one because of intersentence SDSA
			      if(offset > maxoffset)
				  	maxoffset = offset;  // maintain maximum space needed
				  		  
				  offset = offset - Delete(level);
				  level--;
				}
			  ;

local_declarations : /*empty */ { $$ = NULL;}
				  | var_declaration local_declarations 
				  	{ 
					  $$ = $1; $$->next = $2; // next connect lists
					}
				  ;


statement_list : {$$ = NULL;} /* EMPTY */
			  | statement statement_list 
			  {
				$$ = $1; 
			  	$$->next = $2;
			  }
			  ; 

statement : expression_stmt {$$ = $1;}   // THESE ALL NEED ASTNODE TYPES!!!  $$ = will be the action
		  | compound_stmt {$$ = $1;}
		  | selection_stm {$$ = $1;}
		  | iteration_stmt {$$ = $1;}
		  | assignment_stmt {$$ = $1;}
		  | return_stmt {$$ = $1;}
		  | read_stmt {$$ = $1;}
		  | write_stmt {$$ = $1;}
          ;

expression_stmt : expression ';' {$$ = AST_Create_Node(A_EXPR_STMT); $$->s1 = $1; }   // create node for empty expression
				| ';' {$$ = AST_Create_Node(A_EXPR_STMT);} /* empty expression */
				;

selection_stm :  T_IF expression T_THEN statement 
				{ 
					$$ = AST_Create_Node(A_IF_EXPR); $$->s1 = $2;        // set s1 to be expression
					struct ASTNode* p = AST_Create_Node(A_IF_BODY);      // create second node to hold second piece
					$$->s2 = p;          
					p->s1 = $4;                                          // this will hold statement
				}
			   | T_IF expression T_THEN statement T_ELSE statement 
			   {
				  	$$ = AST_Create_Node(A_IF_EXPR); $$->s1 = $2; 
					struct ASTNode* p = AST_Create_Node(A_IF_BODY);     // do the same
					$$->s2 = p; 
					p->s1 = $4;
					p->s2 = $6;                                         // p->s2 will NOT be NULL for else
			   }
			   ; 

iteration_stmt : T_WHILE expression T_DO statement 
				{
					$$ = AST_Create_Node(A_WHILE);  
					$$->s1 = $2;        // similar to if
					$$->s2 = $4; 
				}
               ; 

return_stmt : T_RETURN ';' {$$ = AST_Create_Node(A_RETURN);}  // empty return to prevent seg fault
            | T_RETURN expression ';' {$$ = AST_Create_Node(A_RETURN); $$->s1 = $2;}  
			;

read_stmt : T_READ var ';' { $$ = AST_Create_Node(A_READ); $$->s1 = $2;} // var is a node so point to it
         ;

write_stmt : T_WRITE expression ';' {$$ = AST_Create_Node(A_WRITE); $$->s1 = $2;} 
			| T_WRITE T_QUOTED_STRING ';'{$$ = AST_Create_Node(A_WRITE); $$->name = $2;}
		   ; 

assignment_stmt : var '=' simple_expr ';' 
				{
					$$ = AST_Create_Node(A_ASSIGN); 
					if (($1->calculated_type == A_VOIDTYPE) || ($1->calculated_type != $3->calculated_type)) {
						yyerror("WARNING: type mismatch in assignment statement.");
						exit(1);
					}
					$$->name = CreateTemp();
					$$->symbol = Insert($$->name, $1->calculated_type, 0, level, 1, offset);
					$$->s1 = $1;
					$$->s2 = $3;
					offset++;
				}				   
				;
		
expression : simple_expr {$$ = $1;}
		   ;

var : T_ID
		{   /** check if $1 is in symbol table **/
			struct SymbTab *p;
			if ((p=Search($1, level, 1)) != NULL) {

				
				$$ = AST_Create_Node(A_IDENT); // create node for ID's
				$$->name = $1;
				$$->symbol = p;
				$$->calculated_type = Search($1, level, 1)->Type; // set calculated type using search
			}
			else {
				yyerror($1);
				yyerror("Symbol is not in the table!");
				exit(1);
			}

		}

	| T_ID '[' expression ']' 
		{
			struct SymbTab *p;

			if((p = Search($1, level, 1)) != NULL) {
				$$ = AST_Create_Node(A_IDENT);
				$$->name = $1;
				$$->symbol = p;
				$$->calculated_type = p->Type;
				$$->s1 = $3;   // set s1 branch to expression


				if (p->IsAFunc == 2){
					$$->symbol = p;
				}

				else {
					yyerror($1);
					yyerror("NOt an array!");
					exit(1);
				}
			}
			else {
				yyerror($1);
				yyerror("Symbol is not in the table!");
				exit(1);
			}
			
		
		}
	; 


simple_expr : additive_expr {$$ = $1;}
            | additive_expr relop additive_expr 
			{
			   if( $1->calculated_type != $3->calculated_type) {
					yyerror("Warning: incorrect type in use.");
					exit(1);   
			   }

			   $$ = AST_Create_Node(A_EXPR);  // create node for expressions
			   $$->s1 = $1;
			   $$->operator = $2; // operator for expression
			   $$->s2 = $3;
			   $$->calculated_type = $1->calculated_type;
			   $$->name = CreateTemp();
			   $$->symbol = Insert($$->name, A_INTTYPE, 0, level, 1, offset);
			   offset++;
			}
			;

relop : T_GREQ   {$$ = A_GREQ;}
	  | '<'      {$$ = A_LT;}
	  | '>'      {$$ = A_GT;}
      | T_LSEQ   {$$ = A_LSEQ;}
	  | T_EQUALS {$$ = A_EQUALS;}  
	  | T_NOTEQ  {$$ = A_NOTEQ;}
	  ;

additive_expr : term {$$ = $1;}
			  | additive_expr addop term
			  {
				if( $1->calculated_type != $3->calculated_type){
					yyerror("Warning: incorrect type in use.");
					exit(1);
				}  

				$$ = AST_Create_Node(A_EXPR);
			   	$$->s1 = $1;
			   	$$->operator = $2;      // this acts similar to simple_expr
			   	$$->s2 = $3;
				$$->name = CreateTemp();
				$$->calculated_type = $1->calculated_type;
				$$->symbol = Insert($$->name, A_INTTYPE, 0, level, 1, offset);
				offset++;		   

			  }
			  ;

addop : '+' {$$ = A_PLUS;}
      | '-' {$$ = A_MINUS;}
	  ;
 
term : factor {$$ = $1;}
	  | term multop factor // needs calculated_type for all math
	  				{
						if( $1->calculated_type != $3->calculated_type){
							yyerror("Warning: incorrect type in use.");
							exit(1);
						}

						$$ = AST_Create_Node(A_EXPR);
						$$->s1 = $1;  
						$$->operator = $2;        // this is similar to additive_expr
						$$->s2 = $3;
						$$->calculated_type = $1->calculated_type;
						$$->name = CreateTemp();
						$$->symbol = Insert($$->name, A_INTTYPE, 0, level, 1, offset);
						offset++;
					}
	  ;

multop : '*' {$$ = A_TIMES;}
	   | '/' {$$ = A_DIVIDE;}
	   | T_AND  {$$ = A_AND;}
	   | T_OR {$$ = A_OR;}
	   ;

// fix indentation
factor : '(' expression ')' {$$ = $2;}
       | T_NUM {
		   			$$ = AST_Create_Node(A_NUM); 
					$$->size = $1; 
					$$->calculated_type = A_INTTYPE;
				} // create node and set size (value) to T_NUM

	   | var {$$ = $1;}

	   | call {$$ = $1;}

	   | T_TRUE {
		   			$$ = AST_Create_Node(A_TRUE); 
					$$->size = 1; 
					$$->calculated_type = A_INTTYPE;
				} // set size to 1 for true, 0 for false 

	   | T_FALSE {
		   			$$ = AST_Create_Node(A_FALSE); 
					$$->size = 0; 
					$$->calculated_type = A_INTTYPE;
				}  

	   | T_NOT factor {
		   				$$ = AST_Create_Node(A_EXPR); 
						$$->calculated_type = A_NOT;
						$$->operator = A_NOT; 
						$$->name = CreateTemp();
						$$->symbol = Insert($$->name, A_NOT, 0, level, 1, offset);
						$$->s1 = $2; 
						offset++;
					  }  // operator = A_NOT in this case. Factor can be an expression NEEDS CreateTemp()
	   ;

call : T_ID '(' args ')' {
							struct SymbTab *p = Search($1, 0, 0);
							if (p != NULL ) { // check if in symbol table
								
								if(p->IsAFunc != 1) {  // check for if a function
									yyerror($1);
									yyerror("WARNING: Symbol is not a function.");
								}
							
								if (CompareFormals(p->fparms, $3) != 1) {  // check parameters 
									yyerror($1);
									yyerror("WARNIGN: paramater mismatch or incorrect amount of parameters used from orriginal declaration.");
									exit(1);
								}
								$$ = AST_Create_Node(A_CALL); 
								$$->s1 = $3; 
								$$->calculated_type = p->Type;
								$$->name = $1;
								$$->symbol = p;
							}				
							else {
								yyerror($1);
								yyerror("WARNIGN: Function not defined.");
								exit(1);
							}	
						}  // only next connect lists, see args_list
     ;

args : args_list {$$ = $1;}
	 | {$$ = NULL;} /* empty */ 
	 ;

args_list : expression { $$ = AST_Create_Node(A_ARGSLIST); 
						 $$->s1 = $1;
						 $$->calculated_type = $1->calculated_type;
						 $$->name = CreateTemp();
						 offset++;
						}
		  | expression ',' args_list { 
			  			$$ = AST_Create_Node(A_ARGSLIST); 
			  			$$->s1 = $1; 
						$$->calculated_type = $1->calculated_type;
						$$->name = CreateTemp();
			  			$$->next = $3; 
						  offset++;
						} // next connect node here for created node.
		  ; 	 


%%	/* end of rules, start of program  test*/

void main(int argc, char* argv[])
{ 	
	FILE *fp = NULL;
	int i = 1;
	char s[100];

	while (i < argc ) {

		if (strcmp(argv[i], "-d" ) == 0)
			mydebug = 1; // set to print tree and other debugging needs

		if (strcmp(argv[i], "-o") == 0) { // print nada

			strcpy(s, argv[i+1]);
			strcat(s, ".asm");

			fp = fopen(s, "w");

			if (fp == NULL) {
				fprintf(stderr, "Cannot Open %s\n", s);
				exit(1);
			}
		}
		i++;	
	}
	
	
	yyparse();
	if (mydebug) Display(); // changed for ONLY IF -d was used
	if (mydebug) printf("Main symbol table START\n");
	if (mydebug) printf("finished parsing\n");

	if (mydebug) AST_Print(Program, 0);

	if (fp != NULL) {
		emit_header(Program, fp);
		emit_AST(Program, fp);
	}
	else {
		printf("No output file defined.\n");
	}
}