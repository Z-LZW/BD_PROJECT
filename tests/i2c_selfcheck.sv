`ifndef I2C_SELFCHECK_GUARD
`define I2C_SELFCHECK_GUARD

class i2c_master_sequence_arb extends virtual_sequence_base;

  i2c_trans trans;

  `uvm_object_utils(i2c_master_sequence_arb)

  function new(string name = "i2c_master_sequence_arb");
    super.new(name);
  endfunction:new 

  virtual task body();
   `uvm_do_on_with(trans,p_sequencer.i2c_master_seqr_arb,{trans.kind == I2C_WRITE; trans.addr == 7'h55; trans.data_q.size() == 1; trans.repeated_start == 0; trans.resp[trans.data_q.size()-1] == I2C_NACK;trans.clock_period == 8;})
   #200;
    //`uvm_do_on_with(trans,p_sequencer.i2c_master_seqr,{trans.kind == I2C_WRITE; trans.addr == 7'h55; trans.data_q.size() == 1; trans.repeated_start == 0;})
    //`uvm_do_on_with(trans,p_sequencer.i2c_master_seqr,{trans.kind == I2C_WRITE; trans.addr == 7'h55; trans.data_q.size() == 3; trans.repeated_start == 0;})
   //#200;
   //  `uvm_do_on_with(trans,p_sequencer.i2c_master_seqr,{trans.kind == I2C_WRITE; trans.addr == 7'h5a; trans.data_q.size() == 1; trans.repeated_start == 0;})
   //  #200;
   //#200;
   //  `uvm_do_on_with(trans,p_sequencer.i2c_master_seqr,{trans.kind == I2C_WRITE; trans.addr == 7'h55; trans.data_q.size() == 3; trans.repeated_start == 0;})
  endtask

endclass

class i2c_master_sequence extends virtual_sequence_base;

  i2c_trans trans;

  `uvm_object_utils(i2c_master_sequence)

  function new(string name = "i2c_master_sequence");
    super.new(name);
  endfunction:new 

  virtual task body();
   `uvm_do_on_with(trans,p_sequencer.i2c_master_seqr,{trans.kind == I2C_READ; trans.addr == 7'h55; trans.data_q.size() == 1; trans.repeated_start == 0; trans.resp[trans.data_q.size()-1] == I2C_NACK;trans.clock_period == 16;})
   #200;
   //`uvm_do_on_with(trans,p_sequencer.i2c_master_seqr,{trans.kind == I2C_WRITE; trans.addr == 7'h55; trans.data_q.size() == 1; trans.repeated_start == 0;})
    //`uvm_do_on_with(trans,p_sequencer.i2c_master_seqr,{trans.kind == I2C_WRITE; trans.addr == 7'h55; trans.data_q.size() == 3; trans.repeated_start == 0;})
   //#200;
   //  `uvm_do_on_with(trans,p_sequencer.i2c_master_seqr,{trans.kind == I2C_WRITE; trans.addr == 7'h5a; trans.data_q.size() == 1; trans.repeated_start == 0;})
   //  #200;
   //#200;
   //  `uvm_do_on_with(trans,p_sequencer.i2c_master_seqr,{trans.kind == I2C_WRITE; trans.addr == 7'h55; trans.data_q.size() == 3; trans.repeated_start == 0;})
  endtask

endclass

class i2c_slave_sequence extends virtual_sequence_base;

  i2c_trans trans;

  `uvm_object_utils(i2c_slave_sequence)

  function new(string name = "i2c_slave_sequence");
    super.new(name);
  endfunction:new 

  virtual task body();
   `uvm_do_on_with(trans,p_sequencer.i2c_slave_seqr,{trans.resp.size() > 2;trans.clock_strech == 1;})
    
   //`uvm_do_on_with(trans,p_sequencer.i2c_slave_seqr,{trans.resp.size() > 4; trans.clock_strech == 1;})
   
   // `uvm_do_on(trans,p_sequencer.i2c_slave_seqr)
// 
   // `uvm_do_on_with(trans,p_sequencer.i2c_slave_seqr,{trans.data_q.size() > 1;})
// 
   // `uvm_do_on_with(trans,p_sequencer.i2c_slave_seqr,{trans.resp.size() > 4;trans.resp[1] == I2C_NACK;})
    
  endtask

endclass

class i2c_sequence extends virtual_sequence_base;

   i2c_master_sequence master_seq;
   i2c_slave_sequence  slave_seq;

   i2c_master_sequence_arb master_arb_Seq;
   
   `uvm_object_utils(i2c_sequence)
   // Declare which is the virtual sequencer
   //`uvm_declare_p_sequencer(virtual_sequencer)   

   function new(string name = "i2c_sequence");
      super.new(name);
   endfunction:new 
   
   virtual task body();
      fork
         `uvm_do(master_seq)
         `uvm_do(master_arb_Seq)
         `uvm_do(slave_seq)
      join
      //#500;
   endtask

endclass

class i2c_selfcheck extends base_test;

   `uvm_component_utils(i2c_selfcheck)
   
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction
   
   virtual function void build_phase(uvm_phase phase);
      // Configuration
      uvm_config_db #(uvm_object_wrapper)::set(this,"env.v_sequencer.run_phase", "default_sequence", i2c_sequence::get_type());
      
      super.build_phase(phase);
   endfunction
   
endclass



`endif