`ifndef READ_IRQ_GUARD
`define READ_IRQ_GUARD

class read_irq extends virtual_sequence_base;

  uvm_status_e status;
  uvm_reg_data_t data;

  `uvm_object_utils(read_irq) 

  function new(string name = "read_irq");
    super.new(name);
  endfunction:new

  virtual task body();
    p_sequencer.p_reg_model.irq.mirror(status);
  endtask
endclass

`endif