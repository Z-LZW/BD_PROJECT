`ifndef BASE_TEST_GUARD
`define BASE_TEST_GUARD

class base_test extends uvm_test;

  `uvm_component_utils(base_test)

  environment#(6,32) env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    //apb config
    uvm_config_db #(uvm_bitstream_t)::set(this,"env.apb_master_agent", "agent_kind", APB_MASTER);
    uvm_config_db #(uvm_bitstream_t)::set(this,"env.apb_master_agent", "is_active", UVM_ACTIVE);
    uvm_config_db #(int)::set(this,"env.apb_master_agent.monitor", "has_checks", 1);
    uvm_config_db #(int)::set(this,"env.apb_master_agent.monitor", "has_coverage", 1);

    uvm_config_db #(uvm_bitstream_t)::set(this,"env.apb_slave_agent", "agent_kind", APB_SLAVE);
    uvm_config_db #(uvm_bitstream_t)::set(this,"env.apb_slave_agent", "is_active", UVM_ACTIVE);
    uvm_config_db #(int)::set(this,"env.apb_slave_agent.monitor", "has_checks", 1);
    uvm_config_db #(int)::set(this,"env.apb_slave_agent.monitor", "has_coverage", 1);

    //system agent
    uvm_config_db #(uvm_bitstream_t)::set(this,"env.sys_agent","is_active",UVM_ACTIVE);

    env = environment#(6,32)::type_id::create("env",this);
  endfunction

  virtual function void start_of_simulation_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

endclass

`endif