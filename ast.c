/**
 * ast.c
 * Implementation of ast functions
 * Mateo Romero    NEED PRE AND POST!!!!!!!!!!!!!!!!!!!!
 * February 2022
 * 
 * 
 * LAST UPDATE: 4/27/2022
 */


#include "ast.h"
#include <stdlib.h>
#include <stdio.h>


// PRE: integer for amount of spaces
// POST: should create needed levels for 
void indent(int tabs) {
    for (int i = 0; i < tabs; i++)
        printf("  ");
    return;
}

// PRE: AST_Node_Type
//POST: ptr to a ASTNode from heap
struct ASTNode* AST_Create_Node( enum AST_Node_Type my_type) {
    struct ASTNode *p;

    p = (struct ASTNode*)malloc(sizeof(struct ASTNode));
    p->myType = my_type;
    p->s1=NULL;
    p->s2=NULL;
    p->next=NULL;
    p->size = 1; // default size, should only be more than one for array decs
}

// PRE: ASTNode pointers
// POST: return 1 if parameters and sizes match up correctly, otherwise 0
int CompareFormals(struct ASTNode *p, struct ASTNode *q) {
    if (p == NULL && q == NULL) return 1;
    if (p == NULL || q == NULL) return 0;
    if (p->calculated_type != q->calculated_type)return 0;

    return CompareFormals(p->next, q->next); 
}


// PRE: enumerated type A_OPERATORS
// POST: print out needed operator for expressions / types
void Print_OP(enum A_OPERATORS op) {

    switch (op) {

        case A_PLUS : 
            printf(" + ");
            break;
        case A_MINUS :
            printf(" - ");
            break;
        case A_TIMES :
            printf(" * ");
            break;
        case A_DIVIDE :
            printf(" / ");
            break;
        case A_BOOLTYPE :
            printf("BOOL ");
            break;
        case A_VOIDTYPE :
            printf("VOID ");
            break;

        case A_INTTYPE :
            printf("INT ");
            break;

        case A_GREQ: 
            printf(" >= ");
            break;

        case A_LT:
            printf(" < ");
            break;  

        case A_GT:
            printf(" > ");
            break;   

        case A_LSEQ:
            printf(" <= ");
            break;

        case A_EQUALS:  
            printf(" == ");
            break;

        case A_NOTEQ:         
            printf(" != ");
            break;
        
        case A_AND:
            printf(" and ");
            break;
        
        case A_OR:
            printf(" or ");
            break;
        
        case A_NOT:
            printf(" not ");
            break;

        default : fprintf(stderr, "WARNING: Unrecognizable operator.");
    }
}

//PRE: Ptr to ASTNode
// POST: formatted output of the AST
void AST_Print(struct ASTNode *p, int tab) {

    // no else needed, tree is NULL
    if(p == NULL) return;

    switch(p->myType) {
        case A_VARDEC:
            if (p->size > 1) {
                indent(tab);
                printf("Variable ");
                Print_OP(p->operator);
                printf("%s[%d]\n", p->name, p->size);
            }  
            else  {  
                indent(tab);
                printf("Variable ");
                Print_OP(p->operator); 
                printf("%s\n", p->name);
            }

            AST_Print(p->s1, tab);
            AST_Print(p->next, tab);           
            break;

        case A_FUNDEC:
            Print_OP(p->operator);
            printf("FUNCTION %s \n", p->name); 
            
            if (p->s1 == NULL) {
                indent(tab+1);
                printf("(VOID)\n");  // print ONLY IF params are void
            }
            else {
                AST_Print(p->s1, tab+1);  // print params
            }

            AST_Print(p->s2, tab+1); // print body
            AST_Print(p->next,tab); 
            break;

        case A_PARAM:
            printf("\n");
            indent(tab);
            printf("PARAMATER ");
            Print_OP(p->operator);
            printf("%s", p->name);
            AST_Print(p->next, tab);
            break;

        case A_BLOCK:
            indent(tab);
            printf("BLOCK STATEMENT\n");
            AST_Print(p->s1, tab+1);
            AST_Print(p->s2,tab+1);
            indent(tab);
            printf("END\n");
            AST_Print(p->next, tab); 
            break;

        case A_READ:
            indent(tab);
            printf("READ STATEMENT\n");
            AST_Print(p->s1, tab+1);
            AST_Print(p->next, tab+1); // statements are next connected
            break;

        case A_IDENT:
            indent(tab);
            printf("IDENTIFIER with name %s \n", p->name);
            if (p->s1 != NULL) {
                indent(tab);
                printf("Array [\n");
                AST_Print(p->s1, tab+1);
                indent(tab);
                printf(" ] \n");
            }   
            break;

        case A_NUM:
            indent(tab);
            printf("Number with value %d\n", p->size);
            break;

        case A_EXPR:
            indent(tab);
            printf("Expression ");
            Print_OP(p->operator);  // operator first to avoid unwanted ambiguity
            printf("\n");
            AST_Print(p->s1,tab+1);
            AST_Print(p->s2,tab+1);
            break;

        case A_WRITE:
            indent(tab);
            printf("WRITE STATEMENT\n");
            AST_Print(p->s1, tab+1);
            AST_Print(p->s2, tab+1);
            AST_Print(p->next, tab);
            break;

        case A_RETURN:
            indent(tab);
            printf("RETURN\n");
            AST_Print(p->s1,tab+1);
            AST_Print(p->next,tab);
            break;

        case A_CALL:
            indent(tab);
            printf("FUNCTION CALL ");
            printf("%s\n", p->name);
            indent(tab+1);
            printf("ARGUMENTS\n");
            AST_Print(p->s1, tab+1);
            break;
            
        case A_WHILE:
            indent(tab);
            printf("WHILE STATEMENT\n");;
            AST_Print(p->s1,tab+1); 
            AST_Print(p->s2,tab);
            AST_Print(p->next, tab); // ALL STATEMENTS ARE NEXT CONNECTED
            break;

        case A_TRUE:
            indent(tab);
            printf("Number with value %d\n", p->size); // this should print 1 for true, and 0 for false
            break;

        case A_FALSE:
            indent(tab);
            printf("Number with value %d\n", p->size); // this should print 1 for true, and 0 for false
            break;   
        
        // case A_DO:
        //     AST_Print(p->s1,tab+1);
        //     break;

        case A_ASSIGN:
            indent(tab);
            printf("ASSIGNMENT STATEMENT\n");
            AST_Print(p->s1, tab+1);
            AST_Print(p->s2, tab+1);
            AST_Print(p->next, tab);
            break;
        
        case A_IF_EXPR: 
            indent(tab);
            printf("IF BLOCK\n");
            AST_Print(p->s1, tab+1);
            indent(tab);
            printf("THEN STATEMENT\n");
            AST_Print(p->s2, tab);
            break;

        case A_IF_BODY:
            AST_Print(p->s1, tab+1);
            if( p->s2 != NULL) {
                indent(tab);
                printf("ELSE STATEMENT\n");
                AST_Print(p->s2, tab+1);
            }
            break;
        
        case A_EXPR_STMT: 
            if(p->s1 != NULL) {
                indent(tab);
                printf("EXPRESSION STATEMENT\n");
                AST_Print(p->s1, tab);           
            }
            AST_Print(p->next, tab);
            break;

        case A_ARGSLIST:
            AST_Print(p->s1, tab+1);
            AST_Print(p->next, tab);
            break;
        

        default: fprintf(stderr, "WARNING: unknown type in ASTPrint\n");
        
    }// end of switch

}// end of AST_Print