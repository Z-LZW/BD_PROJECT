`ifndef COV_SELFCHECK
`define COV_SELFCHECK

class apb_master_sequence extends virtual_sequence_base;
  
  uvm_status_e status;
  uvm_reg_data_t data;

  uvm_event start_read_rx_fifo;
  uvm_event done_read_rx_fifo;

  //address register
  rand bit [7-1:0] target_addr;

  //control register
  rand bit [8-1:0] rx_lim    ;

  //irq mask register
  rand bit         rx_fifo_empty_mask;
  rand bit         tx_fifo_full_mask;
  rand bit         rx_fail_mask;
  rand bit         tx_fail_mask;
  rand bit         rx_done_mask;
  rand bit         tx_done_mask;

  //divider
  rand bit [16-1:0] divider;

  `uvm_object_utils(apb_master_sequence)   

  function new(string name = "apb_master_sequence");
    super.new(name);
  endfunction:new 

  function void randomize_conf();
    assert (std::randomize(target_addr)) else $fatal("randomization failed in master read configuration sequence");

    assert (std::randomize(rx_lim)) else $fatal("randomization failed in master read configuration sequence");

    assert (std::randomize(rx_fifo_empty_mask)) else $fatal("randomization failed in master read configuration sequence");
    assert (std::randomize(tx_fifo_full_mask)) else $fatal("randomization failed in master read configuration sequence");
    assert (std::randomize(rx_fail_mask)) else $fatal("randomization failed in master read configuration sequence");
    assert (std::randomize(tx_fail_mask)) else $fatal("randomization failed in master read configuration sequence");
    assert (std::randomize(rx_done_mask)) else $fatal("randomization failed in master read configuration sequence");
    assert (std::randomize(tx_done_mask)) else $fatal("randomization failed in master read configuration sequence");

    assert (std::randomize(divider)) else $fatal("randomization failed in master read configuration sequence");
  endfunction

  virtual task body();
    p_sequencer.p_reg_model.divider.write(status,divider);              //set divider
    p_sequencer.p_reg_model.ctrl.write(status,{rx_lim,13'b0,3'h7});     //set transfer limit | enable device | enable ack | mode
    p_sequencer.p_reg_model.cmd.write(status,'h1c);                     //clear the interrupt and fifos
    p_sequencer.p_reg_model.addr.write(status,{target_addr,8'b0});      //write the target address

    p_sequencer.p_reg_model.irq_mask.write(status,{rx_fifo_empty_mask,
                                                   rx_fifo_empty_mask,
                                                   rx_fail_mask,
                                                   tx_fail_mask,
                                                   rx_done_mask,
                                                   tx_done_mask});      //masking the coresponding interrupts

    p_sequencer.p_reg_model.cmd.write(status,'h2);                      //initiate read
      
  endtask
endclass

class apb_slave_sequence extends virtual_sequence_base;

   `uvm_object_utils(apb_slave_sequence)

   apb_trans#(6,32) trans;

   function new(string name = "apb_slave_sequence");
     super.new(name);
   endfunction:new 

   virtual task body();
     //write_tx(3);
     configre();
   endtask

   task configre();
      repeat(6) begin
        `uvm_do_on_with(trans,p_sequencer.apb_slave_seqr,{trans.resp == APB_OKAY;})
      end
   endtask

   task write_tx(int number_of_bytes);
      repeat(number_of_bytes) begin 
         `uvm_do_on_with(trans,p_sequencer.apb_slave_seqr,{trans.resp == APB_OKAY;})
      end
   endtask

endclass

class i2c_master_sequence extends virtual_sequence_base;

  i2c_trans trans;
  rand bit [6:0] t_addr;

  `uvm_object_utils(i2c_master_sequence)

  function new(string name = "i2c_master_sequence");
    super.new(name);
  endfunction:new 

  virtual task body();
   `uvm_do_on_with(trans,p_sequencer.i2c_master_seqr,{kind == I2C_WRITE; addr == t_addr; data_q.size() == 3; repeated_start == 0;clock_period == 20;})
  endtask   

endclass

class i2c_slave_sequence extends virtual_sequence_base;

  i2c_trans trans;

  `uvm_object_utils(i2c_slave_sequence)

  function new(string name = "i2c_slave_sequence");
    super.new(name);
  endfunction:new 

  virtual task body();
   `uvm_do_on_with(trans,p_sequencer.i2c_slave_seqr,{trans.resp.size() == 4;foreach (trans.resp[i]) trans.resp[i] == I2C_ACK;trans.clock_strech == 1;})
  endtask

endclass

class cov_selfcheck extends base_test;

   `uvm_component_utils(cov_selfcheck)

   bit [6:0] number_of_masters = 1;
   bit [6:0] number_of_slaves  = 1;

   randc bit [6:0] dev_addr;

   apb_master_sequence apb_master_seq;
   apb_slave_sequence  apb_slave_seq ;

   i2c_master_sequence i2c_master_seq;
   i2c_slave_sequence  i2c_slave_seq ;
   
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction
   
   virtual function void build_phase(uvm_phase phase);
      // Configuration
      `uvm_info(get_type_name(),"WE ARE SETTING THE ENV VARIABLES",UVM_MEDIUM)

      uvm_config_db #(int)::set(this,"env", "number_of_masters",number_of_masters);
      uvm_config_db #(int)::set(this,"env", "number_of_slaves",number_of_slaves);

      super.build_phase(phase);

      for(int i=0; i<number_of_slaves; i++) begin
         assert (std::randomize(dev_addr));
         uvm_config_db #(int)::set(this,$sformatf("env.i2c_slave_agent[%0d]",i), "dev_addr",  dev_addr); //TBD change scope
      end

      apb_master_seq = apb_master_sequence::type_id::create("apb_master_seq",this);
      apb_slave_seq  = apb_slave_sequence::type_id::create("apb_slave_seq",this);

      i2c_master_seq = i2c_master_sequence::type_id::create("i2c_master_seq",this);
      i2c_slave_seq  = i2c_slave_sequence::type_id::create("i2c_slave_seq",this);
      
   endfunction

   virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);
      
      phase.raise_objection(this);
      apb_master_seq.randomize_conf();
      apb_master_seq.target_addr = dev_addr;
      i2c_master_seq.t_addr = dev_addr;
      
      fork
         apb_master_seq.start(env.v_sequencer);
         apb_slave_seq.start(env.v_sequencer);
      join
      fork
         i2c_master_seq.start(env.v_sequencer);
         i2c_slave_seq.start(env.v_sequencer);
         begin

         end
      join_any
      disable fork
      phase.drop_objection(this);
   endtask
   
endclass

`endif