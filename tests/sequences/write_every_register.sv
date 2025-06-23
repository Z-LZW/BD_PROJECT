`ifndef WRITE_EVERY_REGISTER_GUARD
`define WRITE_EVERY_REGISTER_GUARD

class write_every_register extends virtual_sequence_base;

  uvm_status_e status;
  rand uvm_reg_data_t data;

  `uvm_object_utils(write_every_register)   

  function new(string name = "write_every_register");
    super.new(name);
  endfunction:new 

  virtual task body();
    assert(std::randomize(data));
    p_sequencer.p_reg_model.tx_fifo_data.write(status,data);

    assert(std::randomize(data));
    p_sequencer.p_reg_model.addr.write(status,data);

    assert(std::randomize(data));
    p_sequencer.p_reg_model.ctrl.write(status,data);

    assert(std::randomize(data));
    p_sequencer.p_reg_model.cmd.write(status,data);

    assert(std::randomize(data));
    p_sequencer.p_reg_model.irq_mask.write(status,data);

    assert(std::randomize(data));
    p_sequencer.p_reg_model.divider.write(status,data);       
  endtask
endclass

`endif