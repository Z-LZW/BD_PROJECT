`ifndef SYSTEM_TRANS_GUARD
`define SYSTEM_TRANS_GUARD

class system_trans extends uvm_sequence_item;

  rand bit [ 6-1:0] reset_width;        //width of the reset [in time units]
  rand bit [13-1:0] delay_before_reset; //time units to pass untill reset is asserted

  //factory
  `uvm_object_utils_begin(system_trans)
    `uvm_field_int(reset_width       ,UVM_ALL_ON)
    `uvm_field_int(delay_before_reset,UVM_ALL_ON)
  `uvm_object_utils_end

  constraint reset_width_c {
    reset_width >= 35;
  }

  function new (string name = "system_trans");
    super.new(name);
  endfunction

endclass

`endif