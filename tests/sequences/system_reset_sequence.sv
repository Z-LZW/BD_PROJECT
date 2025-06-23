`ifndef SYSTEM_RESET_SEQ
`define SYSTEM_RESET_SEQ

class system_reset_sequence extends virtual_sequence_base;

  system_trans trans;

  `uvm_object_utils(system_reset_sequence)

  function new(string name = "system_reset_sequence");
    super.new(name);
  endfunction:new 

  virtual task body();
   `uvm_do_on_with(trans,p_sequencer.system_seqr,{delay_before_reset == 100;})
  endtask   
endclass

`endif