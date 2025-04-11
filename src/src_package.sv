`ifndef SRC_PKG_GUARD
`define SRC_PKG_GUARD

package src_package;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import system_package::*;
  import apb_package::*;
  import i2c_package::*;

  `include "register_model/reg_model.sv"
  `include "register_model/reg_adapter.sv"
  `include "../v_src/virtual_sequencer.sv"
  `include "environment.sv"

endpackage

`endif