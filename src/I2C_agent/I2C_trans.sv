`ifndef I2C_TRANS_GUARD
`define I2C_TRANS_GUARD

class i2c_trans extends uvm_sequence_item;

  rand i2c_trans_kind_t kind          ; //read | write
  rand bit [7-1:0]      addr          ; //address
  rand bit [8-1:0]      data_q[$]     ; //data bytes
  rand i2c_resp_kind_t  resp[$]       ; //ack | nack
  rand bit              repeated_start; // 0 -> normal | 1 -> repeated_start
  rand bit              clock_strech  ; // 0 -> normal | 1 -> clock_streaching
  rand bit [8-1:0]      clock_period  ;
  bit                   arb_lost      ;

  `uvm_object_utils_begin(i2c_trans)
    `uvm_field_enum(i2c_trans_kind_t,kind,UVM_ALL_ON)
    `uvm_field_int(addr,UVM_ALL_ON)
    `uvm_field_queue_int(data_q,UVM_ALL_ON)
    `uvm_field_queue_enum(i2c_resp_kind_t,resp,UVM_ALL_ON)
    `uvm_field_int(repeated_start,UVM_ALL_ON)
    `uvm_field_int(clock_strech,UVM_ALL_ON)
    `uvm_field_int(clock_period,UVM_ALL_ON)
    `uvm_field_int(arb_lost,UVM_ALL_ON)
  `uvm_object_utils_end

//------------------------CONSTRAINTS------------------------------//

  constraint clock_period_c{
    clock_period % 4 == 0;
    clock_period inside {[4:128]};
  }

  constraint size_c{
    data_q.size() inside {[1:256]};
  }

  constraint resp_size{
    resp.size() == data_q.size() + 1;
  }

  constraint resp_c{
     foreach(resp[i]) soft resp[i] == I2C_ACK;
  }

  constraint size_order{
    solve data_q.size before resp.size;
  }

//------------------------------------------------------------------//

  //Constructor
  function new(string name = "i2c_trans");
    super.new(name);
  endfunction

endclass

`endif