`ifndef BASE_TEST_GUARD
`define BASE_TEST_GUARD

class base_test extends uvm_test;

  `uvm_component_utils(test_base)

  environment#(32,32) env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = environment#(32,32)::type_id::create("env",this);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

endclass

`endif