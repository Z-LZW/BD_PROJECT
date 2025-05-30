`ifndef CONFIGURE_SLAVE_GUARD
`define CONFIGURE_SLAVE_GUARD

class configure_slave extends virtual_sequence_base;

  uvm_status_e status;
  uvm_reg_data_t data;

  //address register
  rand bit [7-1:0] device_addr;

  //irq mask register
  rand bit         rx_fifo_empty_mask;
  rand bit         tx_fifo_full_mask;
  rand bit         rx_fail_mask;
  rand bit         tx_fail_mask;
  rand bit         rx_done_mask;
  rand bit         tx_done_mask;

  `uvm_object_utils(configure_slave) 

  function new(string name = "configure_slave");
    super.new(name);
  endfunction:new
  
  function randomize();
    assert (std::randomize(device_addr)) else $fatal("randomization failed in slave configuration sequence");

    assert (std::randomize(rx_fifo_empty_mask)) else $fatal("randomization failed in slave configuration sequence");
    assert (std::randomize(tx_fifo_full_mask)) else $fatal("randomization failed in slave configuration sequence");
    assert (std::randomize(rx_fail_mask)) else $fatal("randomization failed in slave configuration sequence");
    assert (std::randomize(tx_fail_mask)) else $fatal("randomization failed in slave configuration sequence");
    assert (std::randomize(rx_done_mask)) else $fatal("randomization failed in slave configuration sequence");
    assert (std::randomize(tx_done_mask)) else $fatal("randomization failed in slave configuration sequence");
  endfunction

  virtual task body();
    p_sequencer.p_reg_model.cmd.write(status,'h1c);                      //clear the interrupt and fifos
    p_sequencer.p_reg_model.addr.write(status,device_addr);              //write the device address

    repeat(256) begin
      p_sequencer.p_reg_model.tx_fifo_data.write(status,data);           //write the data in the tx fifo
    end

     p_sequencer.p_reg_model.irq_mask.write(status,{rx_fifo_empty_mask,
                                                    rx_fifo_empty_mask,
                                                    rx_fail_mask,
                                                    tx_fail_mask,
                                                    rx_done_mask,
                                                    tx_done_mask});       //masking the coresponding interrupts

    p_sequencer.p_reg_model.ctrl.write(status,'h7);                       //set transfer limit | enable device | enable ack | mode
  endtask
endclass

`endif