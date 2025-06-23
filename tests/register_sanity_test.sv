`ifndef REGISTER_SANITY_TEST
`define REGISTER_SANITY_TEST

class register_sanity_test extends base_test;

  system_reset_sequence system_seq;
  write_every_register write_seq;
  read_every_register read_seq;

  `uvm_component_utils(register_sanity_test)
   
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
   
  virtual function void build_phase(uvm_phase phase);
    // Configuration
    uvm_config_db #(int)::set(this,"env", "number_of_masters",1);
    uvm_config_db #(int)::set(this,"env", "number_of_slaves",1);
    uvm_config_db #(int)::set(this,"env.i2c_slave_agent[0]", "dev_addr",0);
    
    super.build_phase(phase);
    system_seq = system_reset_sequence::type_id::create("system_seq",this);
    write_seq  = write_every_register::type_id::create("write_seq",this);
    read_seq  = read_every_register::type_id::create("read_seq",this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    super.run_phase(phase);

    write_seq.start(env.v_sequencer);
    system_seq.start(env.v_sequencer);
    env.reg_model.reset();
    read_seq.start(env.v_sequencer);

    write_seq.start(env.v_sequencer);
    read_seq.start(env.v_sequencer);
    phase.drop_objection(this);
  endtask
   
endclass

`endif