`ifndef SYSTEM_BASE_SEQ_GUARD
`define SYSTEM_BASE_SEQ_GUARD

class system_base_sequence extends uvm_sequence #(system_trans);

  `uvm_object_utils(system_base_sequence)

  function new(string name = "system_base_sequence");
    super.new(name);
  endfunction: new

  virtual task pre_body();
    starting_phase.raise_objection(this);
  endtask

  virtual task post_body();
    starting_phase.drop_objection(this);
  endtask

endclass

`endif