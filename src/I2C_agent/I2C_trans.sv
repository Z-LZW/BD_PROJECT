`ifndef I2C_TRANS_GUARD
`define I2C_TRANS_GUARD

class i2c_trans extends uvm_sequence_item;

  rand i2c_trans_kind_t kind          ; //read | write
  rand bit [7-1:0]      addr          ; //address
  rand bit [8-1:0]      data_q[$]     ; //data bytes
  rand i2c_resp_kind_t  resp[$]       ; //ack | nack
  rand bit              repeated_start; // 0 -> normal | 1 -> repeated_start

  `uvm_object_utils_begin(i2c_trans)
    `uvm_field_enum(i2c_agent_kind_t,kind,UVM_ALL_ON)
    `uvm_field_int(addr,UVM_ALL_ON)
    `uvm_field_int(data,UVM_ALL_ON)
    `uvm_field_enum(i2c_resp_kind_t,resp,UVM_ALL_ON)
    `uvm_field_int(size,UVM_ALL_ON)
  `uvm_object_utils_end

//------------------------CONSTRAINTS------------------------------//

  constraint size{
    data_q.size() inside {[1:256]};
  }

  constraint resp_size{
    resp.size() == data_q.size();
  }

  solve size before resp_size;

//------------------------------------------------------------------//

  //Constructor
  function new(string name = "i2c_trans");
    super.new(name)
  endfunction

endclass

`endif