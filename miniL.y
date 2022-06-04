/* cs152-miniL phase3 */

%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string>
  #include <vector>
  #include <iostream>
  #include <sstream>
  #include <fstream>
  #include "lib.h"
  #include <unordered_set>

  extern FILE *yyin;
  extern int yylex(void);
  void yyerror(const char *msg);
  extern int curLn;
  extern int curPos;
  //for declarations
  int decl_int = 0;
  std::string decl_str = "";
  std::unordered_set<std::string> reservedWords = {
    "function", "beginparams", "endparams", "end_params", 
    "beginlocals", "endlocals", "beginbody", "endbody", "integer", 
    "array", "of", "if", "then", "endif", "else", "while",
    "do", "beginloop", "endloop", "continue", "break", "read", 
    "write", "not", "true", "false", "return",
  };

  enum Type { Integer, Array };

  struct Symbol {
    std::string name;
    Type type;
  };

  struct Function {
    std::string name;
    std::vector<Symbol> declarations;
  };

  std::vector <Function> symbol_table;
  std::stringstream out;
  std::ofstream file("./testmil/out.mil");

  Function *get_function() {
    int last = symbol_table.size()-1;
    return &symbol_table[last];
  }

  bool find(std::string &value, Type type) {
    Function *f = get_function();
    if(f->declarations.size() < 1){
      return false;
    }
    for(int i=0; i < f->declarations.size(); i++) {
      Symbol *s = &f->declarations[i];
      if (s->name == value && s->type == type) {
        return true;
      }
    }
    return false;
  }

  void add_function_to_symbol_table(std::string &value) {
    Function f; 
    f.name = value; 
    if(reservedWords.find(value)!= reservedWords.end()){
      std::string temp = "Error: function name can not be reserved word \"" + value + "\"";
      yyerror(temp.c_str());
    }
    symbol_table.push_back(f);
  }

  void add_variable_to_symbol_table(std::string &value, Type t) {
    Symbol s;
    s.name = value;
    s.type = t;
    Function *f = get_function();
    if(reservedWords.find(value)!= reservedWords.end()){
      std::string temp = "Error: variable name can not be reserved word \"" + value + "\"";
      yyerror(temp.c_str());
    }
    f->declarations.push_back(s);
  }

  bool findFunction(std::string &name){
    for(int i=0; i<symbol_table.size(); i++) {
      if(symbol_table[i].name.c_str() == name){
        return true;
      }
    }
    return false;
  }

  void print_symbol_table(void) {
    printf("symbol table:\n");
    printf("--------------------\n");
    for(int i=0; i<symbol_table.size(); i++) {
      printf("function: %s\n", symbol_table[i].name.c_str());
      for(int j=0; j<symbol_table[i].declarations.size(); j++) {
        printf("  locals: %s\n", symbol_table[i].declarations[j].name.c_str());
      }
    }
    printf("--------------------\n");
  }
%}

%union {
  int int_val;
  char* ident;
  struct CodeNode *node;
}

%error-verbose

%start program

%token <int_val> NUMBER
%token <ident> IDENT
%type <node> Function Functions Declaration Declarations Statement Statements funcName var Term expression expressionLoop Multiexpression ece comp boolExpress Identifiers RelationExpresses RelationExpress

%token FUNCTION BEGINPARAMS ENDPARAMS BEGINLOCALS ENDLOCALS BEGINBODY ENDBODY 
%token INTEGER ARRAY ENUM
%token OF IF THEN ENDIF ELSE
%token WHILE DO BEGINLOOP ENDLOOP CONTINUE BREAK
%token READ WRITE
%token AND OR TRUE FALSE RETURN 
%token SEMICOLON COLON COMMA

%token LPAREN RPAREN 
%token L_SQUARE_BRACKET R_SQUARE_BRACKET
%token NEG 
%token MULT DIV MOD 
%token ADD SUB 
%token LT LTE GT GTE EQ NEQ
%token NOT
%token ASSIGN
%left L_PAREN R_PAREN 
%left L_SQUARE_BRACKET R_SQUARE_BRACKET 
%right NEG
%left MULT DIV MOD 
%left ADD SUB 
%left LT LTE GT GTE EQ NEQ 
%right NOT
%right ASSIGN

%% 

/* %start program */

program:      Functions{
                //printf("program -> Functions\n");
                CodeNode *node = $1;  
                std::string main = "main";
                if(!findFunction(main)){
                    std::string temp = "Error: no main function";
                    yyerror(temp.c_str());
                }
                out << node->code << std::endl;
                }
                ;

Functions:    {
                //printf("Functions -> epsilon\n");
                CodeNode *node = new CodeNode;
                $$ = node;
                }
                | Function Functions{
                          //printf("Functions -> Function Functions\n");
                          CodeNode *node1 = $1;
                          CodeNode *node2 = $2;
                          CodeNode *node = new CodeNode;
                          node->code = node1->code + node2->code;
                          $$ = node;
                      }
                      ;

funcName:              FUNCTION IDENT{
                        CodeNode *node = new CodeNode;
                        std::string func_name = $2;
                        add_function_to_symbol_table(func_name);
                        node->code = "func "+ func_name + "\n";
                        $$ = node;
                      }

Function:     funcName SEMICOLON BEGINPARAMS Declarations ENDPARAMS BEGINLOCALS Declarations ENDLOCALS BEGINBODY Statements ENDBODY{
                        // printf("function -> FUNCTION IDENT SEMICOLON" 
                        //         " BEGIN_PARAMS declarations END_PARAMS"
                        //         " BEGIN_LOCALS declarations END_LOCALS"
                        //         " BEGIN_BODY statements END_BODY\n");
                        CodeNode *node = new CodeNode;
                        CodeNode *node1 = $1;
                        CodeNode *param = $4;
                        CodeNode *locals = $7;
                        decl_str = "";
                        decl_int = 0;
                        CodeNode *body = $10; 

                        if(body->code.find("continue") != std::string::npos){
                          std::string temp = "Error use of \"continue\" outside of loop body";
                          yyerror(temp.c_str());
                        }
                        else if(body->code.find("break") != std::string::npos){
                          std::string temp = "Error use of \"break\" outside of loop body";
                          yyerror(temp.c_str());
                        }

                        node->code = node1->code + param->code + param->name + locals->code + body->code + "endfunc\n\n";
                        $$ = node;
                      }
                      ; 

Declarations: {
                // printf("declarations -> epsilon\n");
                CodeNode *node = new CodeNode;
                $$ = node;
                }
              | Declaration SEMICOLON Declarations{
                          //printf("declarations -> declaration SEMICOLON delcarations\n");
                          CodeNode *node1 = $1;
                          CodeNode *node2 = $3;
                          CodeNode *node = new CodeNode;
                          node->code = node1->code + node2->code;
                          node->name = decl_str;
                          $$ = node;
                      }
                      ;

Declaration:	IDENT COLON INTEGER{
                         //printf("declaration -> IDENT %s COLON INTEGER\n", $1);
                        std::string ident = $1;
                        //printf("hello1\n");                     
                        if(find(ident, Array) || find(ident, Integer)){
                          std::string temp = "Error redeclaration of variable \"" + ident + "\"";
                          yyerror(temp.c_str());
                        }
                        //printf("hello2\n");   
                        Type t = Integer;
                        add_variable_to_symbol_table(ident, t);

                        CodeNode *node = new CodeNode;
                        node->code = ". " + ident + "\n";
                        $$ = node;
                        decl_str += "= " + ident + ", $" + std::to_string(decl_int) + "\n";
                        decl_int ++;
                      }
              | IDENT COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER{
                            // printf("declaration -> IDENT COLON ARRAY L_SQUARE_BRACKET"
                            //        " NUMBER R_SQUARE_BRACKET OF INTEGER\n");
                            std::string ident = $1;
                            int size = $5;

                            if(size <= 0){
                              std::string temp = "Error array size must be > 0. Cannot declare array of size (" + std::to_string(size) + ")";
                              yyerror(temp.c_str());
                            }

                            if(find(ident, Array) || find(ident, Integer)){
                              std::string temp = "Error redeclaration of variable \"" + ident + "\"";
                              yyerror(temp.c_str());
                            }
                            Type t = Array;

                            add_variable_to_symbol_table(ident, t);
                            CodeNode *node = new CodeNode;
                            node->code = ".[] " + ident + ", " + std::to_string(size) + "\n";
                            node->isArray = true;
                            $$ = node;
                            decl_str += "= " + ident + ", $" + std::to_string(decl_int) + "\n";
                            decl_int ++;
                      };

Identifiers:	IDENT
              //{printf("Identifiers->Ident %s\n", $1);}
              | IDENT COMMA Identifiers
              //{printf("Identifiers->Ident COMMA Identifiers\n");}
              ;

Statements:	  Statement SEMICOLON Statements{
                          //printf("statements -> statement SEMICOLON statements\n");
                          CodeNode *node1 = $1;
                          CodeNode *node2 = $3;
                          CodeNode *node = new CodeNode;
                          node->code = node1->code + node2->code;
                          $$ = node;
                      }
              | Statement SEMICOLON{
                        //printf("statements -> statement SEMICOLON\n");
                        CodeNode *node = $1;
                        $$ = node;
                      }
              | Statement error {yyparse();}
              ;

Statement:    var ASSIGN expression{
                        //printf("statement -> var ASSIGN expression\n");
                        CodeNode *node = new CodeNode; 
                        CodeNode *node1 = $1;
                        CodeNode *node2 = $3;
                        node->code = node1->code + node2->code;
                        
                        if(node1->isArray)
                          node->code += "[]= " + node1->name + ", " + node1->arrayIndex + ", " + node2->name + "\n";
                        else
                          node->code += "= " + node1->name + ", " + node2->name + "\n";\
                        $$ = node; 
                      }
              |IF boolExpress THEN Statements  ENDIF{
                          //printf("statement -> IF bool_exp THEN statements ENDIF\n");
                          CodeNode *node = new CodeNode;
                          CodeNode *node1 = $2;
                          std::string if_true = Generator::make_label();
                          std::string endif = Generator::make_label();
                          //node->code = node1->code;
                          //printf("hello3\n");  
                          node->code += "?:= " + if_true + ", " + $2->name + "\n";
                          //printf("hello3.5\n");
                          node->code += ":= " + endif + "\n";
                          node->code += ": " + if_true + "\n"; 
                          node->code += $4->code;  
                          node->code += ": " + endif + "\n";
                          $$ = node;  
                          //printf("hello3\n");  
                      }
              | IF boolExpress THEN Statements ELSE Statements ENDIF{
                          //printf("statement -> IF bool_exp THEN statements ELSES statements ENDIF\n");
                          CodeNode *node = new CodeNode;
                          std::string if_true = Generator::make_label();
                          std::string else_ = Generator::make_label();
                          std::string endif = Generator::make_label();
                          node->code = $2->code;
                          node->code += "?:= " + if_true + ", " + $2->name + "\n";
                          node->code += ":= " + else_ + "\n";
                          node->code += ": " + if_true + "\n";
                          node->code += $4->code;
                          node->code += ":= " + endif + "\n";
                          node->code += ": " + else_ + "\n";
                          node->code += $6->code;
                          node->code += ": " + endif + "\n";
                          $$ = node;
                      }		 
              |WHILE boolExpress BEGINLOOP Statements ENDLOOP{
                          //printf("statement -> WHILE bool_exp BEGINLOOP statements ENDLOOP\n");
                          LoopNode *node = new LoopNode;
                          CodeNode *statements = $4;
                          std::string beginloop = Generator::make_label();
                          std::string loopbody = Generator::make_label();
                          std::string endloop = Generator::make_label();
                          std::string flowC = ":= " + beginloop;
                          std::string flowB = ":= " + endloop;
                          
                          // Replace flow
                          node->addFlow(statements->code, Continue, flowC);
                          node->addFlow(statements->code, Break, flowB);

                          node->code += ": " + beginloop + "\n";
                          node->code += $2->code;
                          node->code += "?:= " + loopbody + ", " + $2->name + "\n";
                          node->code += ":= " + endloop + "\n";
                          node->code += ": " + loopbody + "\n";
                          node->code += statements->code;
                          node->code += ":= " + beginloop + "\n";
                          node->code += ": " + endloop + "\n";
                          $$ = node;
                      }
              |DO BEGINLOOP Statements ENDLOOP WHILE boolExpress{
                          //printf("statement -> DO BEGINLOOP statements ENDLOOP WHILE bool_exp\n");
                          LoopNode *node = new LoopNode;
                          CodeNode *statements = $3;
                          std::string beginloop = Generator::make_label();
                          std::string endloop = Generator::make_label();

                          std::string flowC = ":= " + beginloop;
                          std::string flowB = ":= " + endloop;
                          
                          // Replace flow
                          node->addFlow(statements->code, Continue, flowC);
                          node->addFlow(statements->code, Break, flowB);

                          node->code = ": " + beginloop + "\n";
                          node->code += $3->code;
                          node->code += $6->code;
                          node->code += "?:= " + beginloop + ", " + $6->name + "\n";
                          node->code += ": " + endloop + "\n";
                          $$ = node;
                      }
              | READ var varLoop{
                          //printf("statement -> READ var\n");
                          CodeNode *node1 = $2;
                          CodeNode *node = new CodeNode;
                          if(node1->isArray){
                            std::string temp = Generator::make_var();
                            node->code = ". " + temp + "\n";
                            node->code += "=[] " + temp + ", " + node1->name + ", " + node1->arrayIndex + "\n";
                            node->code = ".< " + temp  + "\n";
                          }
                          else
                            node->code += ".< " + node1->name + "\n"; 
                          $$ = node;
                      }
              | WRITE var varLoop{ 
                          //printf("statement -> WRITE var\n");
                          CodeNode *node1 = $2;
                          CodeNode *node = new CodeNode;
                          if(node1->isArray){
                            std::string temp = Generator::make_var();
                            node->code = ". " + temp + "\n";
                            node->code += "=[] " + temp + ", " + node1->name + ", " + node1->arrayIndex + "\n";
                            node->code += ".> " + temp + "\n";
                          }
                          else
                            node->code = ".> " + node1->name + "\n";
                          $$ = node;
                      }
              | CONTINUE{
                          //printf("statement -> CONTINUE\n");
                          // $$->code += "continue\n";
                          CodeNode *node = new CodeNode;
                          node->code = "break\n";
                          $$ = node;
                      }
              | RETURN expression{
                          //printf("hello4\n");  
                          //printf("statement -> RETURN expression\n");
                          CodeNode *node = new CodeNode;
                          CodeNode *node1 = $2;
                          node->code = node1-> code + "ret " + node1->name + "\n";
                          $$ = node;
                      }
                      ;



varLoop:	//{printf("varLoop->epsilon\n");}
		      | COMMA var varLoop
		      //{printf("varLoop-> COMMA var varLoop\n");}
		      ;

var:		IDENT{
                        //printf("var -> IDENT %s\n", $1);
                        std::string var = $1;
                        CodeNode *node = new CodeNode();
                        node->name = $1;
                        if(!find(var, Integer)){
                          std::string temp = "Error cannot find variable \"" + var + "\" of type INTEGER in the symbol table";
                          yyerror(temp.c_str());
                        }
                        $$ = node;
                      }
	  	  | IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET{
                          //printf("var -> IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET\n");
                          std::string var = $1;
                          CodeNode *node = new CodeNode();
                          CodeNode *node1 = $3;
                          node->name = $1;
                          if(!find(var, Array)){
                            std::string temp = "Error cannot find variable \"" + var + "\" of type ARRAY in the symbol table";
                            yyerror(temp.c_str());
                          }
                          node->isArray = true;
                          node->arrayIndex = node1->name;
                          $$ = node;
                      }
		                  ;

boolExpress:	  RelationExpresses{
              //{printf("BoolExpress->RelationExpresses\n");
              CodeNode *node = new CodeNode;
              CodeNode *node1 = $1;
              node->code = node1->code;
              $$ = node;
              }
              | RelationExpresses OR RelationExpresses{
              //{printf("BoolExpress->RelationExpresses OR RelationExpresses\n");
              CodeNode *node = new CodeNode;
              CodeNode *node1 = $1;
              CodeNode *node2 = $3;
              node->code = node1->code + node2->code;
              $$ = node;
              }
              ;

RelationExpresses:	RelationExpress{
	      	      //{printf("RelationExpresses->RelationExpress\n");
                CodeNode *node = new CodeNode;
                CodeNode *node1 = $1;
                //printf("hello3.5\n");
                node->code = node1->code;
                //printf("hello3\n");
                
                $$ = node;
              }
		            | RelationExpress AND RelationExpresses {
                //{printf("RelationExpresses->RelationExpresses AND RelationExpress\n");
                CodeNode *node = new CodeNode;
                CodeNode *node1 = $1;
                CodeNode *node2 = $3;
                //printf("hello3.5\n");
                node->code = node1->code + node2->code;
                //printf("hello3\n");
                $$ = node;
                }
                ;

RelationExpress: ece
                {//printf("RelationExpress->ece\n");
                CodeNode *node = new CodeNode;
                CodeNode *node1 = $1;
                node->code = node1->code;
                $$ = node;
                }
                | TRUE
                //{printf("RelationExpress->TRUE\n");}
                | NOT TRUE
                //{printf("RelationExpress-> NOT TRUE\n");}
                | FALSE
                //{printf("RelationExpress->FALSE\n");}
                | NOT FALSE
                //{printf("RelationExpress->NOT FALSE\n");}
                | LPAREN boolExpress RPAREN{
                //{printf("RelationExpress->LPAREN BoolExpress RPAREN\n");
                CodeNode *node = new CodeNode;
                CodeNode *node1 = $2;
                node->code = node1->code;
                $$ = node;
                }
                | NOT LPAREN boolExpress RPAREN
                //{printf("RelationExpress->LPAREN BoolExpress RPAREN\n");}
                ;

ece:		        expression comp expression{
                        //printf("bool_exp ->  expression comp expression\n");
                        std::string temp = Generator::make_var();
                          CodeNode *node = new CodeNode;
                          CodeNode *node2 = $1; 
                          CodeNode *node3 = $2;
                          CodeNode *node4 = $3;
                          node->code += node2->code + node4->code;
                          node->code += ". " + temp + "\n";
                          node->code += node3->code + " " + temp + ", " + node2->name + ", " + node4->name + "\n";
                          //std::cout << node->code << std::endl;
                          node->name = temp;
                          $$ = node;
                          }
                          ;

comp:		        EQ{
                        //printf("comp -> EQ\n");
                        CodeNode *node = new CodeNode;
                        node->code = "==";
                        $$ = node;
                      }
                | NEQ{
                          //printf("comp -> NEQ\n");
                          CodeNode *node = new CodeNode;
                        node->code = "!=";
                        $$ = node;
                      }
                | LT{
                          //printf("comp -> LT\n");
                          CodeNode *node = new CodeNode;
                        node->code = "<";
                        $$ = node;
                      }
                | GT{
                          //printf("comp -> GT\n");
                          CodeNode *node = new CodeNode;
                        node->code = ">";
                        $$ = node;
                      }
                | LTE{
                          //printf("comp -> LTE\n");
                          CodeNode *node = new CodeNode;
                        node->code = "<=";
                        $$ = node;
                      }
                | GTE{
                         // printf("comp -> GTE\n");
                         CodeNode *node = new CodeNode;
                        node->code = ">=";
                        $$ = node;
                      }
                ;

expression:	    Multiexpression {
                        //printf("expression -> mult_exp\n");
                        CodeNode *node = $1;
                        $$ = node;
                      }
                | Multiexpression ADD expression{
                          //printf("expression -> mult_exp ADD expression\n");
                          CodeNode *node = new CodeNode;
                          CodeNode *node1 = $1;
                          CodeNode *node2 = $3;

                          std::string temp = Generator::make_var();
                          node->code += node1->code + node2->code + ". " + temp + "\n";
                          node->code += "+ " + temp + ", " + node1->name + ", " + node2->name + "\n";
                          node->name = temp;
                          $$ = node;
                      }
                | Multiexpression SUB expression{
                          //printf("expression -> mult_exp SUB expression\n");
                          CodeNode *node = new CodeNode;
                          CodeNode *node1 = $1;
                          CodeNode *node2 = $3;

                          std::string temp = Generator::make_var();
                          node->code = node1->code + node2->code + ". " + temp + "\n";
                          node->code += "- " + temp + ", " + node1->name + ", " + node2->name + "\n";
                          node->name = temp;
                          $$ = node;
                      }
                      ;

Multiexpression:	    Term{
                        //printf("mult_exp -> term\n");
                        CodeNode *node = $1;
                        $$ = node;
                      }
                | Term MULT Term{
                          //printf("mult_exp -> term MULT mult_exp\n");
                          CodeNode *node = new CodeNode;
                          CodeNode *node1 = $1;
                          CodeNode *node2 = $3;
                          
                          std::string temp = Generator::make_var();
                          node->code += node1->code + node2->code + ". " + temp + "\n";
                          node->code += "* " + temp + ", " + node1->name + ", " + node2->name + "\n";
                          node->name = temp;
                          $$ = node;
                      }
                | Term DIV Term{
                          //printf("mult_exp -> term DIV mult_exp\n");
                          CodeNode *node = new CodeNode;
                          CodeNode *node1 = $1;
                          CodeNode *node2 = $3;
                          
                          std::string temp = Generator::make_var();
                          node->code += node1->code + node2->code + ". " + temp + "\n";
                          node->code += "/ " + temp + ", " + node1->name + ", " + node2->name + "\n";
                          node->name = temp;
                          $$ = node;
                      }
                | Term MOD Term{
                          //printf("mult_exp -> term MOD mult_exp\n");
                          CodeNode *node = new CodeNode;
                          CodeNode *node1 = $1;
                          CodeNode *node2 = $3;

                          std::string temp = Generator::make_var();
                          node->code += node1->code + node2->code + ". " + temp + "\n";
                          node->code += "% " + temp + ", " + node1->name + ", " + node2->name + "\n";
                          node->name = temp;
                          $$ = node;
                      }
                ;

Term:		        SUB var
    	        	//{printf("Term->SUB var\n");}
                | var{
                        //printf("term -> var\n");
                        CodeNode *node = $1;
                        if($$->isArray){
                          std::string temp = Generator::make_var();
                          node->code += ". " + temp + "\n";
                          node->code += "=[] " + temp + ", " + node->name + ", " + node->arrayIndex + "\n";
                          node->name = temp;
                        }
                        $$ = node;
                      }
                | SUB NUMBER
                  //{printf("Term->SUB NUMBER %d\n", $2);}
                | NUMBER
                  {
                          //printf("term -> NUMBER\n");
                          CodeNode *node = new CodeNode;
                          node->name = std::to_string($1);
                          node->arrayIndex = std::to_string($1);
                          $$ = node;
                      }
                | LPAREN expression RPAREN{
                          //printf("term -> L_PAREN expression R_PAREN\n");
                          CodeNode *node = $2;
                          $$ = node;
                      }
                | SUB LPAREN expression RPAREN
                  //{printf("Term-> SUB LPAREN expression RPAREN\n");}
                | IDENT LPAREN expression expressionLoop RPAREN{
                        //printf("term -> IDENT L_PAREN exp_loop R_PAREN\n");
                        CodeNode *node = new CodeNode;
                        CodeNode *node1 = $3;
                        std::string var = $1;
                        if(!findFunction(var)){
                          std::string temp = "Error cannot find function \"" + var + "\"";
                          yyerror(temp.c_str());
                        }
                        node->name = node1->name;
                        node->code += node1->code + "call " + $1 + ", " + node1->name + "\n";
                        $$ = node;
                      }
                | IDENT LPAREN RPAREN 
                //{printf("Term->Ident LPAREN RPAREN\n");}
                ;

expressionLoop: {
                        //printf("exp_loop -> epsilon\n");
                        CodeNode *node = new CodeNode;
                        $$ = node;
                      }
                | expression{
                          //printf("exp_loop -> expression\n");
                          CodeNode *node = $1;
                          //std::cout << node->code << std::endl;
                          node->code += "param " + node->name + "\n";
                          $$ = node;
                      }
	            	| expression COMMA expressionLoop{
                          //printf("exp_loop -> expression COMMA exp_loop\n");
                          CodeNode* node = new CodeNode;
                          CodeNode *node1 = $1;
                          CodeNode *node2 = $3;

                          std::string temp = Generator::make_var();
                          node->code += "param " + node1->name + "\n" + node2->code + ". " + temp + "\n";
                          node->name = temp;
                          $$ = node;
                      }
    		              ;
%% 

int Generator::counter_label = 0;
int Generator::counter_var = 0;

int main(int argc, char **argv) {
   if(argc == 2)
        yyin = fopen(argv[1], "r");
    else
        yyin = stdin;
   yyparse();
   //print_symbol_table();
   
   file << out.str();
   std::cout << out.str() << std::endl;
   return 0;
}

void yyerror(const char *msg) {
    /* implement your error handling */
    printf("** Line %d, col %d: %s\n", curLn, curPos, msg);
    exit(1);
}