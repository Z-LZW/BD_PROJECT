`ifndef TOP_GUARD
`define TOP_GUARD

`timescale 1ns/1ns

module top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import apb_package::*;
  import system_package::*;
  `include "../tests/base_test.sv"

  system_interface system_if(clk,rst_n);
  apb_interface apb_master_if(clk,rst_n);
  apb_interface apb_slave_if(clk,rst_n);

  initial begin
    uvm_config_db #(virtual interface system_interface::set(null,"*.system_agent.*","system_vif",system_if));
    uvm_config_db #(virtual interface apb_interface#(32,32))::set(null,"*.master_agent.*","apb_vif",apb_master_if);
    uvm_config_db #(virtual interface apb_interface#(32,32))::set(null,"*.slave_agent.*","apb_vif",apb_slave_if);
    run_test();
  end

endmodule

`endif