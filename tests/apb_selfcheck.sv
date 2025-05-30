`ifndef APB_SELFCHECK
`define APB_SELFCHECK

class apb_master_sequence extends virtual_sequence_base;

  //apb_trans #(32,32) apb_read, apb_write;

  uvm_status_e status;
  uvm_reg_data_t data;

  `uvm_object_utils(apb_master_sequence)   

  function new(string name = "apb_master_sequence");
    super.new(name);
  endfunction:new 

  virtual task body();

    p_sequencer.p_reg_model.tx_fifo_data.write(status,'hff);
    p_sequencer.p_reg_model.rx_fifo_data.write(status,'hff);
    p_sequencer.p_reg_model.addr.write(status,'h7f7f);
    p_sequencer.p_reg_model.ctrl.write(status,'hff03);
    p_sequencer.p_reg_model.cmd.write(status,'h3f);
    p_sequencer.p_reg_model.status.write(status,'h1f);
    p_sequencer.p_reg_model.irq.write(status,'h3f);
    p_sequencer.p_reg_model.irq_mask.write(status,'h3f);
    p_sequencer.p_reg_model.divider.write(status,'hffff);

    p_sequencer.p_reg_model.tx_fifo_data.mirror(status,UVM_CHECK);
    p_sequencer.p_reg_model.rx_fifo_data.mirror(status,UVM_CHECK);
    p_sequencer.p_reg_model.addr.mirror(status,UVM_CHECK);
    p_sequencer.p_reg_model.ctrl.mirror(status,UVM_CHECK);
    p_sequencer.p_reg_model.cmd.mirror(status,UVM_CHECK);
    p_sequencer.p_reg_model.status.mirror(status,UVM_CHECK);
    p_sequencer.p_reg_model.irq.mirror(status,UVM_CHECK);
    p_sequencer.p_reg_model.irq_mask.mirror(status,UVM_CHECK);
    p_sequencer.p_reg_model.divider.mirror(status,UVM_CHECK);
    
  endtask

endclass

class apb_slave_sequence extends virtual_sequence_base;

  apb_trans #(6,32) trans;

  `uvm_object_utils(apb_slave_sequence)   

  function new(string name = "apb_slave_sequence");
    super.new(name);
  endfunction:new 

  virtual task body();

    repeat(9) `uvm_do_on(trans,p_sequencer.apb_slave_seqr)

    `uvm_do_on_with(trans,p_sequencer.apb_slave_seqr,{trans.data == 'h00;})
    `uvm_do_on_with(trans,p_sequencer.apb_slave_seqr,{trans.data == 'h00;})
    `uvm_do_on_with(trans,p_sequencer.apb_slave_seqr,{trans.data == 'h7f7f;})
    `uvm_do_on_with(trans,p_sequencer.apb_slave_seqr,{trans.data == 'hff03;})
    `uvm_do_on_with(trans,p_sequencer.apb_slave_seqr,{trans.data == 'h00;})
    `uvm_do_on_with(trans,p_sequencer.apb_slave_seqr,{trans.data == 'h00;})
    `uvm_do_on_with(trans,p_sequencer.apb_slave_seqr,{trans.data == 'h00;})
    `uvm_do_on_with(trans,p_sequencer.apb_slave_seqr,{trans.data == 'h3f;})
    `uvm_do_on_with(trans,p_sequencer.apb_slave_seqr,{trans.data == 'hffff;})
  endtask

endclass

class apb_sequence extends virtual_sequence_base;

   apb_master_sequence master_seq;
   apb_slave_sequence  slave_seq;
   
   `uvm_object_utils(apb_sequence)
   // Declare which is the virtual sequencer
   //`uvm_declare_p_sequencer(virtual_sequencer)   

   function new(string name = "apb_sequence");
      super.new(name);
   endfunction:new 
   
   virtual task body();
      fork
         `uvm_do(master_seq);
        // master_seq.start(null);

         `uvm_do(slave_seq);
      join
      //#500;
   endtask

endclass

class apb_selfcheck extends base_test;

   `uvm_component_utils(apb_selfcheck)
   
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction
   
   virtual function void build_phase(uvm_phase phase);
      // Configuration
      uvm_config_db #(int)::set(this,"env", "number_of_masters",1);
      uvm_config_db #(int)::set(this,"env", "number_of_slaves",1);
      uvm_config_db #(uvm_object_wrapper)::set(this,"env.v_sequencer.run_phase", "default_sequence", apb_sequence::get_type());
      
      super.build_phase(phase);
   endfunction
   
endclass

`endif