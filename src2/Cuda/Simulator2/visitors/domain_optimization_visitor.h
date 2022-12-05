﻿#pragma once
#include <unordered_map>

#include "visitor.h"
#include "../engine/model_oracle.h"



class domain_optimization_visitor : public visitor
{
    unsigned max_expr_depth_ = 0;
    bool check_depth_lock_ = true;
    bool contains_invalid_constraint_ = false;
    std::unordered_map<int, bool> variables_clock_map_;
    model_size model_counter_;
    
    static unsigned count_expr_depth(const expr* ex);
    static void compound_optimize_constraints(edge* e);
    bool expr_contains_clock(const expr* ex);
public:
    void optimize(network* a){ visit(a);  }
    void visit(network* a) override;
    void visit(node* n) override;
    void visit(edge* e) override;
    void visit(constraint* c) override;
    void visit(clock_var* cv) override ;
    void visit(update* u) override;
    void visit(expr* ex) override;

    void clear();
    
    unsigned get_max_expr_depth() const;
    bool invalid_constraint() const;
    model_size get_model_size() const{ return model_counter_; }
};