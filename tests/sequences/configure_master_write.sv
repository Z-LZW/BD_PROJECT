`ifndef CONF_MASTER_WRITE_GUARD
`define CONF_MASTER_WRITE_GUARD

class configure_master_write extends virtual_sequence_base;
  
  uvm_status_e status;

  //address register
  rand bit [7-1:0] target_addr;

  //control register
  rand bit [9-1:0] tx_lim    ;
  bit [8-1:0] tx_lim_actual;

  //irq mask register
  rand bit         rx_fifo_empty_mask;
  rand bit         tx_fifo_full_mask;
  rand bit         rx_fail_mask;
  rand bit         tx_fail_mask;
  rand bit         rx_done_mask;
  rand bit         tx_done_mask;

  rand bit         read;

  rand bit [8-1:0] tx_fifo_data;

  //divider
  rand bit [16-1:0] divider;

  `uvm_object_utils(configure_master_write)   

  function new(string name = "configure_master_write");
    super.new(name);
  endfunction:new 

  function randomize_conf();
    assert (std::randomize(target_addr)) else $fatal("randomization failed in master write configuration sequence");

    assert (std::randomize(tx_lim) with {tx_lim <= 256;}) else $fatal("randomization failed in master write configuration sequence");

    assert (std::randomize(rx_fifo_empty_mask)) else $fatal("randomization failed in master write configuration sequence");
    assert (std::randomize(tx_fifo_full_mask)) else $fatal("randomization failed in master write configuration sequence");
    assert (std::randomize(rx_fail_mask)) else $fatal("randomization failed in master write configuration sequence");
    assert (std::randomize(tx_fail_mask)) else $fatal("randomization failed in master write configuration sequence");
    assert (std::randomize(rx_done_mask)) else $fatal("randomization failed in master write configuration sequence");
    assert (std::randomize(tx_done_mask)) else $fatal("randomization failed in master write configuration sequence");

    assert (std::randomize(read)) else $fatal("randomization failed in master write configuration sequence");

    assert (std::randomize(divider)) else $fatal("randomization failed in master write configuration sequence");
  endfunction

  function print_configurations();
    `uvm_info(get_type_name(),$sformatf("DUT will be configured with:\n
    MODE: MASTER\n
    OPERATION: WRITE\n
    DIVIDER: %0d\n
    RX_LIM: 0\n
    TX_LIM: %0d\n
    ADDRESS: %h\n",divider,tx_lim,target_addr),UVM_LOW)
  endfunction

  virtual task body();

    print_configurations();

    if(tx_lim == 256)
      tx_lim_actual = 0;
    else
      tx_lim_actual = tx_lim;
      
    p_sequencer.p_reg_model.divider.write(status,divider);              //set divider
    p_sequencer.p_reg_model.ctrl.write(status,{8'b0,tx_lim_actual,5'b0,3'h7}); //set transfer limit | enable device | enable ack | mode
    p_sequencer.p_reg_model.cmd.write(status,'h1c);                     //clear the interrupt and fifos
    p_sequencer.p_reg_model.addr.write(status,{target_addr,8'b0});      //write the target address

    repeat(tx_lim) begin
      assert (std::randomize(tx_fifo_data)) else $fatal("randomization failed in master write configuration sequence");
      p_sequencer.p_reg_model.tx_fifo_data.write(status,tx_fifo_data);          //write the data in the tx fifo
    end

    p_sequencer.p_reg_model.irq_mask.write(status,{rx_fifo_empty_mask,
                                                   rx_fifo_empty_mask,
                                                   rx_fail_mask,
                                                   tx_fail_mask,
                                                   rx_done_mask,
                                                   tx_done_mask});      //masking the coresponding interrupts

    p_sequencer.p_reg_model.cmd.write(status,{1'b0,1'b1});              //initiate write
      
  endtask
endclass

`endif