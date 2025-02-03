`ifndef SYSTEM_MONITOR_GUARD
`define SYSTEM_MONITOR_GUARD

class system_monitor extends uvm_monitor;

  `uvm_component_utils(clock_monitor)

  uvm_analysis_port #(clock_trans) item_collected_port; //port used to send the arrival of reset to high level components

  virtual interface clock_interface vif;
  clock_trans trans;

  function new(string name,uvm_component parent = null);
    super.new(name,parent);
    item_collected_port = new ("analysis_port", this);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual clock_interface)::get(this,"","clk_vif", vif)) begin
      `uvm_fatal(get_type_name(), {"Virtual interface must be set for: ",get_full_name(),".vif"})       
    end
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      @(negedge vif.rst_n);               //wait for reset to be asserted
      item_collected_port.write(trans);   //signal the hogh level components
    end
  endtask


endclass


`endif