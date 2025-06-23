`ifndef TOP_GUARD
`define TOP_GUARD

`timescale 1ns/1ns

module top;

  localparam AW =  6;
  localparam DW = 32;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import src_package::*;
  import system_package::*;
  import apb_package::*;
  import i2c_package::*;
  `include "../tests/sequences/seq_lib.sv"
  `include "../tests/test_lib.sv"

  system_interface system_if(clk,rst_n,f_clk);
  apb_interface#(AW,DW) apb_master_if(clk,rst_n);
  i2c_interface i2c_if(f_clk,rst_n);

  irq_interface irq_if(clk,rst_n);

  //i2c signals
  triand scl;
  triand sda;

  tran scl_master_link(i2c_if.scl,scl);
  tran sda_master_link(i2c_if.sda,sda);

  initial begin
    uvm_config_db #(virtual interface system_interface)::set(null,"*.sys_agent.*","system_vif",system_if);

    uvm_config_db #(virtual interface apb_interface#(AW,DW))::set(null,"*.apb_master_agent.*","apb_vif",apb_master_if);

    uvm_config_db #(virtual interface i2c_interface)::set(null,"*.i2c_master_agent*","i2c_vif",i2c_if);
    uvm_config_db #(virtual interface i2c_interface)::set(null,"*.i2c_slave_agent*", "i2c_vif",i2c_if);

    uvm_config_db #(virtual interface irq_interface)::set(null,"*.irq_slave_agent.*","irq_vif",irq_if);
    run_test();
  end

apb_i2c_top DUT(
.func_clk(f_clk                ),
.pclk    (clk                  ),
.rst_n   (rst_n                ),
.paddr   (apb_master_if.paddr  ),
.pwdata  (apb_master_if.pwdata ),
.prdata  (apb_master_if.prdata ),
.pwrite  (apb_master_if.pwrite ),
.penable (apb_master_if.penable),
.psel    (apb_master_if.psel   ),
.pready  (apb_master_if.pready ),
.pslverr (apb_master_if.pslverr),
.scl     (scl                  ),
.sda     (sda                  ),
.irq     (irq_if.irq           )
);

endmodule

`endif