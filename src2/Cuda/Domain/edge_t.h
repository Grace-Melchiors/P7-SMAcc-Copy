﻿#pragma once

#ifndef EDGE_T_H
#define EDGE_T_H

#include "common.h"
#include <list>

class node_t;

class edge_t
{
private:
    int id_;
    float weight_;
    node_t* dest_;
    constraint_t* guard_;
    array_t<update_t> updates_{0};
public:
    explicit edge_t(int id, float weight, node_t* dest, constraint_t* guard);
    CPU GPU float get_weight() const;
    GPU CPU node_t* get_dest() const;
    void set_updates(std::list<update_t>* updates);
    GPU bool evaluate_constraints(const lend_array<clock_timer_t>* timers) const;
    GPU void execute_updates(const lend_array<clock_timer_t>* timers);
    void accept(visitor* v);
    int get_id() const;
};

#endif