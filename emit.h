// header file for emit.c

#ifndef EMIT_H
#define EMIT_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "symtable.h"

FILE *fp;

void emit_header(struct ASTNode* p, FILE *fp);
void emit_AST(struct ASTNode *p, FILE *fp);
void emit_global_strings(struct ASTNode *p, FILE *fp);
void emit_global_variables(struct ASTNode *p, FILE *fp);
void emit_read(struct ASTNode *p, FILE *fp);
void emit_expr(struct ASTNode *p, FILE *fp);
void emit_ident(struct ASTNode *p, FILE *fp);
void emit_selection(struct ASTNode *p, FILE *fp);
void emit(char *label, char *command, char *comment, FILE *fp);
void emit_assign(struct ASTNode *p, FILE *fp);
void emit_if_body(struct ASTNode* p, FILE *fp);
void emit_while(struct ASTNode* p, FILE *fp);
void emit_call(struct ASTNode *p, FILE *fp);

char* create_label();
char* create_branch();

#endif