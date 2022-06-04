/* cs152-miniL */

%{   
   /* write your C code here for definitions of variables and including headers */
   #include "miniL-parser.hpp"
   int fileno(FILE *stream); // erorrs??????
	int curPos = 0;
	int curLn = 1;
%}

/* some common rules */
DIGIT          [0-9]
CHAR           [a-zA-Z0-9_]
WHITESPACE     [ \t]
NEWLINE        [\n]

%%
"function"     {curPos += yyleng; return FUNCTION;}
"beginparams"  {curPos += yyleng; return BEGINPARAMS;}
"endparams"    {curPos += yyleng; return ENDPARAMS;}
"beginlocals"  {curPos += yyleng; return BEGINLOCALS;}
"endlocals"    {curPos += yyleng; return ENDLOCALS;}
"beginbody"    {curPos += yyleng; return BEGINBODY;}
"endbody"      {curPos += yyleng; return ENDBODY;}
"integer"      {curPos += yyleng; return INTEGER;}
"array"        {curPos += yyleng; return ARRAY;}
"of"           {curPos += yyleng; return OF;}
"if"           {curPos += yyleng; return IF;}
"then"         {curPos += yyleng; return THEN;}
"endif"        {curPos += yyleng; return ENDIF;}
"else"         {curPos += yyleng; return ELSE;}
"while"        {curPos += yyleng; return WHILE;}
"do"           {curPos += yyleng; return DO;}
"beginloop"    {curPos += yyleng; return BEGINLOOP;}
"endloop"      {curPos += yyleng; return ENDLOOP;}
"continue"     {curPos += yyleng; return CONTINUE;}
"break"        {curPos += yyleng; return BREAK;}
"read"         {curPos += yyleng; return READ;}
"write"        {curPos += yyleng; return WRITE;}
"and"          {curPos += yyleng; return AND;}
"or"           {curPos += yyleng; return OR;}
"not"          {curPos += yyleng; return NOT;}
"true"         {curPos += yyleng; return TRUE;}
"false"        {curPos += yyleng; return FALSE;}
"return"       {curPos += yyleng; return RETURN;}

"-"            {curPos += yyleng; return SUB;}
"+"            {curPos += yyleng; return ADD;}
"*"            {curPos += yyleng; return MULT;}
"/"            {curPos += yyleng; return DIV;}
"%"            {curPos += yyleng; return MOD;}

"=="           {curPos += yyleng; return EQ;}
"<>"           {curPos += yyleng; return NEQ;}
"<"            {curPos += yyleng; return LT;}
">"            {curPos += yyleng; return GT;}
"<="           {curPos += yyleng; return LTE;}
">="           {curPos += yyleng; return GTE;}

";"            {curPos += yyleng; return SEMICOLON;}
":"            {curPos += yyleng; return COLON;}
","            {curPos += yyleng; return COMMA;}
"("            {curPos += yyleng; return LPAREN;}
")"            {curPos += yyleng; return RPAREN;}
"["            {curPos += yyleng; return L_SQUARE_BRACKET;}
"]"            {curPos += yyleng; return R_SQUARE_BRACKET;}
":="           {curPos += yyleng; return ASSIGN;}

"##".*{NEWLINE}            {curPos = 0; curLn++;}
{NEWLINE}                  {curPos = 0; curLn++;}
{WHITESPACE}+	            {curPos += yyleng;}

{DIGIT}+                   {yylval.int_val = atoi(yytext); curPos += yyleng; return NUMBER;}

({DIGIT}|"_"){CHAR}+       {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter \n", 
	                              curLn, curPos, yytext); exit(1);}
{CHAR}*"_"                 {printf("Error at line %d, column %d: identifier \"%s\" can not end with an underscore\n", 
	                              curLn, curPos, yytext); exit(1);}

{CHAR}*                    {
                              char *ptr = new char[yyleng]; strcpy(ptr, yytext); yylval.ident = ptr;
                              curPos += yyleng; return IDENT;
                           } 

.                          {curPos += yyleng;}

%%

/* C functions used in lexer */

/* int main(int argc, char ** argv)
{
   if(argc == 2)
        yyin = fopen(argv[1], "r");
    else
        yyin = stdin;
   yylex();
} */