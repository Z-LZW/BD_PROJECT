`ifndef I2C_PACKAGE_GUARD
`define I2C_PACKAGE_GUARD

package i2c_package;
  
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "I2C_types.sv"
  `include "I2C_trans.sv"
  `include "I2C_driver.sv"
  `include "I2C_monitor.sv"
  //`include "i2c_base_sequence.sv"
  `include "I2C_sequencer.sv"
  //`include "i2c_coverage.sv"
  `include "I2C_agent.sv"

endpackage

`endif