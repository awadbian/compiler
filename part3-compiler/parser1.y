%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_SYMBOLS 200
#define MAX_VARS 500
#define MAX_FUNCS 200
#define MAX_PARAMS 20


char *symbols[MAX_SYMBOLS];
int symbol_count = 0;
int symbol_scopes[MAX_SYMBOLS];

char *var_names[MAX_VARS];
char *var_types[MAX_VARS];
int var_count = 0;

int var_scopes[MAX_VARS];
int current_scope = 0;

char *string_names_3ac[1000];
int string_lens_3ac[1000];
int string_count_3ac = 0;


char *func_names[MAX_FUNCS];
int func_param_counts[MAX_FUNCS];
char *func_param_types[MAX_FUNCS][MAX_PARAMS];
char *func_return_types[MAX_FUNCS];
int func_count = 0;
int semantic_error = 0;
const char *current_return_type = NULL;


int temp_counter = 0;
int label_counter = 1;

FILE *tac_file = NULL;

char *new_temp()
{
    char buffer[32];
    sprintf(buffer, "t%d", temp_counter++);
    return strdup(buffer);
}

char *new_label()
{
    char buffer[32];
    sprintf(buffer, "L%d", label_counter++);
    return strdup(buffer);
}

void emit(const char *line)
{
    if (tac_file != NULL)
    {
        fprintf(tac_file, "%s\n", line);
    }
}

void emitf(const char *fmt, const char *a, const char *b, const char *c)
{
    if (tac_file != NULL)
    {
        fprintf(tac_file, fmt, a, b, c);
        fprintf(tac_file, "\n");
    }
}


const char *return_type_stack[100];
int return_type_top = 0;

void push_return_type(const char *type)
{
    return_type_stack[return_type_top++] = current_return_type;
    current_return_type = type;
}

void pop_return_type()
{
    if (return_type_top > 0)
        current_return_type = return_type_stack[--return_type_top];
    else
        current_return_type = NULL;
}

void semanticError(const char *msg, const char *name);
void pop_scope_vars();
void pop_scope_symbols();

void add_var(const char *name, const char *type)
{
    for (int i = 0; i < var_count; i++)
    {
        if (strcmp(var_names[i], name) == 0 && var_scopes[i] == current_scope)
    {
        semanticError("variable already declared in this scope", name);
        return;
    }
            
    }

    if (var_count < MAX_VARS)
    {
        var_names[var_count] = strdup(name);
        var_types[var_count] = strdup(type);
        var_scopes[var_count] = current_scope;
        var_count++;
    }
}

const char *get_var_type(const char *name)
{
    int best_scope = -1;
    const char *best_type = NULL;

    for (int i = 0; i < var_count; i++)
    {
        if (strcmp(var_names[i], name) == 0 &&
            var_scopes[i] <= current_scope &&
            var_scopes[i] > best_scope)
        {
            best_scope = var_scopes[i];
            best_type = var_types[i];
        }
    }

    if (best_type != NULL)
        return best_type;

    if (!semantic_error)
    {
        semanticError("variable used before declaration", name);
    }
    return "UNKNOWN";
}

void pop_scope_vars()
{
    while (var_count > 0 && var_scopes[var_count - 1] == current_scope)
    {
        var_count--;
    }
}

int exists_symbol(const char *name)
{
    for (int i = 0; i < symbol_count; i++)
    {
        if (strcmp(symbols[i], name) == 0 &&
            symbol_scopes[i] <= current_scope)
            {
                return 1;

            }
    }
    return 0;
}

void add_symbol(const char *name)
{
    for (int i = 0; i < symbol_count; i++)
    {
        if (strcmp(symbols[i], name) == 0 &&
            symbol_scopes[i] == current_scope)
        {
            semanticError("function/procedure already declared", name);
            return;
        }
    }

    if (symbol_count < MAX_SYMBOLS)
    {
        symbols[symbol_count] = strdup(name);
        symbol_scopes[symbol_count] = current_scope;
        symbol_count++;
    }
}  

void pop_scope_symbols()
{
    while (symbol_count > 0 &&
           symbol_scopes[symbol_count - 1] == current_scope)
    {
        symbol_count--;
    }
}

int yylex(void);
int yyerror(const char *s);
extern int yylineno;
extern char *yytext;
int wrong_main_found = 0;
int main_count = 0; 
int detailed_expr_error = 0;

void semanticError(const char *msg, const char *name)
{
    if (name != NULL)
        printf("Semantic error at line %d: %s '%s'\n", yylineno, msg, name);
    else
        printf("Semantic error at line %d: %s\n", yylineno, msg);

    semantic_error = 1;
}


/* ===== AST Node ===== */
typedef struct node
{
    char *token;
    struct node *left;
    struct node *right;
} node;


void add_var(const char *name, const char *type);
const char *get_var_type(const char *name);
void add_id_list_to_table(node *ids, const char *type);
const char *infer_lhs_type(node *t);
node *mknode(char *token, node *left, node *right);
int ends_with_return(node *t);
void printtree(node *tree, int tabs);
const char *infer_expr_type(node *t);
int check_return_types(node *t, const char *expected_type);
void add_function_info(const char *name, int param_count, const char *return_type);
const char *get_function_return_type(const char *name);
int get_function_param_count(const char *name);
int count_ids(node *t);
int count_params(node *t);
int count_args(node *t);
void save_param_types(const char *func_name, node *params);
void collect_param_types(node *params, char **arr, int *index);
int check_arg_types(const char *func_name, node *args);
void check_assignment_types(node *lhsNode, node *rhsNode);
node *root;
void gen_stmt_3ac(node *t);
char *gen_expr_3ac(node *t);
char *gen_lhs_3ac(node *t);
int is_binary_op(const char *op);
void gen_push_args_3ac(node *args);
int calc_args_bytes(node *args);
int type_size_3ac(const char *type);
char *gen_bool_expr_3ac(node *t);
int calc_func_size_3ac(node *t);
int is_real_literal_3ac(const char *s);
int is_int_number_3ac(const char *s);
int find_string_len_3ac(node *t);
int count_string_ids_3ac(node *t);
void save_string_lengths_3ac(node *t, int len);
int get_string_len_by_name_3ac(const char *name);
void renumber_labels_3ac(const char *filename);
void format_3ac_indentation(const char *filename);

void collect_type_for_ids(node *ids, const char *type, char **arr, int *index)
{
    if (ids == NULL) return;

    if (strcmp(ids->token, "IDS") == 0)
    {
        collect_type_for_ids(ids->left, type, arr, index);
        collect_type_for_ids(ids->right, type, arr, index);
        return;
    }

    arr[*index] = strdup(type);
    (*index)++;
}

void collect_param_types(node *params, char **arr, int *index)
{
    if (params == NULL) return;

    if (strcmp(params->token, "NONE") == 0)
        return;

    if (strcmp(params->token, "PARAMS") == 0)
    {
        collect_param_types(params->left, arr, index);
        collect_param_types(params->right, arr, index);
        return;
    }

    /* single param group like (INT a b) */
    collect_type_for_ids(params->left, params->token, arr, index);
}

void save_param_types(const char *func_name, node *params)
{
    for (int i = 0; i < func_count; i++)
    {
        if (strcmp(func_names[i], func_name) == 0)
        {
            int index = 0;
            collect_param_types(params, func_param_types[i], &index);
            return;
        }
    }
}

int check_arg_types(const char *func_name, node *args)
{
    int func_index = -1;

    for (int i = 0; i < func_count; i++)
    {
        if (strcmp(func_names[i], func_name) == 0)
        {
            func_index = i;
            break;
        }
    }

    if (func_index == -1)
        return 1;

    if (args == NULL || strcmp(args->token, "NONE") == 0)
        return 1;

    int expected_index = 0;

    node *stack[100];
    int top = 0;
    stack[top++] = args;

    while (top > 0)
    {
        node *curr = stack[--top];

        if (strcmp(curr->token, "ARGS_LIST") == 0)
        {
            if (curr->right) stack[top++] = curr->right;
            if (curr->left) stack[top++] = curr->left;
        }
        else
        {
            const char *actual = infer_expr_type(curr);
            const char *expected = func_param_types[func_index][expected_index];

            if (expected != NULL &&
                strcmp(actual, "UNKNOWN") != 0 &&
                strcmp(actual, expected) != 0)
            {
                return 0;
            }

            expected_index++;
        }
    }

    return 1;
}

void add_function_info(const char *name, int param_count, const char *return_type)
{
    for (int i = 0; i < func_count; i++)
    {
        if (strcmp(func_names[i], name) == 0)
            return;
    }

    if (func_count < MAX_FUNCS)
    {
        func_names[func_count] = strdup(name);
        func_param_counts[func_count] = param_count;
        func_return_types[func_count] = strdup(return_type);
        func_count++;
    }
}

const char *get_function_return_type(const char *name)
{
    for (int i = 0; i < func_count; i++)
    {
        if (strcmp(func_names[i], name) == 0)
            return func_return_types[i];
    }

    return "UNKNOWN";
}


int get_function_param_count(const char *name)
{
    for (int i = 0; i < func_count; i++)
    {
        if (strcmp(func_names[i], name) == 0)
            return func_param_counts[i];
    }
    return -1;
}

int count_ids(node *t)
{
    if (t == NULL) return 0;

    if (strcmp(t->token, "IDS") == 0)
        return count_ids(t->left) + count_ids(t->right);

    return 1;
}

int count_params(node *t)
{
    if (t == NULL) return 0;

    if (strcmp(t->token, "NONE") == 0)
        return 0;

    if (strcmp(t->token, "PARAMS") == 0)
        return count_params(t->left) + count_params(t->right);

    return count_ids(t->left);
}

int count_args(node *t)
{
    if (t == NULL) return 0;

    if (strcmp(t->token, "NONE") == 0)
        return 0;

    if (strcmp(t->token, "ARGS_LIST") == 0)
        return count_args(t->left) + count_args(t->right);

    return 1;
}

void add_id_list_to_table(node *ids, const char *type)
{
    if (ids == NULL) return;

    if (strcmp(ids->token, "IDS") == 0)
    {
        add_id_list_to_table(ids->left, type);
        add_id_list_to_table(ids->right, type);
        return;
    }

    add_var(ids->token, type);
}

const char *infer_expr_type(node *t)
{
    if (t == NULL) return "UNKNOWN";

    if (t->left == NULL && t->right == NULL)
    {
        if (strcmp(t->token, "true") == 0 || strcmp(t->token, "false") == 0)
            return "BOOL";

        if (t->token[0] == '\'')
            return "CHAR";

        if (t->token[0] == '"')
            return "STRING";

        if (strcmp(t->token, "NULL") == 0)
            return "NULL";

        if (strncmp(t->token, "0x", 2) == 0 || strncmp(t->token, "0X", 2) == 0)
            return "INT";

       int i = 0, has_dot = 0, has_exp = 0;
int is_number = 0;

if (t->token[0] >= '0' && t->token[0] <= '9')
{
    is_number = 1;
}
else if (t->token[0] == '.' &&
         (t->token[1] >= '0' && t->token[1] <= '9'))
{
    is_number = 1;
}
else if ((t->token[0] == '+' || t->token[0] == '-') &&
         (t->token[1] >= '0' && t->token[1] <= '9'))
{
    is_number = 1;
    i = 1;
}
else if ((t->token[0] == '+' || t->token[0] == '-') &&
         t->token[1] == '.' &&
         (t->token[2] >= '0' && t->token[2] <= '9'))
{
    is_number = 1;
    i = 1;
}


if (is_number)
{
    for (; t->token[i] != '\0'; i++)
    {
        if (t->token[i] == '.') has_dot = 1;
        if (t->token[i] == 'e' || t->token[i] == 'E') has_exp = 1;
    }

    if (has_dot || has_exp)
        return "REAL";

    return "INT";
}

return get_var_type(t->token);
    }

    if (!strcmp(t->token, "!"))
    {
        const char *inner = infer_expr_type(t->left);

        if (!strcmp(inner, "BOOL"))
            return "BOOL";

        detailed_expr_error = 1;
        semanticError("operator ! requires bool operand", NULL);
        return "TYPE_ERROR";
    }

    if (!strcmp(t->token, "UMINUS") || !strcmp(t->token, "UPLUS"))
    {
        const char *inner = infer_expr_type(t->left);
        if (!strcmp(inner, "INT") || !strcmp(inner, "REAL"))
            return inner;
        return "TYPE_ERROR";
    }

    if (!strcmp(t->token, "+") || !strcmp(t->token, "-") ||
    !strcmp(t->token, "*") || !strcmp(t->token, "/"))
    {
        const char *lt = infer_expr_type(t->left);
        const char *rt = infer_expr_type(t->right);
        int left_is_ptr =
            !strcmp(lt, "INT_PTR") || !strcmp(lt, "REAL_PTR") || !strcmp(lt, "CHAR_PTR");

        int right_is_ptr =
            !strcmp(rt, "INT_PTR") || !strcmp(rt, "REAL_PTR") || !strcmp(rt, "CHAR_PTR");

        /* pointer arithmetic is allowed only for CHAR_PTR */

/* char* +/- int */
if ((!strcmp(t->token, "+") || !strcmp(t->token, "-")) &&
    !strcmp(lt, "CHAR_PTR") && !strcmp(rt, "INT"))
{
    return "CHAR_PTR";
}

/* int + char* */
if (!strcmp(t->token, "+") &&
    !strcmp(lt, "INT") && !strcmp(rt, "CHAR_PTR"))
{
    return "CHAR_PTR";
}

/* any other pointer arithmetic is illegal */
if (left_is_ptr || right_is_ptr)
{
    detailed_expr_error = 1;
    semanticError("pointer arithmetic is allowed only for char* with int", NULL);
    return "TYPE_ERROR";
}


        /* regular numeric arithmetic */
        if ((!strcmp(lt, "INT") || !strcmp(lt, "REAL")) &&
        (!strcmp(rt, "INT") || !strcmp(rt, "REAL")))
        {
            if (!strcmp(lt, "REAL") || !strcmp(rt, "REAL"))
                return "REAL";
        return "INT";
        }
    
    detailed_expr_error = 1;
    semanticError("arithmetic operators require int or real operands", NULL);
    return "TYPE_ERROR";
}
    if (!strcmp(t->token, "&&") || !strcmp(t->token, "||"))
    {
        const char *lt = infer_expr_type(t->left);
        const char *rt = infer_expr_type(t->right);

        if (!strcmp(lt, "BOOL") && !strcmp(rt, "BOOL"))
            return "BOOL";

        detailed_expr_error = 1;
        semanticError("logical operators && and || require bool operands", NULL);
        return "TYPE_ERROR";
}

    if (!strcmp(t->token, ">") || !strcmp(t->token, "<") ||
        !strcmp(t->token, ">=") || !strcmp(t->token, "<="))
    {
        const char *lt = infer_expr_type(t->left);
        const char *rt = infer_expr_type(t->right);

        if ((!strcmp(lt, "INT") || !strcmp(lt, "REAL")) &&
            (!strcmp(rt, "INT") || !strcmp(rt, "REAL")))
            return "BOOL";

        detailed_expr_error = 1;
        semanticError("comparison operators require int or real operands", NULL);
        return "TYPE_ERROR";
    }

  if (!strcmp(t->token, "==") || !strcmp(t->token, "!="))
{
    const char *lt = infer_expr_type(t->left);
    const char *rt = infer_expr_type(t->right);

    int left_is_ptr =
        !strcmp(lt, "INT_PTR") || !strcmp(lt, "REAL_PTR") || !strcmp(lt, "CHAR_PTR");

    int right_is_ptr =
        !strcmp(rt, "INT_PTR") || !strcmp(rt, "REAL_PTR") || !strcmp(rt, "CHAR_PTR");

    if (!strcmp(lt, rt) &&
        (!strcmp(lt, "INT") ||
         !strcmp(lt, "REAL") ||
         !strcmp(lt, "BOOL") ||
         !strcmp(lt, "CHAR") ||
         left_is_ptr))
    {
        return "BOOL";
    }

    if ((left_is_ptr && !strcmp(rt, "NULL")) ||
        (!strcmp(lt, "NULL") && right_is_ptr))
    {
        return "BOOL";
    }

    detailed_expr_error = 1;
    semanticError("equality operators require matching comparable types", NULL);
    return "TYPE_ERROR";
}
   if (!strcmp(t->token, "INDEX"))
   {
    const char *arr_type = infer_expr_type(t->left);
    const char *index_type = infer_expr_type(t->right);

    if (strcmp(arr_type, "STRING") != 0)
    {
        detailed_expr_error = 1;
        semanticError("index operator [] can be used only on string", NULL);
        return "TYPE_ERROR";
    }

    if (strcmp(index_type, "INT") != 0)
    {
        detailed_expr_error = 1;
        semanticError("string index must be int", NULL);
        return "TYPE_ERROR";
    }

    return "CHAR";
    }

    if (!strcmp(t->token, "LEN"))
    {
        const char *inner_type = infer_expr_type(t->left);
        if (strcmp(inner_type, "STRING") != 0)
        {
            detailed_expr_error = 1;
            semanticError("| | operator can be used only on string", NULL);
            return "TYPE_ERROR";
        }

        return "INT";
    }


    if (!strcmp(t->token, "&"))
    {
        const char *inner_type = infer_expr_type(t->left);
        if (!strcmp(inner_type, "INT"))
            return "INT_PTR";
            
        if (!strcmp(inner_type, "REAL"))
            return "REAL_PTR";

        if (!strcmp(inner_type, "CHAR"))
            return "CHAR_PTR";

        detailed_expr_error = 1;
        semanticError("& operator can be used only on int, real, char or string[index]", NULL);
        return "TYPE_ERROR";
    }

    if (!strcmp(t->token, "^"))
    {
        const char *inner_type = infer_expr_type(t->left);

        if (!strcmp(inner_type, "INT_PTR"))
            return "INT";

        if (!strcmp(inner_type, "REAL_PTR"))
            return "REAL";

        if (!strcmp(inner_type, "CHAR_PTR"))
            return "CHAR";

        detailed_expr_error = 1;
        semanticError("^ operator can be used only on pointer variables", NULL);
        return "TYPE_ERROR";
    }

    if (!strcmp(t->token, "CALL"))
    {
        return get_function_return_type(t->left->token);
    }

return "UNKNOWN";
}


const char *infer_lhs_type(node *t)
{
    if (t == NULL) return "UNKNOWN";

   if (!strcmp(t->token, "INDEX"))
{
    const char *arr_type = infer_expr_type(t->left);
    const char *index_type = infer_expr_type(t->right);

    if (strcmp(arr_type, "STRING") != 0)
    {
        semanticError("index operator [] can be used only on string", NULL);
        return "TYPE_ERROR";
    }

    if (strcmp(index_type, "INT") != 0)
    {
        semanticError("string index must be int", NULL);
        return "TYPE_ERROR";
    }

    return "CHAR";
}

    if (!strcmp(t->token, "^"))
    {
        const char *inner_type = infer_expr_type(t->left);

        if (!strcmp(inner_type, "INT_PTR"))
            return "INT";

        if (!strcmp(inner_type, "REAL_PTR"))
            return "REAL";

        if (!strcmp(inner_type, "CHAR_PTR"))
            return "CHAR";

        semanticError("^ operator can be used only on pointer variables", NULL);
        return "TYPE_ERROR";
    }


    if (t->left == NULL && t->right == NULL)
        return get_var_type(t->token);

    return "UNKNOWN";
}

void check_assignment_types(node *lhsNode, node *rhsNode)
{
    const char *lhs_type = infer_lhs_type(lhsNode);
    detailed_expr_error = 0;
    const char *rhs_type = infer_expr_type(rhsNode);

    if (strcmp(lhs_type, "UNKNOWN") != 0 &&
        strcmp(rhs_type, "UNKNOWN") != 0 &&
        strcmp(rhs_type, "TYPE_ERROR") != 0 &&
        strcmp(lhs_type, "TYPE_ERROR") != 0 &&
        strcmp(rhs_type, "NULL") != 0 &&
        strcmp(lhs_type, rhs_type) != 0)
    {
        semanticError("assignment type mismatch", NULL);
    }

    if (!strcmp(rhs_type, "TYPE_ERROR") && detailed_expr_error == 0)
    {
        semanticError("invalid expression type in assignment", NULL);
    }

    if (strcmp(rhs_type, "NULL") == 0)
    {
        if (strcmp(lhs_type, "INT_PTR") != 0 &&
            strcmp(lhs_type, "REAL_PTR") != 0 &&
            strcmp(lhs_type, "CHAR_PTR") != 0)
        {
            semanticError("null can be assigned only to pointer variables", NULL);
        }
    }
}

%}  

%union {
    char* string;
    node* n;
}

/*TOKENS*/
/*values*/
%token <string> IDENTIFIER
%token <string> STRING_LITERAL CHAR_LITERAL
%token <string> REAL_LITERAL HEX_LITERAL DECIMAL_LITERAL
%token <string> BOOLTRUE BOOLFALSE

/*Keywords/Types*/
%token BOOL CHAR INT REAL STRING
%token CHAR_PTR INT_PTR REAL_PTR

/*Statements/loops*/
%token IF ELSE WHILE FOR VAR FUNC PROC RETURN NULLTOK

/*Operators*/
%token AND OR EQ NEQ GE LE GT LT ASSIGN
%token PLUS MINUS MUL DIV NOT AMP CARET

/*other lexemes*/
%token SEMICOLON COLON COMMA
%token LBRACE RBRACE LPAREN RPAREN LBRACKET RBRACKET BAR 

%type <n> program
%type <n> decl_list decl
%type <n> proc_decl func_decl
%type <n> param_list param_groups param_group
%type <n> body stmt_list stmt
%type <n> expr
%type <n> type
%type <n> id_list
%type <n> block
%type <n> assignment_stmt return_stmt lhs
%type <n> if_stmt while_stmt
%type <n> var_decl var_decl_list
%type <n> call_expr call_stmt arg_list arg_list_opt
%type <n> for_stmt for_init for_update  
%type <n> block_body


%left OR
%left AND
%left EQ NEQ
%left GT GE LT LE
%left PLUS MINUS
%left MUL DIV
%right NOT
%right UMINUS UPLUS
%right AMP CARET

%%
program
    : decl_list
      {
          root = mknode("CODE", $1, NULL);

          if (wrong_main_found)
          {
            semanticError("procedure name must be 'Main' and not 'main'", "main");
            YYABORT;
          }

          if (main_count == 0)
          {
            semanticError("program must contain exactly one Main procedure", NULL);
            YYABORT;
          }

          if (main_count > 1)
          {
            semanticError("multiple Main procedures are not allowed", "Main");
            YYABORT;
          }

          if (semantic_error)
          {
            YYABORT;
            }
          /*printtree(root, 0);*/
          gen_stmt_3ac(root);
      }
    ;

decl_list
    : decl
      {
          $$ = $1;
      }
    | decl_list decl
      {
          $$ = mknode("DECLS", $1, $2);
      }
    ;

decl
    : proc_decl
      { $$ = $1; }
    | func_decl
      { $$ = $1; }
    ;  

proc_decl
    : PROC IDENTIFIER
      {
        if (strcmp($2, "Main") == 0 && exists_symbol($2))
          {
              semanticError("multiple Main procedures are not allowed", $2);
              YYABORT;
          }
          add_symbol($2);
          current_return_type = "VOID";
          current_scope++;
      }
      LPAREN param_list RPAREN LBRACE body RBRACE
      {
          pop_scope_vars();
          pop_scope_symbols();
          current_scope--;
          current_return_type = NULL;

          add_function_info($2, count_params($5), "VOID");
          save_param_types($2, $5);

          if (strcmp($2, "Main") == 0)
          {
              main_count++;
              if (count_params($5) != 0)
              {
                semanticError("Main procedure must not receive arguments", $2);
                YYABORT;
              }
          }
          else if (strcmp($2, "main") == 0)
          {
              wrong_main_found = 1;
          }

          node *nameNode = mknode($2, NULL, NULL);
          node *argsNode = mknode("ARGS", $5, NULL);
          node *bodyNode = mknode("BODY", $8, NULL);

          $$ = mknode("PROC",
                      nameNode,
                      mknode("PROC_PARTS", argsNode, bodyNode));
      }
    ;

func_decl
    : FUNC IDENTIFIER
      {
          add_symbol($2);
          current_scope++;
      }
      LPAREN param_list RPAREN RETURN type 
       {
          push_return_type($8->token);
      }
      LBRACE body RBRACE
      {
        
          add_function_info($2, count_params($5), $8->token);
          save_param_types($2, $5);

          if (strcmp($8->token, "STRING") == 0)
          {
              semanticError("function return type cannot be string", $2);
          }
          else
          {
              if (!check_return_types($11, $8->token))
              {
                  YYABORT;
              }
          }

          if (!ends_with_return($11))
          {
            semanticError("function must end with return statement", $2);
            YYABORT;
          }

          pop_scope_vars();
          pop_scope_symbols();
          current_scope--;
          pop_return_type();

          node *nameNode = mknode($2, NULL, NULL);
          node *argsNode = mknode("ARGS", $5, NULL);
          node *retNode  = mknode("RET", $8, NULL);
          node *bodyNode = mknode("BODY", $11, NULL);

          $$ = mknode("FUNC",
                      nameNode,
                      mknode("FUNC_PARTS",
                             argsNode,
                             mknode("MORE_PARTS", retNode, bodyNode)));
      }
    ;
    

type
    : BOOL      { $$ = mknode("BOOL", NULL, NULL); }
    | CHAR      { $$ = mknode("CHAR", NULL, NULL); }
    | INT       { $$ = mknode("INT", NULL, NULL); }
    | REAL      { $$ = mknode("REAL", NULL, NULL); }
    | CHAR_PTR  { $$ = mknode("CHAR_PTR", NULL, NULL); }
    | INT_PTR   { $$ = mknode("INT_PTR", NULL, NULL); }
    | REAL_PTR  { $$ = mknode("REAL_PTR", NULL, NULL); }
    | STRING    { $$ = mknode("STRING", NULL, NULL); }

    ;

id_list
    : IDENTIFIER
      {
          $$ = mknode($1, NULL, NULL);
      }
    | id_list COMMA IDENTIFIER
      {
          $$ = mknode("IDS", $1, mknode($3, NULL, NULL));
      }
    ;

param_list
    : /* empty */
      {
          $$ = mknode("NONE", NULL, NULL);
      }
    | param_groups
      {
          $$ = $1;
      }
    ;

param_groups
    : param_group
      {
          $$ = $1;
      }
    | param_groups SEMICOLON param_group
      {
          $$ = mknode("PARAMS", $1, $3);
      }
    ;

param_group
    : id_list COLON type
      {
        if (strcmp($3->token, "STRING") == 0)
        {
            semanticError("parameter type cannot be string", NULL);
        }
        add_id_list_to_table($1, $3->token);
        $$ = mknode($3->token, $1, NULL);
      }
    ;

body
    : /* empty */
      {
          $$ = mknode("EMPTY", NULL, NULL);
      }
    | decl_list
      {
          $$ = $1;
      }
    | var_decl_list
      {
          $$ = $1;
      }
    | stmt_list
      {
          $$ = $1;
      }
    | decl_list var_decl_list
      {
          $$ = mknode("BODY_PARTS", $1, $2);
      }
    | decl_list stmt_list
      {
          $$ = mknode("BODY_PARTS", $1, $2);
      }
    | var_decl_list stmt_list
      {
          $$ = mknode("BODY_PARTS", $1, $2);
      }
    | decl_list var_decl_list stmt_list
      {
          $$ = mknode("BODY_PARTS",
                      $1,
                      mknode("BODY_PARTS", $2, $3));
      }
    ;

block_body
    : /* empty */
      {
          $$ = mknode("EMPTY", NULL, NULL);
      }
    | var_decl_list
      {
          $$ = $1;
      }
    | stmt_list
      {
          $$ = $1;
      }
    | var_decl_list stmt_list
      {
          $$ = mknode("BODY_PARTS", $1, $2);
      }
    ;

var_decl_list
    : var_decl
      {
          $$ = $1;
      }
    | var_decl_list var_decl
      {
          $$ = mknode("VAR_DECLS", $1, $2);
      }
    ;

var_decl
    : VAR IDENTIFIER ASSIGN expr COLON type SEMICOLON
      {
          printf("Syntax error at line %d near '=': assignment is not allowed in variable declaration\n", yylineno);
          YYABORT;
      }
    
    | VAR id_list COLON STRING SEMICOLON
    {
      printf("Syntax error at line %d near 'string': string variables must have size like string[10]\n", yylineno);
      YYABORT;
    }

    | VAR id_list COLON type SEMICOLON
      {
          add_id_list_to_table($2, $4->token);
          $$ = mknode($4->token, $2, NULL);
      }
    | VAR id_list COLON STRING LBRACKET DECIMAL_LITERAL RBRACKET SEMICOLON
      {
          add_id_list_to_table($2, "STRING");
          $$ = mknode("STRING",
                      $2,
                      mknode($6, NULL, NULL));
      }
    ;

stmt_list
    : stmt
      {
          $$ = $1;
      }
    | stmt_list stmt
      {
          $$ = mknode("STMTS", $1, $2);
      }
    ;

stmt
    : block
      {
          $$ = $1;
      }
    | assignment_stmt
      {
          $$ = $1;
      }
    | return_stmt
      {
          $$ = $1;
      }
    | if_stmt
      {
          $$ = $1;
      }
    | while_stmt
      {
          $$ = $1;
      }
    | call_stmt
      {
          $$ = $1;
      }
    | for_stmt
      {
          $$ = $1;
      }
    ;

block
    : LBRACE
      {
          current_scope++;
      }
      block_body RBRACE
      {
          $$ = mknode("BLOCK", $3, NULL);
          pop_scope_vars();
          current_scope--;
      }
    ;


lhs
    : IDENTIFIER
      {
        $$ = mknode($1, NULL, NULL);
      }
    | IDENTIFIER LBRACKET expr RBRACKET
      {
          $$ = mknode("INDEX", mknode($1, NULL, NULL), $3);
      }      
    | CARET IDENTIFIER
      {
          $$ = mknode("^", mknode($2, NULL, NULL), NULL);
      }
    ;

assignment_stmt
    : lhs ASSIGN expr SEMICOLON
      {
          const char *lhs_type = infer_lhs_type($1);
          detailed_expr_error = 0;

          const char *rhs_type = infer_expr_type($3);

          if (strcmp(lhs_type, "UNKNOWN") != 0 &&
          strcmp(rhs_type, "UNKNOWN") != 0 &&
          strcmp(rhs_type, "TYPE_ERROR") != 0 &&
          strcmp(lhs_type, "TYPE_ERROR") != 0 &&
          strcmp(rhs_type, "NULL") != 0 &&
          strcmp(lhs_type, rhs_type) != 0)
          {
             semanticError("assignment type mismatch", NULL);
          }

          if (!strcmp(rhs_type, "TYPE_ERROR") && detailed_expr_error == 0)
          {
            semanticError("invalid expression type in assignment", NULL);
          }

          if (strcmp(rhs_type, "NULL") == 0)
          {
            if (strcmp(lhs_type, "INT_PTR") != 0 &&
            strcmp(lhs_type, "REAL_PTR") != 0 &&
            strcmp(lhs_type, "CHAR_PTR") != 0)
            {
                semanticError("null can be assigned only to pointer variables", NULL);
            } 
          }

          if (!strcmp(lhs_type, "CHAR") && !strcmp(rhs_type, "STRING"))
          {
                semanticError("cannot assign string to char variable", NULL);
          }

          if (!strcmp(lhs_type, "STRING") && !strcmp(rhs_type, "CHAR"))
          {
            semanticError("cannot assign char to string variable", NULL);
          }

          $$ = mknode("=", $1, $3);
      }
      
    | lhs ASSIGN STRING_LITERAL SEMICOLON
      {
          const char *lhs_type = infer_lhs_type($1);

          if (strcmp(lhs_type, "STRING") != 0)
          {
              printf("Syntax error at line %d near '=': cannot assign string literal to non-string variable\n", yylineno);
              YYABORT;
          }

          $$ = mknode("=", $1, mknode($3, NULL, NULL));
      }
    ;
return_stmt
    : RETURN expr SEMICOLON
      {
          if (current_return_type != NULL && strcmp(current_return_type, "VOID") == 0)
          {
              semanticError("return statement is not allowed inside procedure", NULL);
              YYABORT;
          }

          $$ = mknode("RET", $2, NULL);
      }
    ;

arg_list_opt
    : /* empty */
      {
          $$ = mknode("NONE", NULL, NULL);
      }
    | arg_list
      {
          $$ = $1;
      }
    ;

arg_list
    : expr
      {
          $$ = $1;
      }
    | arg_list COMMA expr
      {
          $$ = mknode("ARGS_LIST", $1, $3);
      }
    ;

call_expr
    : IDENTIFIER LPAREN arg_list_opt RPAREN
      {
          if (!exists_symbol($1))
          {
            semanticError("function/procedure called before declaration", $1);
          }

          int expected = get_function_param_count($1);
          int actual = count_args($3);

          if (expected != -1 && expected != actual)
          {
            semanticError("wrong number of arguments in function/procedure call", $1);
          }

          if (!check_arg_types($1, $3))
          {
            semanticError("argument type mismatch in function/procedure call", $1);
          }

          $$ = mknode("CALL",
                      mknode($1, NULL, NULL),
                      $3);
      }
    ;

call_stmt
    : IDENTIFIER LPAREN arg_list_opt RPAREN SEMICOLON
      {
          if (!exists_symbol($1))
          {
            semanticError("function/procedure called before declaration", $1);
          }

          int expected = get_function_param_count($1);
          int actual = count_args($3);

          if (expected != -1 && expected != actual)
          {
            semanticError("wrong number of arguments in function/procedure call", $1);
          }

          if (!check_arg_types($1, $3))
          {
            semanticError("argument type mismatch in function/procedure call", $1);
          }

          $$ = mknode("CALL",
                      mknode($1, NULL, NULL),
                      $3);
      }
    ;

if_stmt
    : IF LPAREN expr RPAREN stmt
      {
          if (strcmp(infer_expr_type($3), "BOOL") != 0)
              semanticError("if condition must be bool", NULL);

          $$ = mknode("IF", $3, $5);
      }
    | IF LPAREN expr RPAREN stmt ELSE stmt
      {
          if (strcmp(infer_expr_type($3), "BOOL") != 0)
              semanticError("if condition must be bool", NULL);

          $$ = mknode("IF-ELSE", $3, mknode("THEN_ELSE", $5, $7));
      }
    ;


while_stmt
    : WHILE LPAREN expr RPAREN stmt
      {
          if (strcmp(infer_expr_type($3), "BOOL") != 0)
              semanticError("while condition must be bool", NULL);

          $$ = mknode("WHILE", $3, $5);
      }
    ;


for_stmt
    : FOR LPAREN for_init SEMICOLON expr SEMICOLON for_update RPAREN stmt
      {
          if (strcmp(infer_expr_type($5), "BOOL") != 0)
              semanticError("for condition must be bool", NULL);

          $$ = mknode("FOR",
                      mknode("FOR_PARTS", $3, mknode("COND_UPD", $5, $7)),
                      $9);
      }
    ;


for_init
    : lhs ASSIGN expr
      {
        check_assignment_types($1, $3);
        $$ = mknode("=", $1, $3);
      }
    | /* empty */
      {
          $$ = mknode("EMPTY", NULL, NULL);
      }
    ;

for_update
    : lhs ASSIGN expr
      {
        check_assignment_types($1, $3);
        $$ = mknode("=", $1, $3);
      }
    | /* empty */
      {
          $$ = mknode("EMPTY", NULL, NULL);
      }
    ;

expr
    : IDENTIFIER
      {
        $$ = mknode($1, NULL, NULL);
      }
    | call_expr
      {
          $$ = $1;
      }
    | DECIMAL_LITERAL
      {
          $$ = mknode($1, NULL, NULL);
      }
    | HEX_LITERAL
      {
          $$ = mknode($1, NULL, NULL);
      }
    | REAL_LITERAL
      {
          $$ = mknode($1, NULL, NULL);
      }
    | CHAR_LITERAL
      {
          $$ = mknode($1, NULL, NULL);
      }
    | STRING_LITERAL
      {
          $$ = mknode($1, NULL, NULL);
      }
    | BOOLTRUE
      {
          $$ = mknode($1, NULL, NULL);
      }
    | BOOLFALSE
      {
          $$ = mknode($1, NULL, NULL);
      }
    | NULLTOK
      {
          $$ = mknode("NULL", NULL, NULL);
      }
    | IDENTIFIER LBRACKET expr RBRACKET
      {
          $$ = mknode("INDEX", mknode($1, NULL, NULL), $3);
      }
    | BAR IDENTIFIER BAR
      {
      $$ = mknode("LEN", mknode($2, NULL, NULL), NULL);
      }
    | LPAREN expr RPAREN
      {
          $$ = $2;
      }
    | expr PLUS expr
      {
          $$ = mknode("+", $1, $3);
      }
    | expr MINUS expr
      {
          $$ = mknode("-", $1, $3);
      }
    | expr MUL expr
      {
          $$ = mknode("*", $1, $3);
      }
    | expr DIV expr
      {
          $$ = mknode("/", $1, $3);
      }
    | expr AND expr
      {
          $$ = mknode("&&", $1, $3);
      }
    | expr OR expr
      {
          $$ = mknode("||", $1, $3);
      }
    | expr EQ expr
      {
          $$ = mknode("==", $1, $3);
      }
    | expr NEQ expr
      {
          $$ = mknode("!=", $1, $3);
      }
    | expr GT expr
      {
          $$ = mknode(">", $1, $3);
      }
    | expr GE expr
      {
          $$ = mknode(">=", $1, $3);
      }
    | expr LT expr
      {
          $$ = mknode("<", $1, $3);
      }
    | expr LE expr
      {
          $$ = mknode("<=", $1, $3);
      }
    | NOT expr
      {
          $$ = mknode("!", $2, NULL);
      }
    | MINUS expr %prec UMINUS
      {
          $$ = mknode("UMINUS", $2, NULL);
      }
    | PLUS expr %prec UPLUS
      {
      $$ = mknode("UPLUS", $2, NULL);
      }
    | AMP IDENTIFIER
      {
          $$ = mknode("&", mknode($2, NULL, NULL), NULL);
      }
    | AMP IDENTIFIER LBRACKET expr RBRACKET
      {
          $$ = mknode("&",
                      mknode("INDEX", mknode($2, NULL, NULL), $4),
                      NULL);
      }
    | CARET IDENTIFIER
      {
        $$ = mknode("^", mknode($2, NULL, NULL), NULL);
      }
    | CARET LPAREN expr RPAREN
      {
        $$ = mknode("^", $3, NULL);
      }
    ;

%%

node *mknode(char *token, node *left, node *right)
{
    node *newnode = (node *)malloc(sizeof(node));
    char *newstr = (char *)malloc(strlen(token) + 1);
    strcpy(newstr, token);

    newnode->token = newstr;
    newnode->left = left;
    newnode->right = right;

    return newnode;
}

int is_leaf(node *t)
{
    return t && t->left == NULL && t->right == NULL;
}

int is_ids_chain(node *t)
{
    if (t == NULL) return 0;
    if (is_leaf(t)) return 1;
    if (!strcmp(t->token, "IDS"))
        return is_ids_chain(t->left) && is_ids_chain(t->right);
    return 0;
}

int is_inline(node *t)
{
    if (t == NULL) return 0;
    if (is_leaf(t)) return 1;

    if (t->right == NULL && is_leaf(t->left))
        return 1;

    if (t->right == NULL && is_ids_chain(t->left))
        return 1;

    if (is_leaf(t->left) && is_leaf(t->right))
        return 1;

    return 0;
}

int ends_with_return(node *t)
{
    if (t == NULL)
        return 0;

    if (strcmp(t->token, "RET") == 0)
        return 1;

    if (strcmp(t->token, "STMTS") == 0)
        return ends_with_return(t->right);

    if (strcmp(t->token, "BODY_PARTS") == 0)
        return ends_with_return(t->right);

    return 0;
}

void print_inline(node *t)
{
    if (t == NULL) return;

    if (!strcmp(t->token, "IDS"))
    {
        print_inline(t->left);
        printf(" ");
        print_inline(t->right);
        return;
    }

    if (is_leaf(t))
    {
        printf("%s", t->token);
        return;
    }

    printf("(%s", t->token);

    if (t->left)
    {
        printf(" ");
        print_inline(t->left);
    }

    if (t->right)
    {
        printf(" ");
        print_inline(t->right);
    }

    printf(")");
}

void printtree(node *tree, int tabs)
{
    int i;

    if (tree == NULL)
        return;

    if (!strcmp(tree->token, "DECLS") ||
        !strcmp(tree->token, "BODY_PARTS") ||
        !strcmp(tree->token, "PROC_PARTS") ||
        !strcmp(tree->token, "FUNC_PARTS") ||
        !strcmp(tree->token, "MORE_PARTS") ||
        !strcmp(tree->token, "PARAMS") ||
        !strcmp(tree->token, "IDS") ||
        !strcmp(tree->token, "COND_UPD") ||
        !strcmp(tree->token, "STMTS") ||
        !strcmp(tree->token, "VAR_DECLS") ||
        !strcmp(tree->token, "THEN_ELSE"))
    {
        printtree(tree->left, tabs);
        printtree(tree->right, tabs);
        return;
    }

    for (i = 0; i < tabs; i++)
        printf("  ");

    if (is_leaf(tree))
    {
        printf("%s\n", tree->token);
        return;
    }

    if (is_inline(tree))
    {
        print_inline(tree);
        printf("\n");
        return;
    }

    /* assignment */
    if (!strcmp(tree->token, "=") && tree->left)
    {
        printf("(= ");
        print_inline(tree->left);
        printf("\n");

        if (tree->right)
            printtree(tree->right, tabs + 1);

        for (i = 0; i < tabs; i++)
            printf("  ");
        printf(")\n");
        return;
    }

    /* return */
    if (!strcmp(tree->token, "RET") && tree->left)
    {
        if (is_inline(tree->left))
        {
            printf("(RET ");
            print_inline(tree->left);
            printf(")\n");
            return;
        }

        printf("(RET\n");
        printtree(tree->left, tabs + 1);

        for (i = 0; i < tabs; i++)
            printf("  ");
        printf(")\n");
        return;
    }

    /* binary operators */
    if ((!strcmp(tree->token, "+") ||
         !strcmp(tree->token, "-") ||
         !strcmp(tree->token, "*") ||
         !strcmp(tree->token, "/") ||
         !strcmp(tree->token, ">") ||
         !strcmp(tree->token, "<") ||
         !strcmp(tree->token, ">=") ||
         !strcmp(tree->token, "<=") ||
         !strcmp(tree->token, "==") ||
         !strcmp(tree->token, "!=") ||
         !strcmp(tree->token, "&&") ||
         !strcmp(tree->token, "||")) && tree->left && tree->right)
    {
        if (is_leaf(tree->left) && is_leaf(tree->right))
        {
            printf("(%s ", tree->token);
            print_inline(tree->left);
            printf(" ");
            print_inline(tree->right);
            printf(")\n");
            return;
        }

        printf("(%s\n", tree->token);
        printtree(tree->left, tabs + 1);
        printtree(tree->right, tabs + 1);

        for (i = 0; i < tabs; i++)
            printf("  ");
        printf(")\n");
        return;
    }

    printf("(%s\n", tree->token);

    if (tree->left)
        printtree(tree->left, tabs + 1);

    if (tree->right)
        printtree(tree->right, tabs + 1);

    for (i = 0; i < tabs; i++)
        printf("  ");

    printf(")\n");
}



int is_type_token(const char *s)
{
    if (s == NULL) return 0;

    return strcmp(s, "INT") == 0 ||
           strcmp(s, "REAL") == 0 ||
           strcmp(s, "BOOL") == 0 ||
           strcmp(s, "CHAR") == 0 ||
           strcmp(s, "STRING") == 0 ||
           strcmp(s, "INT*") == 0 ||
           strcmp(s, "REAL*") == 0 ||
           strcmp(s, "CHAR*") == 0 ||
           strcmp(s, "int") == 0 ||
           strcmp(s, "real") == 0 ||
           strcmp(s, "bool") == 0 ||
           strcmp(s, "char") == 0 ||
           strcmp(s, "string") == 0 ||
           strcmp(s, "int*") == 0 ||
           strcmp(s, "real*") == 0 ||
           strcmp(s, "char*") == 0;
}

int check_return_types(node *t, const char *expected_type)
{
    if (t == NULL) return 1;

if (strcmp(t->token, "FUNC") == 0 ||
    strcmp(t->token, "FUNC_DECL") == 0 ||
    strcmp(t->token, "FUNCTION") == 0)
{
    return 1;
}

    if (strcmp(t->token, "RET") == 0 && t->left != NULL)
    {
        if (is_type_token(t->left->token))
        {
            return 1;
        }

        const char *actual_type = infer_expr_type(t->left);

        if (actual_type == NULL)
        {
            semanticError("invalid expression type in return statement", NULL);
            return 0;
        }

        if (strcmp(actual_type, "TYPE_ERROR") == 0)
        {
            semanticError("invalid expression type in return statement", NULL);
            return 0;
        }

        if (strcmp(actual_type, "UNKNOWN") != 0 &&
            strcmp(actual_type, expected_type) != 0)
        {
            printf("Semantic error at line %d: return type mismatch, expected %s\n",
                   yylineno, expected_type);
            semantic_error = 1;
            return 0;
        }
    }

    if (!check_return_types(t->left, expected_type))
        return 0;

    if (!check_return_types(t->right, expected_type))
        return 0;

    return 1;
}

int yyerror(const char *s)
{
    if (strcmp(yytext, "var") == 0)
    {
        printf("Syntax error at line %d near 'var': variable declarations must appear before statements\n", yylineno);
    }
    else if (strcmp(yytext, ")") == 0)
    {
        printf("Syntax error at line %d near ')': missing identifier or invalid parameter list\n", yylineno);
    }
    else if (strcmp(yytext, "}") == 0)
    {
        printf("Syntax error at line %d near '}': missing statement or invalid block/body structure\n", yylineno);
    }
    else if (strcmp(yytext, "=") == 0)
    {
        printf("Syntax error at line %d near '=': invalid assignment syntax\n", yylineno);
    }
    else if (strcmp(yytext, ",") == 0)
    {
        printf("Syntax error at line %d near ',': invalid identifier list or parameter list\n", yylineno);
    }
    else if (strcmp(yytext, ":") == 0)
    {
        printf("Syntax error at line %d near ':': missing or invalid type declaration\n", yylineno);
    }
    else
    {
        printf("Syntax error at line %d near '%s': %s\n", yylineno, yytext, s);
    }

    return 0;
}

int is_binary_op(const char *op)
{
    return !strcmp(op, "+") ||
           !strcmp(op, "-") ||
           !strcmp(op, "*") ||
           !strcmp(op, "/") ||
           !strcmp(op, "==") ||
           !strcmp(op, "!=") ||
           !strcmp(op, ">") ||
           !strcmp(op, ">=") ||
           !strcmp(op, "<") ||
           !strcmp(op, "<=") ||
           !strcmp(op, "&&") ||
           !strcmp(op, "||");
}

char *gen_expr_3ac(node *t)
{
    if (t == NULL)
        return strdup("");

    if (t->left == NULL && t->right == NULL)
    {
        if (!strcmp(t->token, "true"))
            return strdup("1");

        if (!strcmp(t->token, "false"))
            return strdup("0");

        return strdup(t->token);
    }

    if (is_binary_op(t->token))
    {
       char *left = gen_expr_3ac(t->left);
       char *right = gen_expr_3ac(t->right);

        if (left[0] == '^')
        {
            char *tmpLeft = new_temp();
            fprintf(tac_file, "%s = %s\n", tmpLeft, left);
            left = tmpLeft;
        }

        if (right[0] == '^')
        {
            char *tmpRight = new_temp();
            fprintf(tac_file, "%s = %s\n", tmpRight, right);
            right = tmpRight;
        }

        char *temp = new_temp();
        fprintf(tac_file, "%s = %s %s %s\n", temp, left, t->token, right);
        return temp;
    }

    if (!strcmp(t->token, "UMINUS"))
    {
        char *v = gen_expr_3ac(t->left);
        char *temp = new_temp();

        fprintf(tac_file, "%s = -%s\n", temp, v);

        return temp;
    }

    if (!strcmp(t->token, "UPLUS"))
    {
        return gen_expr_3ac(t->left);
    }

    if (!strcmp(t->token, "!"))
    {
        char *v = gen_expr_3ac(t->left);
        char *temp = new_temp();

        fprintf(tac_file, "%s = !%s\n", temp, v);

        return temp;
    }

    if (!strcmp(t->token, "CALL"))
    {
        char *funcName = t->left->token;
        int bytes = calc_args_bytes(t->right);

        gen_push_args_3ac(t->right);

        char *temp = new_temp();
        fprintf(tac_file, "%s = LCall %s\n", temp, funcName);

        if (bytes > 0)
        {
            fprintf(tac_file, "PopParams %d\n", bytes);
        }

        return temp;
    }

    if (!strcmp(t->token, "INDEX"))
{
    char *index = gen_expr_3ac(t->right);

    char buffer[256];
    sprintf(buffer, "%s[%s]", t->left->token, index);

    return strdup(buffer);
}

if (!strcmp(t->token, "LEN"))
{
    const char *name = t->left->token;

    int len = get_string_len_by_name_3ac(name);

    if (len != -1)
    {
        char buffer[32];
        sprintf(buffer, "%d", len);
        return strdup(buffer);
    }

    return strdup("|?|");
}

if (!strcmp(t->token, "&"))
{
    char *v = gen_expr_3ac(t->left);

    char buffer[256];
    sprintf(buffer, "&%s", v);

    return strdup(buffer);
}

if (!strcmp(t->token, "^"))
{
    char *v = gen_expr_3ac(t->left);

    char buffer[256];
    sprintf(buffer, "^%s", v);

    return strdup(buffer);
}



    return strdup(t->token);
}

char *gen_lhs_3ac(node *t)
{
    if (t == NULL)
        return strdup("");

    if (t->left == NULL && t->right == NULL)
        return strdup(t->token);

    if (!strcmp(t->token, "INDEX"))
    {
        char *index = gen_expr_3ac(t->right);
        char buffer[256];
        sprintf(buffer, "%s[%s]", t->left->token, index);
        return strdup(buffer);
    }

    if (!strcmp(t->token, "^"))
    {
        char buffer[256];
        sprintf(buffer, "^%s", t->left->token);
        return strdup(buffer);
    }

    return strdup(t->token);
}

void gen_stmt_3ac(node *t)
{
    if (t == NULL)
        return;

    if (!strcmp(t->token, "STMTS") ||
        !strcmp(t->token, "BODY_PARTS") ||
        !strcmp(t->token, "VAR_DECLS"))
    {
        gen_stmt_3ac(t->left);
        gen_stmt_3ac(t->right);
        return;
    }

    if (!strcmp(t->token, "EMPTY"))
        return;

        if (!strcmp(t->token, "CODE") || !strcmp(t->token, "DECLS"))
    {
        gen_stmt_3ac(t->left);
        gen_stmt_3ac(t->right);
        return;
    }

    if (!strcmp(t->token, "PROC"))
    {
        char *name = t->left->token;

        if (!strcmp(name, "Main"))
            fprintf(tac_file, "main:\n");
        else
            fprintf(tac_file, "%s:\n", name);

        node *body = t->right->right->left;
        int size = calc_func_size_3ac(body);

        fprintf(tac_file, "BeginFunc %d\n", size);

        gen_stmt_3ac(body);

        fprintf(tac_file, "EndFunc\n");
        return;
    }

    if (!strcmp(t->token, "FUNC"))
    {
        char *name = t->left->token;

        fprintf(tac_file, "%s:\n", name);

        node *body = t->right->right->right->left;
        int size = calc_func_size_3ac(body);

        fprintf(tac_file, "BeginFunc %d\n", size);

        gen_stmt_3ac(body);

        fprintf(tac_file, "EndFunc\n");
        return;
    }

    if (!strcmp(t->token, "IF"))
{

    char *cond = gen_bool_expr_3ac(t->left);
    char *trueLabel = new_label();
    char *endLabel = new_label();
    
    fprintf(tac_file, "if %s Goto %s\n", cond, trueLabel);
    fprintf(tac_file, "Goto %s\n", endLabel);

    fprintf(tac_file, "%s:\n", trueLabel);
    gen_stmt_3ac(t->right);

    fprintf(tac_file, "%s:\n", endLabel);
    return;
}

if (!strcmp(t->token, "IF-ELSE"))
{

    char *cond = gen_bool_expr_3ac(t->left);
    char *trueLabel = new_label();
    char *falseLabel = new_label();
    char *endLabel = new_label();


    fprintf(tac_file, "if %s Goto %s\n", cond, trueLabel);
    fprintf(tac_file, "Goto %s\n", falseLabel);

    fprintf(tac_file, "%s:\n", trueLabel);
    gen_stmt_3ac(t->right->left);

    fprintf(tac_file, "Goto %s\n", endLabel);

    fprintf(tac_file, "%s:\n", falseLabel);
    gen_stmt_3ac(t->right->right);

    fprintf(tac_file, "%s:\n", endLabel);
    return;
}
if (!strcmp(t->token, "WHILE"))
{
    char *startLabel = new_label();

    fprintf(tac_file, "%s:\n", startLabel);

    char *cond = gen_bool_expr_3ac(t->left);

    char *bodyLabel = new_label();
    char *endLabel = new_label();

    fprintf(tac_file, "if %s Goto %s\n", cond, bodyLabel);
    fprintf(tac_file, "Goto %s\n", endLabel);

    fprintf(tac_file, "%s:\n", bodyLabel);
    gen_stmt_3ac(t->right);

    fprintf(tac_file, "Goto %s\n", startLabel);
    fprintf(tac_file, "%s:\n", endLabel);

    return;
}
     
     if (!strcmp(t->token, "CALL"))
{
    char *funcName = t->left->token;
    int bytes = calc_args_bytes(t->right);

    gen_push_args_3ac(t->right);

    fprintf(tac_file, "LCall %s\n", funcName);

    if (bytes > 0)
        fprintf(tac_file, "PopParams %d\n", bytes);

    return;
}

     if (!strcmp(t->token, "FOR"))
{
    node *init = t->left->left;
    node *cond = t->left->right->left;
    node *update = t->left->right->right;
    node *body = t->right;

    char *startLabel = new_label();

    /* init */
    gen_stmt_3ac(init);

    fprintf(tac_file, "%s:\n", startLabel);

    /* condition */
    char *condTemp = gen_bool_expr_3ac(cond);

    char *bodyLabel = new_label();
    char *endLabel = new_label();

    fprintf(tac_file, "if %s Goto %s\n", condTemp, bodyLabel);
    fprintf(tac_file, "Goto %s\n", endLabel);

    /* body */
    fprintf(tac_file, "%s:\n", bodyLabel);
    gen_stmt_3ac(body);

    /* update */
    gen_stmt_3ac(update);

    fprintf(tac_file, "Goto %s\n", startLabel);
    fprintf(tac_file, "%s:\n", endLabel);

    return;
}

    if (!strcmp(t->token, "="))
    {
        char *lhs = gen_lhs_3ac(t->left);
        char *rhs = gen_expr_3ac(t->right);

        fprintf(tac_file, "%s = %s\n", lhs, rhs);
        return;
    }

    if (!strcmp(t->token, "RET"))
    {
        char *v = gen_expr_3ac(t->left);
        fprintf(tac_file, "Return %s\n", v);
        return;
    }

    if (!strcmp(t->token, "BLOCK") || !strcmp(t->token, "BODY"))
    {
        gen_stmt_3ac(t->left);
        return;
    }
}

int type_size_3ac(const char *type)
{
    if (type == NULL)
        return 4;

    if (!strcmp(type, "REAL"))
        return 8;

    return 4;
}

int is_real_literal_3ac(const char *s)
{
    if (s == NULL)
        return 0;

    return strchr(s, '.') != NULL ||
           strchr(s, 'e') != NULL ||
           strchr(s, 'E') != NULL;
}

int calc_args_bytes(node *args)
{
    if (args == NULL || !strcmp(args->token, "NONE"))
        return 0;

    if (!strcmp(args->token, "ARGS_LIST"))
    {
        return calc_args_bytes(args->left) + calc_args_bytes(args->right);
    }

    if (args->left == NULL && args->right == NULL)
    {
        if (is_real_literal_3ac(args->token))
            return 8;
    }

    return 4;
}

void gen_push_args_3ac(node *args)
{
    if (args == NULL || !strcmp(args->token, "NONE"))
        return;

    if (!strcmp(args->token, "ARGS_LIST"))
    {
        /* right to left */
        gen_push_args_3ac(args->right);
        gen_push_args_3ac(args->left);
        return;
    }

    char *v = gen_expr_3ac(args);
    fprintf(tac_file, "PushParam %s\n", v);
}

char *gen_bool_expr_3ac(node *t)
{
    if (t == NULL)
        return strdup("");

    if (!strcmp(t->token, "&&"))
    {
        char *result = new_temp();

        char *rightLabel = new_label();
        char *trueLabel = new_label();
        char *falseLabel = new_label();
        char *endLabel = new_label();

        char *left = gen_bool_expr_3ac(t->left);

        fprintf(tac_file, "if %s Goto %s\n", left, rightLabel);
        fprintf(tac_file, "Goto %s\n", falseLabel);

        fprintf(tac_file, "%s:\n", rightLabel);

        char *right = gen_bool_expr_3ac(t->right);

        fprintf(tac_file, "if %s Goto %s\n", right, trueLabel);
        fprintf(tac_file, "Goto %s\n", falseLabel);

        fprintf(tac_file, "%s:\n", falseLabel);
        fprintf(tac_file, "%s = 0\n", result);
        fprintf(tac_file, "Goto %s\n", endLabel);

        fprintf(tac_file, "%s:\n", trueLabel);
        fprintf(tac_file, "%s = 1\n", result);

        fprintf(tac_file, "%s:\n", endLabel);

        return result;
    }

    if (!strcmp(t->token, "||"))
    {
        char *result = new_temp();

        char *rightLabel = new_label();
        char *trueLabel = new_label();
        char *falseLabel = new_label();
        char *endLabel = new_label();

        char *left = gen_bool_expr_3ac(t->left);

        fprintf(tac_file, "if %s Goto %s\n", left, trueLabel);
        fprintf(tac_file, "Goto %s\n", rightLabel);

        fprintf(tac_file, "%s:\n", rightLabel);

        char *right = gen_bool_expr_3ac(t->right);

        fprintf(tac_file, "if %s Goto %s\n", right, trueLabel);
        fprintf(tac_file, "Goto %s\n", falseLabel);

        fprintf(tac_file, "%s:\n", trueLabel);
        fprintf(tac_file, "%s = 1\n", result);
        fprintf(tac_file, "Goto %s\n", endLabel);

        fprintf(tac_file, "%s:\n", falseLabel);
        fprintf(tac_file, "%s = 0\n", result);

        fprintf(tac_file, "%s:\n", endLabel);

        return result;
    }

    return gen_expr_3ac(t);
}

int count_decl_ids_3ac(node *t)
{
    if (t == NULL)
        return 0;

    if (t->left == NULL && t->right == NULL)
    {
        if (!strcmp(t->token, "INT") ||
            !strcmp(t->token, "REAL") ||
            !strcmp(t->token, "BOOL") ||
            !strcmp(t->token, "CHAR") ||
            !strcmp(t->token, "INT*") ||
            !strcmp(t->token, "CHAR*") ||
            !strcmp(t->token, "REAL*") ||
            !strcmp(t->token, "STRING")||
            !strcmp(t->token, "INT_PTR") ||
            !strcmp(t->token, "CHAR_PTR") ||
            !strcmp(t->token, "REAL_PTR"))
        {
            return 0;
        }

        return 1;
    }

    return count_decl_ids_3ac(t->left) + count_decl_ids_3ac(t->right);
}

int calc_func_size_3ac(node *t)
{
    if (t == NULL)
        return 0;

    if (!strcmp(t->token, "INT") ||
    !strcmp(t->token, "BOOL") ||
    !strcmp(t->token, "CHAR") ||
    !strcmp(t->token, "INT*") ||
    !strcmp(t->token, "CHAR*") ||
    !strcmp(t->token, "REAL*") ||
    !strcmp(t->token, "INT_PTR") ||
    !strcmp(t->token, "CHAR_PTR") ||
    !strcmp(t->token, "REAL_PTR"))
    {
        return count_decl_ids_3ac(t->left) * 4;
    }

    if (!strcmp(t->token, "REAL"))
    {
        return count_decl_ids_3ac(t->left) * 8;
    }

if (!strcmp(t->token, "STRING"))
{
    int len = find_string_len_3ac(t);
    int count = count_string_ids_3ac(t);

    save_string_lengths_3ac(t, len);

    return count * len;
}

    return calc_func_size_3ac(t->left) + calc_func_size_3ac(t->right);
}


int is_int_number_3ac(const char *s)
{
    if (s == NULL || *s == '\0')
        return 0;

    for (int i = 0; s[i]; i++)
    {
        if (s[i] < '0' || s[i] > '9')
            return 0;
    }

    return 1;
}

int find_string_len_3ac(node *t)
{
    if (t == NULL)
        return 0;

    if (t->left == NULL && t->right == NULL)
    {
        if (is_int_number_3ac(t->token))
            return atoi(t->token);

        return 0;
    }

    int leftLen = find_string_len_3ac(t->left);
    if (leftLen > 0)
        return leftLen;

    return find_string_len_3ac(t->right);
}

int count_string_ids_3ac(node *t)
{
    if (t == NULL)
        return 0;

    if (t->left == NULL && t->right == NULL)
    {
        if (is_int_number_3ac(t->token))
            return 0;

        return 1;
    }

    return count_string_ids_3ac(t->left) + count_string_ids_3ac(t->right);
}

void save_string_lengths_3ac(node *t, int len)
{
    if (t == NULL)
        return;

    if (t->left == NULL && t->right == NULL)
    {
        if (!is_int_number_3ac(t->token))
        {
            string_names_3ac[string_count_3ac] = strdup(t->token);
            string_lens_3ac[string_count_3ac] = len;
            string_count_3ac++;
        }
        return;
    }

    save_string_lengths_3ac(t->left, len);
    save_string_lengths_3ac(t->right, len);
}

int get_string_len_by_name_3ac(const char *name)
{
    for (int i = string_count_3ac - 1; i >= 0; i--)
    {
        if (!strcmp(string_names_3ac[i], name))
            return string_lens_3ac[i];
    }

    return -1;
}

void renumber_labels_3ac(const char *filename)
{
    FILE *in = fopen(filename, "r");
    if (in == NULL)
        return;

    char *lines[5000];
    int line_count = 0;

    char buffer[1024];

    while (fgets(buffer, sizeof(buffer), in))
    {
        lines[line_count] = strdup(buffer);
        line_count++;
    }

    fclose(in);

    int old_labels[1000];
    int new_labels[1000];
    int label_count = 0;

    for (int i = 0; i < line_count; i++)
    {
        char *p = lines[i];

        while (*p == ' ' || *p == '\t')
            p++;

        if (*p == 'L' && isdigit((unsigned char)p[1]))
        {
            int old_num = 0;
            int j = 1;

            while (isdigit((unsigned char)p[j]))
            {
                old_num = old_num * 10 + (p[j] - '0');
                j++;
            }

            if (p[j] == ':')
            {
                int exists = 0;

                for (int k = 0; k < label_count; k++)
                {
                    if (old_labels[k] == old_num)
                    {
                        exists = 1;
                        break;
                    }
                }

                if (!exists)
                {
                    old_labels[label_count] = old_num;
                    new_labels[label_count] = label_count + 1;
                    label_count++;
                }
            }
        }
    }

    FILE *out = fopen(filename, "w");
    if (out == NULL)
        return;

    for (int i = 0; i < line_count; i++)
    {
        char *p = lines[i];

        while (*p)
        {
            if (*p == 'L' && isdigit((unsigned char)*(p + 1)))
            {
                int old_num = 0;
                char *start = p;

                p++;

                while (isdigit((unsigned char)*p))
                {
                    old_num = old_num * 10 + (*p - '0');
                    p++;
                }

                int new_num = old_num;

                for (int k = 0; k < label_count; k++)
                {
                    if (old_labels[k] == old_num)
                    {
                        new_num = new_labels[k];
                        break;
                    }
                }

                fprintf(out, "L%d", new_num);
            }
            else
            {
                fputc(*p, out);
                p++;
            }
        }

        free(lines[i]);
    }

    fclose(out);
}

void format_3ac_indentation(const char *filename)
{
    FILE *in = fopen(filename, "r");
    if (in == NULL)
        return;

    char *lines[5000];
    int line_count = 0;
    char buffer[1024];

    while (fgets(buffer, sizeof(buffer), in))
    {
        lines[line_count++] = strdup(buffer);
    }

    fclose(in);

    FILE *out = fopen(filename, "w");
    if (out == NULL)
        return;

    int first_function = 1;

    for (int i = 0; i < line_count; i++)
    {
        char *line = lines[i];

        while (*line == ' ' || *line == '\t')
            line++;

        int len = strlen(line);
        while (len > 0 && (line[len - 1] == '\n' || line[len - 1] == '\r'))
        {
            line[len - 1] = '\0';
            len--;
        }

        if (len == 0)
        {
            free(lines[i]);
            continue;
        }

        /* function label: foo: / main: */
        if (line[len - 1] == ':' && line[0] != 'L')
        {
            if (!first_function)
                fprintf(out, "\n\n");

            fprintf(out, "%s\n", line);
            first_function = 0;
            free(lines[i]);
            continue;
        }

        /* regular label: L1: */
        if (line[0] == 'L' && line[len - 1] == ':')
        {
            if (i + 1 < line_count)
            {
                char *next = lines[i + 1];

                while (*next == ' ' || *next == '\t')
                    next++;

                int nextLen = strlen(next);
                while (nextLen > 0 && (next[nextLen - 1] == '\n' || next[nextLen - 1] == '\r'))
                {
                    next[nextLen - 1] = '\0';
                    nextLen--;
                }

                if (nextLen > 0 &&
                    !(next[0] == 'L' && next[nextLen - 1] == ':') &&
                    !(next[nextLen - 1] == ':' && next[0] != 'L'))
                {
                    fprintf(out, "    %s %s\n", line, next);
                    free(lines[i]);
                    free(lines[i + 1]);
                    i++;
                    continue;
                }
            }

            fprintf(out, "    %s\n", line);
            free(lines[i]);
            continue;
        }

        /* regular instruction */
        fprintf(out, "        %s\n", line);
        free(lines[i]);
    }

    fclose(out);
}
int main()
{
    tac_file = fopen("output.3ac", "w");

    if (tac_file == NULL)
    {
        printf("Error: cannot open output.3ac\n");
        return 1;
    }

    int result = yyparse();

    fclose(tac_file);

  if (result != 0 || semantic_error)
{
    tac_file = fopen("output.3ac", "w");

    if (tac_file != NULL)
    {
        fprintf(tac_file, "Compilation failed due to syntax or semantic errors.\n");
        fclose(tac_file);
    }

    return 1;
}

renumber_labels_3ac("output.3ac");
format_3ac_indentation("output.3ac");

return 0;
}