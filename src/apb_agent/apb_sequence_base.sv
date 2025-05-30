`ifndef APB_SEQUENCE_BASE_GUARD
`define APB_SEQUENCE_BASE_GUARD

class apb_sequence_base #(AW=32,DW=32) extends uvm_sequence_base;

  apb_trans#(AW,DW) trans;

  `uvm_object_param_utils(apb_sequence_base #(AW,DW))

  function new(string name = "apb_sequence_base");
    super.new(name);
  endfunction:new

  // Raising objection before starting body
  virtual task pre_body();
    starting_phase.raise_objection(this);
  endtask
  
  // Droping objection after finishing body
  virtual task post_body();
    starting_phase.drop_objection(this);
  endtask

endclass

`endif