`ifndef I2C_MASTER_READ_SEQUENCE_GUARD
`define I2C_MASTER_READ_SEQUENCE_GUARD

class i2c_master_read_sequence extends virtual_sequence_base;
  
  i2c_trans trans;
  rand bit [6:0] target_addr;
  rand bit [8:0] transfer_size;

  `uvm_object_utils(i2c_master_read_sequence)

  function void randomize_conf();
    assert (std::randomize(target_addr)) else $fatal("randomization failed in slave configuration sequence");
    assert (std::randomize(transfer_size)) else $fatal("randomization failed in slave configuration sequence");
  endfunction

  function new(string name = "i2c_master_read_sequence");
    super.new(name);
  endfunction:new 

  virtual task body();
   `uvm_do_on_with(trans,p_sequencer.i2c_master_seqr,{kind == I2C_READ;
                                                      addr == target_addr;
                                                      data_q.size() == transfer_size;
                                                      foreach(resp[i]) soft  resp[i] == I2C_ACK;
                                                      resp[data_q.size()-1] == I2C_NACK;
                                                      repeated_start == 0;})
  endtask   
endclass

`endif