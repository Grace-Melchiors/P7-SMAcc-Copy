﻿#ifndef SIMULATION_STRATEGY_H
#define SIMULATION_STRATEGY_H

#define HIT_MAX_STEPS (-1)


struct model_options
{
    unsigned int simulation_amount;
    unsigned long seed;
    unsigned int max_expression_depth;

    bool use_max_steps = true;
    const unsigned int max_steps_pr_sim;
    const double max_global_progression;
};



struct simulation_strategy
{
    unsigned int block_n = 1;
    unsigned int threads_n = 1;
    unsigned int simulations_per_thread = 1;
    unsigned int cpu_threads_n = 1;
    unsigned int simulation_runs = 1;

    bool use_max_steps = true;
    unsigned int max_sim_steps = 100;
    double max_time_progression = 100.0;

    unsigned int degree_of_parallelism() const
    {
        return block_n*threads_n;
    }
    
    unsigned long total_simulations() const
    {
        return block_n*threads_n*simulations_per_thread;
    }
};

#endif