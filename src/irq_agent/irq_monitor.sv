`ifndef IRQ_MONITOR_GUARD
`define IRQ_MONITOR_GUARD

class irq_monitor extends uvm_monitor;

  `uvm_component_utils(irq_monitor)

  virtual irq_interface vif;

  uvm_analysis_port #(bit) item_collected_port;

  //constructor
  function new(string name, uvm_component parent);
    super.new(name,parent);
    item_collected_port = new("item_collected_port",this);
  endfunction:new

  //build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    //link virtual interface
    if (!uvm_config_db#(virtual irq_interface)::get(this,"","irq_vif", vif)) begin
	    `uvm_fatal(get_type_name(), {"Virtual interface must be set for: ",get_full_name(),".vif"})       
    end
  endfunction:build_phase

  //run phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);

    @(posedge vif.rst_n); //skip initial reset

    forever begin
      wait(vif.mon_cb.irq);
      item_collected_port.write(1);

      wait(~vif.mon_cb.irq);
      item_collected_port.write(1);
    end

  endtask: run_phase

endclass

`endif