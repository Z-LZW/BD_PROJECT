`ifndef SYSTEM_AGENT_GUARD
`define SYSTEM_AGENT_GUARD

class system_agent extends uvm_agent;
  system_sequencer sequencer;
  system_driver    driver   ;
  system_monitor   monitor  ;

  `uvm_component_utils(system_agent)

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction:new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(uvm_bitstream_t)::get(this,"","is_active", is_active)) begin
	    `uvm_fatal(get_type_name(), {"Agent type must be set for: ",get_full_name(),""})       
    end

    sequencer = system_sequencer::type_id::create("sequecer",this);  //create sequencer
    driver    = system_driver::type_id::create("driver",this);       //create driver
    monitor   = system_monitor::type_id::create("monitor",this);     //create monitor

  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass

`endif