﻿#include "uppaal_tree_parser.h"


/* 
 * TODO init like this: double x,y = 0.0;
 * TODO If else in init, guards, and invariants
 * TODO Clean up, e.g. add trimmer for whitespace AND TABS!
 */

string get_constraint_op(const string& expr)
{
    if(expr.find("<=") != std::string::npos)
        return "<=";
    if(expr.find(">=") != std::string::npos)
        return ">=";
    if(expr.find("==") != std::string::npos)
        return "==";
    if(expr.find("!=") != std::string::npos)
        return "!=";
    if(expr.find('<') != std::string::npos)
        return "<";
    if(expr.find('>') != std::string::npos)
        return ">";
    THROW_LINE("Operand in " + expr + " not found, sad..");
}


constraint_t* get_constraint(const string& expr, const int timer_id, expression* value)
{
    if(expr.find("<=") != std::string::npos)
        return constraint_t::less_equal_v(timer_id, value);
    if(expr.find(">=") != std::string::npos)
        return constraint_t::greater_equal_v(timer_id,value);
    if(expr.find("==") != std::string::npos)
        return constraint_t::equal_v(timer_id,value);
    if(expr.find("!=") != std::string::npos)
        return constraint_t::not_equal_v(timer_id,value);
    if(expr.find('<') != std::string::npos)
        return constraint_t::less_v(timer_id,value);
    if(expr.find('>') != std::string::npos)
        return constraint_t::greater_v(timer_id,value);
    THROW_LINE("Operand in " + expr + " not found, sad..");
}

expression* get_expression_con(const string& expr, expression* left, expression* right)
{
    if(expr.find("<=") != std::string::npos)
        return expression::less_equal_expression(left, right);
    if(expr.find(">=") != std::string::npos)
        return expression::greater_equal_expression(left,right);
    if(expr.find("==") != std::string::npos)
        return expression::equal_expression(left,right);
    if(expr.find("!=") != std::string::npos)
        return expression::not_equal_expression(left,right);
    if(expr.find('<') != std::string::npos)
        return expression::less_expression(left,right);
    if(expr.find('>') != std::string::npos)
        return expression::greater_expression(left,right);
    THROW_LINE("Operand in " + expr + " not found, sad..");
}

constraint_t* get_constraint(const string& expr, expression* value_1, expression* value)
{
    if(expr.find("<=") != std::string::npos)
        return constraint_t::less_equal_e(value_1, value);
    if(expr.find(">=") != std::string::npos)
        return constraint_t::greater_equal_e(value_1,value);
    if(expr.find("==") != std::string::npos)
        return constraint_t::equal_e(value_1,value);
    if(expr.find("!=") != std::string::npos)
        return constraint_t::not_equal_e(value_1,value);
    if(expr.find('<') != std::string::npos)
        return constraint_t::less_e(value_1,value);
    if(expr.find('>') != std::string::npos)
        return constraint_t::greater_e(value_1,value);
    THROW_LINE("Operand in " + expr + " not found, sad..");
}

constraint_t* get_constraint(const string& expr, const int timer_id_1, const int timer_id_2)
{
    if(expr.find("<=") != std::string::npos)
        return constraint_t::less_equal_t(timer_id_1, timer_id_2);
    if(expr.find(">=") != std::string::npos)
        return constraint_t::greater_equal_t(timer_id_1, timer_id_2);
    if(expr.find("==") != std::string::npos)
        return constraint_t::equal_t(timer_id_1, timer_id_2);
    if(expr.find('<') != std::string::npos)
        return constraint_t::less_t(timer_id_1, timer_id_2);
    if(expr.find('>') != std::string::npos)
        return constraint_t::greater_t(timer_id_1, timer_id_2);
    THROW_LINE("Operand in " + expr + " not found, sad..")
}

int uppaal_tree_parser::get_timer_id(const string& expr) const
{
    const string expr_wout_spaces = replace_all(expr, string(" "), string(""));
    int index = 0;

    while (true)
    {
        if (static_cast<int>(expr.size()) == index)
        {
            break;
        }
        
        if (in_array(expr_wout_spaces[++index], {'<','>','='}))
        {
            break;
        }
    }

    const string sub = expr_wout_spaces.substr(0, index);
    if ( vars_map_.count(sub))
    {
        return vars_map_.at(sub);
    }
    
    if (global_vars_map_.count(sub))
    {
        return global_vars_map_.at(sub);
    }
    
    THROW_LINE("sum tin wong");
}

void uppaal_tree_parser::get_condition_strings(const string& con, string* left, string* op, string* right)
{
    *op = get_constraint_op(con);
    *left = take_while(con, *op);
    *right = take_after(con, *op);
}

template <typename T>
void uppaal_tree_parser::fill_expressions(const list<string>& expressions, list<T>* t)
{
    for(const auto& expr: expressions)
    {
        string trimmed = replace_all(expr, " ", "");
        if (trimmed.empty())
            continue;

        string op;
        string right_side;
        string left_side;

        get_condition_strings(trimmed, &left_side, &op, &right_side);

        //TODO fix this plz
        //Constraint is heap allocated, and is then copied here.
        //Results in dead memory.
        
        if (timers_map_.count(left_side) || global_timers_map_.count(left_side))
            t->push_back(*get_constraint(trimmed, get_timer_id(trimmed), variable_expression_evaluator::parse_update_expr(right_side, &vars_map_, &global_vars_map_)));
        else
            t->push_back(*get_constraint(trimmed, variable_expression_evaluator::parse_update_expr(left_side, &vars_map_, &global_vars_map_), variable_expression_evaluator::parse_update_expr(right_side, &vars_map_, &global_vars_map_)));
    }
}


void uppaal_tree_parser::init_global_clocks(const xml_document* doc)
{
    string global_decl = doc->child("nta").child("declaration").child_value();
    global_decl = replace_all(global_decl, " ", "");
    const list<declaration> decls = dp_.parse(global_decl);
    for (declaration d : decls)
    {
        //global declarations
        if(d.get_type() == clock_type)
        {
            insert_to_map(&this->global_vars_map_, d.get_name(), clock_id_);
            insert_to_map(&this->global_timers_map_, d.get_name(), clock_id_);
            timer_list_->push_back(clock_variable(clock_id_++, d.get_value()));
            
        }
        else if(d.get_type() == chan_type)
        {
            insert_to_map(&this->global_vars_map_, d.get_name(), chan_id_++);
        }
        else
        {
            insert_to_map(&this->global_vars_map_, d.get_name(), var_id_);
            var_list_->push_back(clock_variable(var_id_++, d.get_value()));

        }
    }
}

void uppaal_tree_parser::init_local_clocks(xml_node template_node)
{
    string decl = template_node.child("declaration").child_value();
    decl = replace_all(decl, " ", ""); //TODO Trimmer
    
    for (declaration d : dp_.parse(decl))
    {
        //local declarations
        if(d.get_type() == clock_type)
        {
            insert_to_map(&this->vars_map_, d.get_name(), clock_id_);
            insert_to_map(&this->timers_map_, d.get_name(), clock_id_);
            timer_list_->push_back(clock_variable(clock_id_++, d.get_value()));

        }
        else if(d.get_type() == chan_type)
        {
            insert_to_map(&this->vars_map_, d.get_name(), chan_id_++);
        }
        else
        {
            // vars_map_.insert_or_assign(d.get_name(), var_id_);
            insert_to_map(&this->vars_map_, d.get_name(), var_id_);
            var_list_->push_back(clock_variable(var_id_++, d.get_value()));

        }
    }
}

uppaal_tree_parser::uppaal_tree_parser()
= default;

node_t* uppaal_tree_parser::get_node(const int target_id, const list<node_t*>* arr) const
{
    for(node_t* node: *arr)
    {
        if(node->get_id() == target_id)
            return node;
    }
    return arr->front();
}

void uppaal_tree_parser::handle_locations(const xml_node locs)
{
    const string string_id = locs.attribute("id").as_string();
    string string_name = locs.child("name").child_value();
    const int node_id = xml_id_to_int(string_id);
    list<constraint_t> invariants;
    expression* expo_rate = nullptr;
    bool is_goal = false;

    insert_to_map(&node_edge_map, node_id, list<edge_t>());
            
    if (string_name != "")
    {
        is_goal = string_name == "Goal" ? true : false;
        node_names_->emplace(node_id, string_name);
    }

    const string kind = locs.child("label").attribute("kind").as_string();
    const string expr_string = locs.child("label").child_value();

    const list<string> expressions = split_expr(expr_string);
            
    if (kind == "exponentialrate")
    {
        //TODO make string trimmer
        const string line_wo_ws = replace_all(expr_string, " ", "");
        const string nums = take_after(line_wo_ws, "=");
                
        expo_rate = variable_expression_evaluator::parse_update_expr(nums,&vars_map_, &global_vars_map_);
    }
            
    if (kind == "invariant")
    {
        fill_expressions(expressions, &invariants);
    }
            
    if (init_node_id_ == node_id)
        start_nodes_.push_back(nodes_->size());
            
    node_t* node = new node_t(node_id, to_array(&invariants),false, is_goal, expo_rate);
    nodes_->push_back(node);
    nodes_map_->emplace(node->get_id(), node_with_system_id(node, this->system_count_));
}

void uppaal_tree_parser::handle_transitions(const xml_node trans)
{
    string source = trans.child("source").attribute("ref").as_string();
            string target = trans.child("target").attribute("ref").as_string();

            int source_id = xml_id_to_int(source);
            int target_id = xml_id_to_int(target);
            
            list<constraint_t> guards;
            list<update_t> updates;
            expression* probability = nullptr;
            edge_channel* ec = nullptr;
            
            for (pugi::xml_node labels: trans.children("label"))
            {
                string kind = labels.attribute("kind").as_string();
                string expr_string = labels.child_value();

                
                if(kind == "guard")
                {
                    list<string> expressions = split_expr(expr_string);
                    fill_expressions(expressions, &guards);
                }
                else if (kind == "assignment")
                {
                    updates = handle_assignment(expr_string);
                }
                else if (kind == "synchronisation")
                {
                    ec = handle_sync(expr_string);
                }
                else if (kind == "probability")
                {
                    string line_wo_ws = replace_all(expr_string, " ", "");
                    string nums = take_after(line_wo_ws, "="); //TODO Trimmer
                    probability = variable_expression_evaluator::parse_update_expr(nums,&vars_map_, &global_vars_map_);
                }
            }

            if (probability == nullptr) probability = expression::literal_expression(1.0);
            
            node_t* target_node = get_node(target_id, nodes_);
            edge_t result_edge = ec == nullptr
                ? edge_t(edge_id_++, probability, target_node, to_array(&guards), to_array(&updates))
                : edge_t(edge_id_++, probability, target_node, to_array(&guards), to_array(&updates), *ec);
            
            node_edge_map.at(source_id).push_back(result_edge);
}

bool uppaal_tree_parser::is_if_statement(const string& expr)
{
    return expr.find("?")!=std::string::npos && expr.find(":")!=std::string::npos;
}

expression* uppaal_tree_parser::handle_if_statement(const string& input)
{
    const string condition = replace_all(take_while(input, "?"), " ", "");
    const string if_true = replace_all(take_while(take_after(input, "?"), ":"), " ", "");
    const string if_false = replace_all(take_after(input, ":"), ";", "");

    string op;
    string right_side_con;
    string left_side_con;
    get_condition_strings(condition, &left_side_con, &op, &right_side_con);

    //Build the condition
    expression* right_side_con_expr = variable_expression_evaluator::parse_update_expr(right_side_con,&this->vars_map_, &this->global_vars_map_);
    expression* left_side_con_expr = variable_expression_evaluator::parse_update_expr(left_side_con,&this->vars_map_, &this->global_vars_map_);
    expression* condition_e = get_expression_con(condition, left_side_con_expr, right_side_con_expr);
    
    expression* if_true_e = variable_expression_evaluator::parse_update_expr(if_true,&this->vars_map_, &this->global_vars_map_);
    expression* if_false_e = variable_expression_evaluator::parse_update_expr(if_false,&this->vars_map_, &this->global_vars_map_);
            
    return expression::conditional_expression(condition_e, if_true_e, if_false_e);
}

list<update_t> uppaal_tree_parser::handle_assignment(const string& input)
{
    const list<string> expressions = split_expr(input, ',');
    list<update_t> result;
    expression* right_side;
    
    for(const auto& expr: expressions)
    {
        const string line_wo_ws = replace_all(expr, " ", "");
        if (expr.empty())
            continue;

        const string left_side = take_while(line_wo_ws, "=");
        const string right_side_of_equal = take_after(line_wo_ws, "=");

        if (is_if_statement(right_side_of_equal))
        {
            //Is if statement
            right_side = handle_if_statement(right_side_of_equal);
        }
        else
        {
            //Is normal assignment
            right_side = variable_expression_evaluator::parse_update_expr(right_side_of_equal,&this->vars_map_, &this->global_vars_map_);
        }
        
        bool is_clock = false;

        if(this-> timers_map_.count(left_side) || this->global_timers_map_.count(left_side))
        {
            is_clock = true;
        }
        
        result.emplace_back(update_t(this->update_id_++, get_timer_id(left_side), is_clock, right_side));
    }
    
    return result;
}

edge_channel* uppaal_tree_parser::handle_sync(const string& input) const
{
    const auto ec = new edge_channel();
    
    ec->is_listener = input.find("?")!=std::string::npos;
    
    string sync_keyword = replace_all(input, " ", "");
    sync_keyword = replace_all(sync_keyword, ec->is_listener ? "?" : "!", "");
    if (vars_map_.count(sync_keyword))
    {
        ec->channel_id = vars_map_.at(sync_keyword);
        return ec;
    }
    
    if (global_vars_map_.count(sync_keyword))
    {
        ec->channel_id = global_vars_map_.at(sync_keyword);
        return ec;
    }

    THROW_LINE(sync_keyword + " NOT IN LOCAL, NOR GLOBAL MAP, comeon dude..");
}

array_t<node_t*> uppaal_tree_parser::after_processing()
{
    for(node_t* node: *nodes_)
    {
        node->set_edges(&node_edge_map.at(node->get_id()));
    }
    
    const array_t<node_t*> start_nodes = array_t<node_t*>(start_nodes_.size());

    int number_of_start_nodes = 0;
    for (const int i : start_nodes_)
    {
        auto n_front = nodes_->begin();
        std::advance(n_front, i);
        start_nodes.arr()[number_of_start_nodes++] = *n_front;
    }
    
    return start_nodes;
}


__host__ stochastic_model_t uppaal_tree_parser::parse_xml(const char* file_path)
{
    string path = file_path;
    xml_document doc;
    declaration_parser dp;
    
    // load the XML file
    if (!doc.load_file(file_path))
    {
        THROW_LINE("The specified file does not exist.. stupid.")
    }

    init_global_clocks(&doc);
    
    for (pugi::xml_node templates: doc.child("nta").children("template"))
    {
        const string init_node = templates.child("init").attribute("ref").as_string();
        init_node_id_ = xml_id_to_int(init_node);
        init_local_clocks(templates);
        
        for (const pugi::xml_node locs: templates.children("location"))
        {
            handle_locations(locs);
        }

        for (pugi::xml_node locs: templates.children("branchpoint"))
        {
            const string string_id = locs.attribute("id").as_string();
            const int node_id = xml_id_to_int(string_id);
            insert_to_map(&node_edge_map, node_id, list<edge_t>());
            nodes_->push_back(new node_t(node_id,array_t<constraint_t>(0), true));
        }
        
        for (const pugi::xml_node trans: templates.children("transition"))
        {
            handle_transitions(trans);
        }
        
        //Done with system, clear storage
        vars_map_.clear();
        timers_map_.clear();
        this->system_count_++;
    }

    const auto start_nodes = after_processing();
    return stochastic_model_t(start_nodes, to_array(timer_list_), to_array(var_list_));
}

__host__ stochastic_model_t uppaal_tree_parser::parse(string file_path)
{
    try
    {
        char* writeable = new char[file_path.size() + 1];
        std::copy(file_path.begin(), file_path.end(), writeable);
        writeable[file_path.size()] = '\0';
        auto model = parse_xml(writeable);
        delete[] writeable;
        return model;
    }
    catch (const std::runtime_error &ex)
    {
        cout << "Parse error: " << ex.what() << "\n";
        throw runtime_error("parse error");
    }
}