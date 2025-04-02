`ifndef APB_TRANS_GUARD
`define APB_TRANS_GUARD

class apb_trans #(AW=32,DW=32) extends uvm_sequence_item;

  //Master relevant
  rand apb_trans_kind_t kind       ;  //read | write
  rand bit [AW-1:0]     addr       ;  //address
  rand bit [DW-1:0]     data       ;  //read | write data
  rand int unsigned     delay      ;  //delay between apb transactions
  rand apb_delay_kind_t delay_kind ;

  //Slave relevant
  rand apb_trans_resp_t resp       ;  //response type: OK | ERR
  rand int unsigned     ready_delay;  //response delay [pready]

  //Factory
  `uvm_object_param_utils_begin(apb_trans)
    `uvm_field_enum(apb_trans_kind_t, kind, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(delay, UVM_ALL_ON)
    `uvm_field_int(ready_delay, UVM_ALL_ON)
    `uvm_field_enum(apb_trans_resp_t, resp, UVM_ALL_ON)    
    `uvm_field_enum(apb_delay_kind_t, delay_kind, UVM_ALL_ON)
  `uvm_object_utils_end

//------------------------CONSTRAINTS------------------------------//

  constraint delay_c {
    (delay_kind == ZERO)    -> delay == 0;
    (delay_kind == SHORT)   -> delay inside {[1 : 5]};
    (delay_kind == MEDIUM)  -> delay inside {[6 :10]};
    (delay_kind == LARGE)   -> delay inside {[11:19]};
    (delay_kind == MAX)     -> delay >= 20;
                               delay >= 0 ; 
                               delay <= 100;           //max delay between trans 
  }

  constraint ready_delay_c {
    ready_delay inside {[0:10]};
  }

  constraint delay_order_c {
    solve delay_kind before delay;
  }

//------------------------------------------------------------------//

  //Constructor
  function new (string name = "apb_trans");
    super.new(name);
  endfunction

endclass

`endif