`ifndef READ_RX_FIFO_GUARD
`define READ_RX_FIFO_GUARD

class read_rx_fifo extends virtual_sequence_base;

  uvm_status_e status;
  uvm_reg_data_t data;

  bit [9-1:0] byte_cnt;
  
  uvm_event start_read_rx_fifo;
  uvm_event done_read_rx_fifo;

  `uvm_object_utils(read_rx_fifo) 

  function new(string name = "read_rx_fifo");
    super.new(name);
    start_read_rx_fifo = uvm_event_pool::get_global("start_read_rx_fifo");
    done_read_rx_fifo  = uvm_event_pool::get_global("done_read_rx_fifo");
  endfunction:new

  virtual task body();

    //start_read_rx_fifo.wait_trigger(); //wait for a read transaction to end on the I2C

    p_sequencer.p_reg_model.status.mirror(status,UVM_CHECK);
    p_sequencer.p_reg_model.status.read(status,data);

    byte_cnt = data[16:8];

    repeat(byte_cnt) begin
      p_sequencer.p_reg_model.rx_fifo_data.read(status,data);
    end

    done_read_rx_fifo.trigger();

  endtask
endclass

`endif