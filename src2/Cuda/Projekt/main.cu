﻿#include "main.h"
#define GPU __device__
#define CPU __host__
#include <cuda.h>
#include <cuda_runtime.h>
#include <list>
#include <stdio.h>
#include "../../UPAALParser/UPAALXMLParser.h"

#include "uneven_list.h"
#include "node_d.h"
#include "edge_d.h"
#include "guard_d.h"
#include "update_d.h"
#include "timer_d.h"
#include "cuda_simulator.h"
int main(int argc, char* argv[])
{
    // node_d nodes[2] = {node_d(1), node_d(2)};
    // edge_d edges[2] = {edge_d(1, 2), edge_d(2, 1)};
    // guard_d guards[1] = {guard_d(1, logical_operator::greater_equal, 10)};
    // update_d updates[1] = {update_d(1, 0)};
    // timer_d timers[1] = {timer_d(1,0)};
    //
    // array_info<node_d> n {nodes, 2};
    // array_info<edge_d> e {edges, 2};
    // array_info<guard_d> g {guards, 1};
    // array_info<update_d> u {updates, 1};
    // array_info<timer_d> t {timers, 1};
    //
    // cuda_simulator sim(&n, &e, &g, &u, &t);
    // sim.simulate(10);

    // node = [node]
    // edge = [[edge]], hvor index af første = node index
    // invarient = [[guard]], hvor index af først = node index
    // guard = [guard], hvor index = edge id
    // update = [update], hvor index = edge id
    // timer = [timer], index = id.

    // -----------------------------------------------------------

    //Nodes
    list<node_d> nodes__;
    nodes__.emplace_back(0);
    nodes__.emplace_back(1);
    nodes__.emplace_back(2);
    nodes__.emplace_back(3);
    nodes__.emplace_back(4);

    // Edges
    list<edge_d> edges_1_;
    edges_1_.emplace_back(0, 1);
    edges_1_.emplace_back(1,2);

    list<edge_d> edges_2_;
    edges_2_.emplace_back(2, 2);

    list<edge_d> edges_3_;
    //edges_3_.emplace_back(3,0);

    list<list<edge_d>> edge_list;
    edge_list.push_back(edges_1_);
    edge_list.push_back(edges_2_);
    edge_list.push_back(edges_3_);

    //Invariants for nodes
    list<guard_d> invariant_1_;
    invariant_1_.emplace_back(0, logical_operator::less, 10, 0);

    list<guard_d> invariant_2_;
    //invariant_2_.emplace_back(0, logical_operator::less_equal, 10);

    list<guard_d> invariant_3_;
    invariant_3_.emplace_back(0, logical_operator::greater_equal, 10, 1);

    list<list<guard_d>> invariant_list;
    invariant_list.push_back(invariant_1_);
    invariant_list.push_back(invariant_2_);
    invariant_list.push_back(invariant_3_);

    // Guard List for edges
    list<guard_d> guard_1_;
    guard_1_.emplace_back(0, logical_operator::less, 5, 2);

    list<guard_d> guard_2_;
    guard_2_.emplace_back(0, logical_operator::greater, 10, 3);

    list<guard_d> guard_3_;
    guard_3_.emplace_back(0, logical_operator::greater_equal, 10, 4);

    // list<guard_d> guard_4_;
    
    list<list<guard_d>> guard_list;
    guard_list.push_back(guard_1_);
    guard_list.push_back(guard_2_);
    guard_list.push_back(guard_3_);
    // guard_list.push_back(guard_4_);

    //Update list for edges
    list<update_d> update_1_;
    update_1_.emplace_back(0, 0);
    update_1_.emplace_back(1,0);
    
    list<update_d> update_2_;
    update_2_.emplace_back(0, 0);

    list<update_d> update_3_;

    list<update_d> update_4_;

    list<list<update_d>> update_list;
    update_list.push_back(update_1_);
    update_list.push_back(update_2_);
    update_list.push_back(update_3_);
    update_list.push_back(update_4_);

    // Timers
    timer_d* timer_list;
    timer_list = (timer_d*)malloc(sizeof(timer_d) * 2);
    timer_list[0] = timer_d(0, 0);
    timer_list[1] = timer_d(1, 0);
    
    UPAALXMLParser parser;
    auto p = parser.parse_xml(&timer_list[1], argv[1]);

    uneven_list<edge_d> node_to_edge = p.edge;
    uneven_list<guard_d> node_to_invariant = p.invariance;
    uneven_list<guard_d> edge_to_guard = p.guard;
    uneven_list<update_d> edge_to_update = p.update;

    //list<list<edge_d>>::iterator it;
    // int i = 0;
    // for (it = node_to_edge.get_index(0)->begin(); it != node_to_edge.get_index(0)->end(); it++)
    // {
    //     printf("%d",i);
    //     i++;
    //     typename list<edge_d>::iterator it2;
    //     for (it2 = it->begin(); it2 != it->end(); it2++ )
    //     {
    //         printf("%d",it2->get_id());
    //     }
    //     printf("\n");
    // }


    
    // NOW ALLOCATE MEMORY ON DEVICE FOR ALL THIS SHIT!

    uneven_list<edge_d> *node_to_edge_d;
    uneven_list<guard_d> *node_to_invariant_d;
    uneven_list<guard_d> *edge_to_guard_d;
    uneven_list<update_d> *edge_to_update_d;

    timer_d* timers_d;
    
    cudaMalloc((void**)&node_to_edge_d, sizeof(uneven_list<edge_d>));
    cudaMalloc((void**)&node_to_invariant_d, sizeof(uneven_list<guard_d>));
    cudaMalloc((void**)&edge_to_guard_d, sizeof(uneven_list<guard_d>));
    cudaMalloc((void**)&edge_to_update_d, sizeof(uneven_list<update_d>));
    cudaMalloc((void**)&timers_d, sizeof(timer_d) * 2);

    // Copy memory to device
    node_to_edge.allocate_memory();
    node_to_invariant.allocate_memory();
    edge_to_guard.allocate_memory();
    edge_to_update.allocate_memory();

    cudaMemcpy(node_to_edge_d, &node_to_edge, sizeof(uneven_list<edge_d>), cudaMemcpyHostToDevice);
    cudaMemcpy(node_to_invariant_d, &node_to_invariant, sizeof(uneven_list<guard_d>), cudaMemcpyHostToDevice);
    cudaMemcpy(edge_to_guard_d, &edge_to_guard, sizeof(uneven_list<guard_d>), cudaMemcpyHostToDevice);
    cudaMemcpy(edge_to_update_d, &edge_to_update, sizeof(uneven_list<update_d>), cudaMemcpyHostToDevice);
    cudaMemcpy(timers_d, timer_list, sizeof(timer_d) * 2, cudaMemcpyHostToDevice);

    //printf("yasss girl: %d %d %d %d\n", node_to_edge.max_elements_, node_to_edge.max_index_, node_to_edge_d->max_elements_, node_to_edge_d->max_index_);

    // array_info<edge_d> hej = node_to_edge_d->get_index(0);
    //
    // for(int i = 0; i < hej.size; i++) {
    //     printf("%d -> %d", hej.arr[i].get_id(), (int)hej.arr[i].get_dest_node());
    // }
    cuda_simulator sim;
    sim.simulate_2(node_to_edge_d, node_to_invariant_d, edge_to_guard_d, edge_to_update_d, 2, timers_d);
    
    

    return 0;
}


