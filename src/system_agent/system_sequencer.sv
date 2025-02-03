`ifndef SYSTEM_SEQUENCER_GUARD
`define SYSTEM_SEQUENCER_GUARD

class system_sequencer extends uvm_sequencer #(system_trans);

  `uvm_component_utils(system_sequencer)

  function new(input string name, uvm_component parent);
      super.new(name, parent);
  endfunction : new

endclass

`endif