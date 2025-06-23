`ifndef I2C_SLAVE_SEQ_GUARD
`define I2C_SLAVE_SEQ_GUARD

class i2c_slave_seq extends virtual_sequence_base;

  i2c_trans trans;
  bit [9-1:0] size;

  `uvm_object_utils(i2c_slave_seq)

  function new(string name = "i2c_slave_seq");
    super.new(name);
  endfunction:new 

  virtual task body();
   `uvm_do_on_with(trans,p_sequencer.i2c_slave_seqr,{data_q.size() == size;
                                                     foreach (resp[i]) resp[i] == I2C_ACK;
                                                     clock_strech == 0;})
  endtask

endclass

`endif