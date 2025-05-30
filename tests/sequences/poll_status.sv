`ifndef POLL_STATUS_GUARD
`define POLL_STATUS_GUARD

class poll_status extends virtual_sequence_base;

  uvm_status_e status;
  uvm_reg_data_t data;

  `uvm_object_utils(poll_status) 

  function new(string name = "poll_status");
    super.new(name);
  endfunction:new

  virtual task body();
    p_sequencer.p_reg_model.status.read(status,data);
  endtask
endclass

`endif