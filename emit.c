/**
 * emit.c
 * 
 * The following is a program that emits MIPS code to a given file.
 * The mips code can then be executed, compiling and running a written ALGOL program.
 * 
 * Mateo Romero
 * 
 * April 2022
 * 
 * Last update: 7/12/2022
 * 
*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "ast.h"
#include "emit.h"
#include "symtable.h"


#define WSIZE 4 // bytes for words
#define WORD_LOG_SIZE 2 // for branches

int STEMP= 0;
char *function_name; // keep track of names of functions for returns


// PRE: ASTNode pointer and pointer to File
// POST: emit header for global variables and strings
void emit_header(struct ASTNode* p, FILE *fp) {
      
    fprintf(fp, ".data # start of the DATA section\n\n");
    emit_global_strings(p, fp);
    fprintf(fp, "\n_NL: .asciiz \"\\n\" # New line\n");
    fprintf(fp, "\n.align 2 # start all globa variables aligned\n\n");
    emit_global_variables(p, fp);
    fprintf(fp, "\n.text # start of code segment\n\n");
    fprintf(fp, ".globl main\n");

}



// PRE: ASTNode pointer and pointer to File
// POST: emits global variables to file
void emit_global_variables(struct ASTNode* p, FILE *fp) {

    if (p == NULL)
        return;

    if (p->myType == A_VARDEC && p->symbol->level == 0) {
        fprintf(fp, "%s:\t\t .space %d\t\t # define global variable\n", p->name, p->size * WSIZE);
        emit_global_variables(p->s1, fp);
        emit_global_variables(p->next, fp);
    }
}



// PRE: ASTNode pointer and pointer to File
// POST: emits global strings to file
void emit_global_strings(struct ASTNode* p, FILE *fp) {
    
    if (p == NULL)
        return;

    if( (p->myType == A_WRITE) && (p->name != NULL) ) {
        p->label = create_label();
        fprintf(fp, "%s:\t.asciiz\t%s\n", p->label, p->name ); // check .asciiz
    }

     emit_global_strings(p->s1, fp);
     emit_global_strings(p->s2, fp);
     emit_global_strings(p->next, fp);
}



// PRE: ASTNode pointer and pointer to File
// POST: emit functions, set up activation record for functions
void emit_fun_head(struct ASTNode *p, FILE *fp) {

    char s[100];
    sprintf(s, "subu $t0 $sp %d\t", p->symbol->mysize * WSIZE);

    fprintf(fp, "\n");
    emit(p->name, "", "Start of function\n", fp);
    function_name = p->name;
    emit("", s, "new stack pointer", fp);                       // t0 will be new stack pointer
    emit("", "sw $ra ($t0)", "store the return address", fp);   // store return address
    emit("", "sw $sp 4($t0)", "store the old sp", fp);          // store old stack pointer
    emit("", "move $sp $t0", "set sp", fp);                     // set stack pointer to new stack pointer
    fprintf(fp, "\n");

    emit_AST(p->s2, fp);
    fprintf(fp, "\n");

    // reset sp and ra end of function

    emit("", "li $v0 0", "return NULL", fp);
    emit("", "lw $ra ($sp)", "reset ra", fp);                  // reset return address
    emit("", "lw $sp 4($sp)", "reset sp to old sp", fp);       // reset stack pointer
    fprintf(fp, "\n");

    // check for main or jump back to call
    if (strcmp(p->name, "main") == 0 ) {
        emit("", "li $v0 10","", fp);
        emit("","syscall","RETURN OUT MIPS", fp); // this is ONLY for main
    }
    
    else {
        emit("", "jr $ra", "go back to function call", fp); // return to call of function
    }    
    
}



// PRE: char * for label, char* for commands, char* for comments, FILE * to write to
// POST: emits necessary MIPS commands to the ASM file
void emit(char *label, char *command, char *comment, FILE *fp) {

    if (strcmp(label, "") == 0){
        
        if (strcmp(comment, "") == 0) 
            fprintf(fp,"\t\t%s\n", command); // comment and label are empty
        
        else 
             fprintf(fp,"\t\t%s\t# %s\n", command, comment); // command and comment
        
    }

    else {

        if (strcmp(comment, "") == 0) 
            fprintf(fp,"%s:\t%s\n", label, command); // comment empty
        
        else 
             fprintf(fp,"%s:\t%s\t# %s\n", label, command, comment); // command and comment and label
        
    }
}



// PRE: ASTNode pointer and pointer to File
// POST: sets up write, emits commands to write either expr or string
void emit_write(struct ASTNode* p, FILE *fp) {

    char s[100];
    sprintf(s, "la $a0, %s\t", p->label);

    if(p->name != NULL) {
        emit("", "li $v0, 4", "printing a string", fp); // command for print string
        emit("", s,"string location print",fp );
        emit("", "syscall", "", fp);
        fprintf(fp, "\n");
    }

    else {
        emit_expr(p->s1, fp); 
        emit("", "li $v0 1", "command for write nums", fp);
        emit("", "syscall\n", "", fp);
    }
}



// PRE: ASTNode pointer and pointer to File
// POST: stores the value of the expr in a0
void emit_expr(struct ASTNode *p, FILE *fp) {

    char s[100];

    if (p == NULL)
        return;

    switch (p->myType) {

        case A_NUM:
            sprintf(s,"li $a0 %d", p->size);
            emit("", s, "load a number expr", fp);  // simply stores an A_NUM into a0
            return;
            

        case A_IDENT:
            emit_ident(p, fp);
            emit("", "lw $a0 ($a0)", "gets value into a0", fp);
            return;

        case A_TRUE:
            sprintf(s,"li $a0 %d", p->size);
            emit("", s, "load a number expr", fp);
            return;
        
        case A_FALSE:
            sprintf(s,"li $a0 %d", p->size);
            emit("", s, "load a number expr", fp);
            return;


        case A_CALL:
            emit_call(p, fp);
            return;

    }// end cases


        // call onto s1 for connected expr statements
        emit_expr(p->s1, fp);
        sprintf(s, "sw $a0, %d($sp)\t", p->symbol->offset * WSIZE);

        emit("", s, "store LHS",fp); 
        emit_expr(p->s2, fp); // call on RHS
        emit("", "move $a1, $a0", "move RHS to b0", fp);

        sprintf(s, "lw $a0, %d($sp)\t", p->symbol->offset * WSIZE);

        // MATH operator emits
        emit("", s, "load a0 with result", fp);
        switch(p->operator) {

            case A_PLUS:
                emit("", "add $a0, $a0, $a1", "ADD expr\n", fp);
                break;

            case A_MINUS:
                emit("", "sub $a0, $a0, $a1", "SUB expr\n", fp);
                break;

            case A_TIMES:
                emit("", "mult $a0 $a1", "\tMULT expr", fp);
                emit("", "mflo $a0", "\tMULT expr", fp);
                break;

            case A_DIVIDE:
                emit("", "div $a0 $a1", "\tDIVIDE expr", fp);
                emit("", "mflo $a0", "\tDIVIDE expr", fp);
                break;

            case A_GREQ:
                emit("", "add $a0, $a0, 1", "GE ADD expr", fp);
                emit("", "slt $a0, $a1, $a0", "GE expr", fp);
                break;   

            case A_LT:
                emit("", "slt $a0, $a0, $a1", "LT expr", fp);
                break;  
                     
            case A_GT: 
                emit("", "sgt $a0, $a0, $a1", "GE expr", fp);
                break;   
                       
            case A_LSEQ: 
                emit("", "add $a1, $a1, 1", "LS ADD to compare expr", fp);
                emit("", "slt $a0, $a0, $a1", "LSEQ expr", fp);
                break;   
                    
            case A_EQUALS: 
                emit("", "slt $t1, $a0, $a1", "EQ expr", fp);
                emit("", "slt $t2, $a1, $a0", "EQ expr", fp);
                emit("", "nor $a0, $t1, $t2", "EQ expr", fp);
                emit("", "andi $a0, 1", "EQ expr final compare", fp);
                break;   
                
            case A_NOTEQ:
                emit("", "slt $t1, $a0, $a1", "EQ expr", fp);
                emit("", "slt $t2, $a1, $a0", "EQ expr", fp);
                emit("", "or $a0, $t1, $t2", "NOTEQ expr", fp);
                break;   
                      
            case A_AND: 
                emit("", "and $a0, $a0, $a1", "store result of AND in a0", fp);
                break;   
                       
            case A_OR:
                emit("", "or $a0, $a0, $a1", "store result of OR in a0", fp);
                break;   
                         
            case A_NOT: 
                 emit("","not $a1, $a0","#Ones compliment", fp);
                 emit("","add $a1, $a1 1","#if we were 0 we are now 0", fp);
                 emit("","srl $a0, $a0 31","# extract sign bit", fp);
                 emit("","srl $a1, $a1 31","# extract sign bit of neg", fp);
                 emit("","or $a0, $a0 $a1","# result 0 if was 0 otherwise a 1", fp);
                 emit("","xor $a0, $a0 1","# flips the bit to get not", fp);
                 break;   
                  
        
        }// end cases
} // end expr



// PRE: ASTNode pointer and pointer to File
// POST: set up and call read for num or ident
void emit_read(struct ASTNode *p, FILE *fp) {

    emit_ident(p->s1, fp);
    emit("", "li $v0 5", "read num", fp);
    emit("", "syscall", "", fp);
    emit("", "sw $v0 ($a0)", " end read statement\n", fp);
}



// PRE: ASTNode pointer and pointer to File
// POST: get address of ident into a0
void emit_ident(struct ASTNode *p, FILE *fp) {

    char s[100];

    if(p->s1 != NULL) {
        emit_expr(p->s1, fp);
        sprintf(s, "sll $t3, $a0, %d", WORD_LOG_SIZE);
        emit("", s, "mult by wordsize", fp);
    }


    if(p->symbol->level == 0) {
        sprintf(s, "la $a0 %s\t", p->name);
        emit("", s, "load global variable", fp);
    }
    
    else {
        sprintf(s, "li $a0 %d",  p->symbol->offset * WSIZE);
        emit("", s, "", fp);
        sprintf(s, "add $a0, $a0, $sp", p->symbol->offset * WSIZE);
        emit("", s, "", fp);        
    }

    if(p->s1 != NULL) // arrays
        emit("", "add $a0, $a0, $t3","add on for arrays", fp);
    

    
}



// PRE: ASTNode pointer and pointer to File
// POST: assign value into a1
void emit_assign(struct ASTNode *p, FILE *fp) {
 
    char s[100];    
    emit_expr(p->s2, fp);


    sprintf(s, "sw $a0 %d($sp)", p->symbol->offset * WSIZE );
    emit("", s, "store RHS", fp);

    emit_ident(p->s1, fp);

    sprintf(s, "lw $a1 %d($sp)", p->symbol->offset * WSIZE );
    emit("", s, "Get RHS", fp);
    emit("", "sw $a1 ($a0)", "assign value", fp);
    fprintf(fp, "\n");
}



// PRE: ASTNode pointer and pointer to File
// POST: create branches for if statement and set up jumps to else
void emit_if_expr(struct ASTNode *p, FILE *fp) {

char s[100];

    char* pStmtOne = create_label();
    char* pStmtTwo = create_label();

    emit_expr(p->s1, fp);
    sprintf(s, "beq $a0 $0 %s", pStmtOne);
    emit("", s, " jump to else", fp);
    emit_AST(p->s2->s1, fp);

    sprintf(s, "j %s", pStmtTwo);
    emit("", s, " IF s1 end", fp);

    sprintf(s, "\n%s", pStmtOne);
    emit(s, "", "start of ELSE", fp);

    if (p->s2->s2 != NULL)
        emit_AST(p->s2->s2, fp);

    sprintf(s, "\n%s", pStmtTwo);
    emit(s, "", "END IF", fp);

}



// PRE:  ASTNode pointer and pointer to File
// POST: set up jumps and call for loops
void emit_while(struct ASTNode* p, FILE *fp) {
    
    char s[100];
    char* labelOne = create_label();
    char* labelTwo = create_label();

    sprintf(s, "%s", labelOne);
    emit(s, "", "JUMP BACK WHILE", fp);

    emit_expr(p->s1, fp);
    sprintf(s, "beq $a0 $0 %s", labelTwo);
    emit("", s, " jump OUT", fp);
    fprintf(fp, "\n");


    emit_AST(p->s2, fp);            

    sprintf(s, "j %s", labelOne);
    emit("", s, " JUMP BACK TO WHILE", fp);

    sprintf(s, "%s", labelTwo);
    emit(s, "", "End of WHILE", fp);

}


// PRE: ASTNode pointer and pointer to File
// POST: stores result of function calls into a0
void emit_call(struct ASTNode *p, FILE *fp) {

    if(p == NULL)
        return;

    char s[100];
    int localCounter = 2;        // all functions start with mem for ra and sp
    struct ASTNode *cur = p->s1; // point to args

    sprintf(s, "subu $t2 $sp %d", p->symbol->mysize * WSIZE);
    emit("", s, "carve out memory for activation record", fp);

    while (cur != NULL) {
        emit_expr(cur->s1, fp); // call on args
        sprintf(s, "sw $a0 %d($t2)", localCounter * WSIZE); // store result in a0
        emit("", s, "store in needed location", fp);
        localCounter+=1;
        cur = cur->next; // move to next param
    }

    sprintf(s, "jal %s", p->name);
    emit("", s, "jump to fucntion",fp);
    fprintf(fp, "\n");
}



// PRE: ASTNode pointer and pointer to File
// POST: move result of expr into v0, reset sp and ra, check for main
void emit_return(struct ASTNode *p, FILE *fp) {

    if(p->s1 != NULL) {
        emit_expr(p->s1, fp);
        emit("", "move $v0 $a0", "move a0 into v0", fp);
    }
    
    else 
        emit("", "li $v0 0", "return NULL", fp);

    emit("", "lw $ra ($sp)", "reset ra", fp);                  // reset return address
    emit("", "lw $sp 4($sp)", "reset sp to old sp", fp);

    if (strcmp(function_name, "main") == 0 ) {   //  check for main
        emit("", "li $v0 10","", fp);
        emit("","syscall","RETURN OUT MIPS", fp); 
    }
    
    else {
        emit("", "jr $ra", "go back to function call", fp); // return 
    }    

}



// PRE: ASTNode pointer and pointer to File
// POST: parse the tree and emit all necessary MIPS commands for written program
void emit_AST(struct ASTNode* p, FILE *fp) {

    if (p == NULL) // base case
        return;


    switch(p->myType) {

        case A_VARDEC: // done in activation record
            emit_AST(p->next, fp);
            break;

        case A_FUNDEC:
            emit_fun_head(p,fp);
            emit_AST(p->next, fp); // s2 because local decs are s1
            break;

        case A_BLOCK:
            // block local decs are done in activation record
            emit_AST(p->s2, fp);
            emit_AST(p->next, fp);
            break;


        case A_WRITE:
            emit_write(p,fp);
            emit_AST(p->next, fp);
            break;

        case A_READ:
            emit_read(p, fp);
            emit_AST(p->next, fp);
            break;

        case A_ASSIGN:
            emit_assign(p, fp);
            emit_AST(p->next, fp);
            break;

        case A_IF_EXPR:
            emit_if_expr(p, fp);
            emit_AST(p->next, fp);
            break;

        case A_WHILE:
            emit_while(p, fp);
            emit_AST(p->next, fp);
            break;

        case A_EXPR_STMT:
            emit_expr(p->s1, fp);
            emit_AST(p->next, fp);
            break;

        case A_RETURN:
            emit_return(p, fp);
            emit_AST(p->next, fp);
            break;

        default: 
            printf("WARNING: emit_AST  error %d.\n", p->myType);
            exit(1);    
    }// end switch    
}



// PRE: 
// POST: create temp label for globals, branches, loops
char * create_label() {
    char hold[100];
    char *s;
    sprintf(hold,"_L%d", STEMP++);
    s=strdup(hold);
    return (s);
}
