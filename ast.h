/**
 * ast.h
 * 
 * H file for abstract syntax tree
 * Feburary 2022
 * Mateo Roemro
 * 
 * 
 */

#ifndef AST_H
#define AST_H
//#include "symtab.h"

// enmu whihc alows us to distinguish node type
enum AST_Node_Type {
    A_VARDEC, 
    A_FUNDEC,
    A_IDENT,
    A_NUMBER,
    A_EXPR,
    A_IF,
    A_IFELSE,
    A_BLOCK,
    A_READ,
    A_WRITE,
    A_NUM,
    A_RETURN, 
    A_EXPR_STMT,
    A_PARAM,
    A_TERM,
    A_TRUE,
    A_FALSE,
    A_WHILE,
    A_IF_EXPR,
    A_IF_BODY,
    A_DO,
    A_ASSIGN,
    A_CALL,
    A_ARGSLIST
}; // end enum


//enum for operators
enum A_OPERATORS {
    A_PLUS,     // 0   for cases
    A_MINUS,    // 1   
    A_TIMES,    // 2   
    A_DIVIDE,   // 3   
    A_BOOLTYPE, // 4   
    A_VOIDTYPE, // 5   
    A_INTTYPE,  // 6   
    A_GREQ,     // 7   
    A_LT,       // 8
    A_GT,       // 9
    A_LSEQ,     // 10  
    A_EQUALS,   // 11  
    A_NOTEQ,    // 12  
    A_AND,      // 13  
    A_OR,       // 14  
    A_NOT       // 15  

};// end enum


// Main stat sctructure of AST

struct ASTNode {
    enum AST_Node_Type myType;
    enum A_OPERATORS calculated_type;
    char* name;
    char* label;
    struct SymbTab *symbol;
    struct ASTNode *s1, *s2, *next;
    int size;
    enum A_OPERATORS operator;
};

void indent(int tabs);

struct ASTNode* AST_Create_Node( enum AST_Node_Type my_type);

void AST_Print(struct ASTNode *p, int tab);

int CompareFormals(struct ASTNode *p, struct ASTNode *q);


#endif