`ifndef CONF_MASTER_READ_GUARD
`define CONF_MASTER_READ_GUARD

class configure_master_read extends virtual_sequence_base;
  
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

  `uvm_object_utils(configure_master_read)   

  function new(string name = "configure_master_read");
    super.new(name);
  endfunction:new 

  function randomize();
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
    p_sequencer.p_reg_model.ctrl.write(status,{rx_lim,5'b0,'h7});       //set transfer limit | enable device | enable ack | mode
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

`endif