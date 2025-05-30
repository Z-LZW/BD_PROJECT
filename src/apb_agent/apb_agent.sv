`ifndef APB_AGENT_GUARD
`define APB_AGENT_GUARD

class apb_agent #(AW=32,DW=32) extends uvm_agent;

  apb_agent_kind_t agent_kind;

  apb_monitor   #(AW,DW) monitor;
  apb_sequencer #(AW,DW) sequencer;
  apb_driver    #(AW,DW) driver;
  apb_coverage  #(AW,DW) coverage;

  `uvm_component_param_utils_begin(apb_agent#(AW,DW))
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
    `uvm_field_enum(apb_agent_kind_t, agent_kind, UVM_ALL_ON)
  `uvm_component_utils_end

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    //get agent type:active or passive
    if (!uvm_config_db#(uvm_bitstream_t)::get(this,"","is_active", is_active)) begin
	    `uvm_fatal(get_type_name(), {"Agent type must be set for: ",get_full_name(),""})       
    end
    
    //get agent kind: Master or Slave
    if (!uvm_config_db#(uvm_bitstream_t)::get(this,"","agent_kind", agent_kind)) begin
	    `uvm_fatal(get_type_name(), {"Agent kind must be set for: ",get_full_name(),""})       
    end

    //create the monitor
    monitor = apb_monitor#(AW,DW)::type_id::create("monitor", this);
    coverage = apb_coverage#(AW,DW)::type_id::create("coverage",this);

    if(is_active == UVM_ACTIVE) begin
	    //create the sequencer
	    sequencer = apb_sequencer#(AW,DW)::type_id::create("sequencer", this);
      //create the driver  
	    driver = apb_driver#(AW,DW)::type_id::create("driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if(is_active == UVM_ACTIVE) begin
      //connect the driver to the sequencer
	    driver.seq_item_port.connect(sequencer.seq_item_export);
	    driver.agent_kind = agent_kind;

      monitor.item_collected_port.connect(coverage.analysis_export);
    end
  endfunction
   

endclass

`endif