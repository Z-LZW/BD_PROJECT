`ifndef VIRTUAL_SEQUENCER_GUARD
`define VIRTUAL_SEQUENCER_GUARD

class virtual_sequencer#(AW=32,DW=32) extends uvm_sequencer;

  `uvm_component_param_utils(virtual_sequencer#(AW,DW))

  apb_sequencer #(AW,DW) apb_master_seqr;
  apb_sequencer #(AW,DW) apb_slave_seqr; 

  i2c_sequencer i2c_master_seqr;
  //i2c_sequencer i2c_master_seqr_arb;
  i2c_sequencer i2c_slave_seqr; 

  reg_blk p_reg_model;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

endclass

class virtual_sequence_base extends uvm_sequence;

  `uvm_object_param_utils(virtual_sequence_base)
  
  // Declare which is the virtual sequencer
  `uvm_declare_p_sequencer(virtual_sequencer#(6,32))
  
  function new(string name = "virtual_sequence_base");
    super.new(name);
  endfunction:new
  
  // Raising objection before starting body
  virtual task pre_body();
    //starting_phase.raise_objection(this);
  endtask
  
  // Droping objection after finishing body
  virtual task post_body();
    //starting_phase.drop_objection(this);
  endtask
  
endclass:virtual_sequence_base

`endif