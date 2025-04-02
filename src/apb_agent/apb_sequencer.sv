`ifndef APB_SEQUENCER_GUARD
`define APB_SEQUENCER_GUARD

class apb_sequencer #(AW=32,DW=32) extends uvm_sequencer #(apb_trans #(AW,DW));

  `uvm_component_param_utils(apb_sequencer #(AW,DW))
   
  function new(input string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new
  
endclass:apb_sequencer

`endif