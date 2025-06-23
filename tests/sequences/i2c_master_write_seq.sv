`ifndef I2C_MASTER_WRITE_SEQUENCE_GUARD
`define I2C_MASTER_WRITE_SEQUENCE_GUARD

class i2c_master_wirte_sequence extends virtual_sequence_base;
  
  i2c_trans trans;
  rand bit [6:0] target_addr;

  `uvm_object_utils(i2c_master_wirte_sequence)

  function new(string name = "i2c_master_wirte_sequence");
    super.new(name);
  endfunction:new 

  virtual task body();
   `uvm_do_on_with(trans,p_sequencer.i2c_master_seqr,{kind == I2C_WRITE; addr == target_addr; repeated_start == 0;})
  endtask   
endclass

`endif