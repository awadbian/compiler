%{
typedef struct node node;
#include "parser1.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern int yylineno;
%}

%%
   /* KEYWORDS LEXEMES / TYPES */
"bool"      { return BOOL; }
"char*"     { return CHAR_PTR; }
"char"      { return CHAR; }
"int*"      { return INT_PTR; }
"int"       { return INT; }
"real*"     { return REAL_PTR; }
"real"      { return REAL; }
"string"    { return STRING; }

    /*Statement / Loops*/
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"for"       { return FOR; }
"var"       { return VAR; }
"func"      { return FUNC; }
"proc"      { return PROC; }
"return"    { return RETURN; }
"null"      { return NULLTOK; }

     /* OPERATOR LEXEMES */
"&&"    { return AND; }
"||"    { return OR; }
"=="    { return EQ; }
"!="    { return NEQ; }
">="    { return GE; }
"<="    { return LE; }
">"     { return GT; }
"<"     { return LT; }
"="     { return ASSIGN; }
"+"     { return PLUS; }
"-"     { return MINUS; }
"*"     { return MUL; }
"/"     { return DIV; }
"!"     { return NOT; }
"&"     { return AMP; }
"^"     { return CARET; }

     /* OTHER LEXEMES */
";"     { return SEMICOLON; }
":"     { return COLON; }
","     { return COMMA; }
"{"     { return LBRACE; }
"}"     { return RBRACE; }
"("     { return LPAREN; }
")"     { return RPAREN; }
"["     { return LBRACKET; }
"]"     { return RBRACKET; }
"|"     { return BAR; }


   /* LITERALS */

"true"     { yylval.string = strdup(yytext); return BOOLTRUE; }
"false"    { yylval.string = strdup(yytext); return BOOLFALSE; }

   /* string literal */
\"[^\n"]*\"                 { yylval.string = strdup(yytext); return STRING_LITERAL; }

   /* char literal */
\'([^\\'\n]|\\[nrt0\\'\"])\'    { yylval.string = strdup(yytext); return CHAR_LITERAL; } 
   /* real literal */
([0-9]+\.[0-9]*|\.[0-9]+)([eE][+-]?[0-9]+)?   { yylval.string = strdup(yytext); return REAL_LITERAL; }
[0-9]+[eE][+-]?[0-9]+                         { yylval.string = strdup(yytext); return REAL_LITERAL; }

   /* hexadecimal integer literal */
0[xX][0-9A-Fa-f]+           { yylval.string = strdup(yytext); return HEX_LITERAL; }

   /* decimal integer literal */
0|[1-9][0-9]*               { yylval.string = strdup(yytext); return DECIMAL_LITERAL; }

   /* invalid identifier starting with underscore */
_[a-zA-Z0-9_]*    { 
                     printf("Syntax error at line %d near '%s': invalid identifier\n", yylineno, yytext);
                     exit(1); 
                  }

                            
   /* identifier */
[a-zA-Z][a-zA-Z0-9_]*       { yylval.string = strdup(yytext); return IDENTIFIER; }

   /* comments */
"/%"([^%]|\n|%[^/])*"%/"   { /* ignore comments */ }

  /* whitespace */
\n                         { yylineno++; }
[ \t\r]+                    { /* ignore */ }
.   
{ printf("Syntax error at line %d: unexpected character '%s'\n", yylineno, yytext);
  exit(1); 
}

%%

int yywrap() {
    return 1;
}