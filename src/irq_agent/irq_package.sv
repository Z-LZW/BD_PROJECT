`ifndef IRQ_PACKAGE_GUARD
`define IRQ_PACKAGE_GUARD

package irq_package;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "irq_monitor.sv"
  `include "irq_agent.sv"

endpackage

`endif