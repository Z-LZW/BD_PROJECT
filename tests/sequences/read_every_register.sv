`ifndef READ_EVERY_REGISTER_GUARD
`define READ_EVERY_REGISTER_GUARD

class read_every_register extends virtual_sequence_base;

  `uvm_object_utils(read_every_register)

  uvm_status_e status;

  function new(string name = "read_every_register");
    super.new(name);
  endfunction:new 

  virtual task body();
    //p_sequencer.p_reg_model.rx_fifo_data.mirror(status,UVM_CHECK);
    p_sequencer.p_reg_model.addr.mirror(status,UVM_CHECK);
    p_sequencer.p_reg_model.ctrl.mirror(status,UVM_CHECK);
    p_sequencer.p_reg_model.status.mirror(status,UVM_CHECK);
    p_sequencer.p_reg_model.irq.mirror(status,UVM_CHECK);
    p_sequencer.p_reg_model.irq_mask.mirror(status,UVM_CHECK);
    p_sequencer.p_reg_model.divider.mirror(status,UVM_CHECK);   
  endtask
endclass

`endif