﻿#include "outout_writer.h"

float output_writer::calc_percentage(const unsigned long long counter, const unsigned long long divisor)
{
    return (static_cast<float>(counter) / static_cast<float>(divisor)) * 100.0f;
}

void output_writer::write_to_file(const result_pointers* results,
    std::chrono::steady_clock::duration sim_duration) const
{
    std::ofstream file_node, file_variable;
    
    file_node.open(this->file_path_ + "_node_data_" + std::to_string(output_counter_) + ".csv" );
    file_variable.open(this->file_path_ + "_variable_data_" + std::to_string(output_counter_) + ".csv");
    
    file_node << "Simulation,Model,Node,Steps,Time\n";
    file_variable << "Simulation,Variable,Value\n";
    
    
    for (unsigned i = 0; i < total_simulations_; ++i)
    {
        const sim_metadata local_result = results->meta_results[i];
        for (unsigned  j = 0; j < this->model_count_; ++j)
        {
            file_node << i << "," << j << "," << results->nodes[this->model_count_ * i + j] << ","
            << local_result.steps << "," << local_result.global_time << "\n";
        }
    
        for (int k = 0; k < this->variable_summaries_.size; ++k)
        {
            file_variable << i << "," << k << "," << results->variables[this->variable_summaries_.size * i + k] << "\n";
        }
    }

    file_node.flush();
    file_variable.flush();
     
    file_node.close();
    file_variable.close();
}

void output_writer::write_summary_to_stream(std::ostream& stream,
                                            std::chrono::steady_clock::duration sim_duration) const
{
    stream << "\naverage maximum value of each variable: \n";
    
    for (int j = 0; j < this->variable_summaries_.size(); ++j)
    {
        const variable_summary result = this->variable_summaries_.store[j];
        stream << "variable " << result.variable_id << " = " << result.avg_max_value << "\n";
    }
    
    stream << "\n\ngoal: \n";

    node_summary no_hit = node_summary{0, 0};
    
    for (const std::pair<const int, node_summary>& it : this->node_summary_map_)
    {
        if(HAS_HIT_MAX_STEPS(it.first))
            no_hit.cumulative(it.second);

        const float percentage = calc_percentage(it.second.reach_count, total_simulations_);
        stream << print_node(it.first, it.second.reach_count, percentage, it.second.avg_steps);
    }
    
    
    const float percentage = calc_percentage(no_hit.reach_count, total_simulations_);

    stream << "No goal node was reached "<< no_hit.reach_count << " times. ("
         << percentage << ")%. avg step count: " << no_hit.avg_steps << ".\n";

    stream << "\nNr of simulations: " << total_simulations_ << "\n\n";
    stream << "Simulation ran for: " << duration_cast<std::chrono::milliseconds>(sim_duration).count()
           << "[ms]" << "\n";
}

void output_writer::write_lite(std::chrono::steady_clock::duration sim_duration) const
{
    std::ofstream lite;
    const std::string file_path = file_path_ + "_lite_summary.txt";
    lite.open(file_path);

    lite << duration_cast<std::chrono::milliseconds>(sim_duration).count();

    lite.flush();
    lite.close();
}

void output_writer::write_hit_file(std::chrono::steady_clock::duration sim_duration) const
{
    if (this->node_summary_map_.empty()) return;
    std::ofstream file = std::ofstream(this->file_path_ + "_results.tsv", std::ofstream::out|std::ofstream::trunc);
    
    for (const auto& pair : this->node_summary_map_)
    {
        if (HAS_HIT_MAX_STEPS(pair.first)) continue;

        const float percentage = this->calc_percentage(pair.second.reach_count, total_simulations_);
        
        file << percentage << "\t" << duration_cast<std::chrono::milliseconds>(sim_duration).count();
    }  

    file.flush();
    file.close();
}

output_writer::output_writer(const std::string* path, unsigned sim_count, int write_mode, const automata* model)
{
    this->file_path_ = *path;
    this->write_mode_ = write_mode;
    this->total_simulations_ = sim_count;

    unsigned var_count = 0;
    for (int i = 0; i < model->variables.size; ++i)
        if(model->variables.store[i].should_track)
            var_count += 1;

    this->variable_summaries_ = arr<variable_summary>{
        static_cast<variable_summary*>(malloc(sizeof(variable_summary)*var_count)),
        static_cast<int>(var_count)
    };

    for (unsigned i = 0; i < static_cast<unsigned>(model->variables.size); ++i)
        if(model->variables.store[i].should_track)
            this->variable_summaries_.store[i] = variable_summary{i, 0.0, 0};
    
    
    this->model_count_ = model->network.size;
    this->node_summary_map_ = std::unordered_map<int, node_summary>();
}

void output_writer::write(const result_store* sim_result, std::chrono::steady_clock::duration sim_duration)
{
    if (this->write_mode_ & lite_sum)
    {
        this->write_lite(sim_duration);
    }

    if(this->write_mode_ & (console_sum | file_sum | file_data | hit_file))
    {
        const result_pointers pointers = sim_result->load_results();

        for (unsigned i = 0; i < this->total_simulations_; ++i)
        {
            sim_metadata x = pointers.meta_results[i];
            
            for (unsigned j = 0; j < model_count_; ++j)
            {
                int n = pointers.nodes[i*model_count_ + j];
                if(this->node_summary_map_.count(n)) //exists
                    this->node_summary_map_.at(n).update_count(x.steps);
                else
                    this->node_summary_map_.insert(
                        std::pair<int, node_summary>(
                            n, node_summary{ 1, static_cast<double>(x.steps) }));
            }

            for (unsigned j = 0; j < this->variable_summaries_.size; ++j)
            {
                double v = pointers.variables[i*this->variable_summaries_.size + j];
                this->variable_summaries_.store[i].update_count(v);
            }
        }
        
        if(this->write_mode_ & file_data) write_to_file(&pointers, sim_duration);
        
        pointers.free_internals();
    }
    output_counter_++;
}

void output_writer::write_summary(std::chrono::steady_clock::duration sim_duration) const
{
    if (this->write_mode_ & console_sum)
    {
        this->write_summary_to_stream(std::cout, sim_duration);
    }
    if (this->write_mode_ & file_sum)
    {
        const std::string path = this->file_path_ + "_summary.csv";
    
        std::ofstream summary;
        summary.open(path);
        this->write_summary_to_stream(summary, sim_duration);

        summary.flush();
        summary.close();
    }
    if (this->write_mode_ & hit_file)
    {
        this->write_hit_file(sim_duration);   
    }
}

void output_writer::clear()
{
    this->node_summary_map_.clear();
    for (int i = 0; i < this->variable_summaries_.size; ++i)
    {
        this->variable_summaries_.store[i] = variable_summary{
            this->variable_summaries_.store[i].variable_id,
            0.0,
            0,
        };
    }
}