﻿#pragma once
#include "update_expression_evaluator.h"
#include <list>
#include <string>
#include <list>
#include <string>
#include "../Domain/expressions/expression.h"
#include "declaration.h"
#include "helper_methods.h"
class update_parser
{
private:
public:
    static expression* parse(string decl, map<string, int>* local_vars, map<string, int>* global_vars);
};