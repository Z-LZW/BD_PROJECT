`ifndef SYSTEM_PACKAGE_GUARD
`define SYSTEM_PACKAGE_GUARD

package system_package;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "system_trans.sv"
  `include "system_driver.sv"
  `include "system_monitor.sv"
  `include "system_sequence.sv"
  `include "system_sequencer.sv"
  `include "system_agent.sv"

endpackage

`endif