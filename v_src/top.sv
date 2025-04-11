`ifndef TOP_GUARD
`define TOP_GUARD

`timescale 1ns/1ns

module top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import src_package::*;
  import system_package::*;
  import apb_package::*;
  import i2c_package::*;
  `include "../tests/test_lib.sv"

  system_interface system_if(clk,rst_n);
  apb_interface apb_master_if(clk,rst_n);
  apb_interface apb_slave_if(clk,rst_n);
  i2c_interface i2c_master_if(clk,rst_n);
  i2c_interface i2c_master_if_arb(clk,rst_n);
  i2c_interface i2c_slave_if(clk,rst_n);

  //apb master
  wire [31:0] paddr;
  wire        psel;
  wire        pwrite;
  wire        penable;
  wire [31:0] pwdata;

  //apb slave
  wire [31:0] prdata;
  wire        pready;
  wire        pslverr;

  //i2c
  triand scl;
  triand sda;

  assign paddr   = apb_master_if.paddr;
  assign psel    = apb_master_if.psel;
  assign pwrite  = apb_master_if.pwrite;
  assign penable = apb_master_if.penable;
  assign pwdata  = apb_master_if.pwdata;
      
  assign apb_master_if.prdata  = prdata;
  assign apb_master_if.pready  = pready;
  assign apb_master_if.pslverr = pslverr;

  assign apb_slave_if.paddr   = paddr;
  assign apb_slave_if.psel    = psel;
  assign apb_slave_if.pwrite  = pwrite;
  assign apb_slave_if.penable = penable;
  assign apb_slave_if.pwdata  = pwdata;  
   
  assign prdata  = apb_slave_if.prdata;
  assign pready  = apb_slave_if.pready;
  assign pslverr = apb_slave_if.pslverr;

  tran scl_master_link(i2c_master_if.scl,scl);
  tran sda_master_link(i2c_master_if.sda,sda);

  tran scl_master_arb_link(i2c_master_if_arb.scl,scl);
  tran sda_master_arb_link(i2c_master_if_arb.sda,sda);

  tran scl_slave_link(i2c_slave_if.scl,scl);
  tran sda_slave_link(i2c_slave_if.sda,sda);

  initial begin
    uvm_config_db #(virtual interface system_interface)::set(null,"*.sys_agent.*","system_vif",system_if);

    uvm_config_db #(virtual interface apb_interface#(32,32))::set(null,"*.apb_master_agent.*","apb_vif",apb_master_if);
    uvm_config_db #(virtual interface apb_interface#(32,32))::set(null,"*.apb_slave_agent.*","apb_vif",apb_slave_if);

    uvm_config_db #(virtual interface i2c_interface)::set(null,"*.i2c_master_agent.*","i2c_vif",i2c_master_if);
    uvm_config_db #(virtual interface i2c_interface)::set(null,"*.i2c_master_agent_arb.*","i2c_vif",i2c_master_if_arb);
    uvm_config_db #(virtual interface i2c_interface)::set(null,"*.i2c_slave_agent.*", "i2c_vif",i2c_slave_if);
    run_test();
  end

endmodule

`endif