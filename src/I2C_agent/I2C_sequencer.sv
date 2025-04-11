`ifndef I2C_SEQUENCER_GUARD
`define I2C_SEQUENCER_GUARD

class i2c_sequencer extends uvm_sequencer #(i2c_trans);

  `uvm_component_utils(i2c_sequencer)

  function new(input string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

endclass: i2c_sequencer

`endif