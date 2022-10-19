﻿
#ifndef UPDATE_EXPRESSION_EVALUATOR_H
#define UPDATE_EXPRESSION_EVALUATOR_H

#include <iostream>
#include <cstdlib>
#include <cctype>
#include <cstring>
#include <math.h> 
#include <cctype>
#include <cstring>
#include <iostream>
#include <map>
#include "../Domain/expressions/expression.h"
#include "parser_exception.h"


#define PI 3.14159265358979323846 

class expression;
using namespace std;
 
enum update_types { UPDATEDELIMITER = 1, UPDATEVARIABLE, UPDATENUMBER, UPDATEFUNCTION };
const int UPDATE_NUMVARS = 26;
class update_expression_evaluator {
    char *exp_ptr; // points to the expression
    char token[256]; // holds current token
    char tok_type; // holds token's type
    double vars[UPDATE_NUMVARS]; // holds variable's values
    map<string, int>* local_vars_;
    map<string, int>* global_vars_;
    expression* eval_exp1();
    expression* eval_exp2();
    expression* eval_exp3();
    expression* eval_exp4();
    expression* eval_exp5();
    expression* eval_exp6();
    expression* eval_exp(char *exp);
    void get_token();
public:
    update_expression_evaluator(map<string,int>* local_vars, map<string,int>* global_vars);
    static expression* parse_update_expr(string input, map<string, int>* local_vars, map<string, int>* global_vars);
    
    char errormsg[64];
};


#endif