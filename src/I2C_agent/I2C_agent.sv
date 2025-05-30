`ifndef I2C_AGENT_GUARD
`define I2C_AGENT_GUARD

class i2c_agent extends uvm_agent;

  i2c_agent_kind_t agent_kind;

  i2c_sequencer sequencer;
  i2c_driver    driver   ;
  i2c_monitor   monitor  ;
  i2c_coverage  coverage ;
  bit [6:0]     dev_addr ;

  `uvm_component_utils_begin(i2c_agent)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
    `uvm_field_enum(i2c_agent_kind_t, agent_kind, UVM_ALL_ON)
    `uvm_field_int(dev_addr, UVM_ALL_ON)
  `uvm_component_utils_end

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if(is_active == UVM_ACTIVE) begin
	    //create the sequencer
	    sequencer = i2c_sequencer::type_id::create("sequencer", this);
      //create the driver  
	    driver = i2c_driver::type_id::create("driver", this);
    end

    //create monitor and coverage
    monitor = i2c_monitor::type_id::create("monitor",this);
    coverage = i2c_coverage::type_id::create("coverage",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    //get agent type: active or passive
    if (!uvm_config_db#(uvm_bitstream_t)::get(this,"","is_active", is_active)) begin
	    `uvm_fatal(get_type_name(), {"Agent type must be set for: ",get_full_name(),""})       
    end

    //get agent kind: Master or Slave
    if (!uvm_config_db#(uvm_bitstream_t)::get(this,"","agent_kind", agent_kind)) begin
	    `uvm_fatal(get_type_name(), {"Agent kind must be set for: ",get_full_name(),""})       
    end

    if (agent_kind == I2C_SLAVE & !uvm_config_db#(int)::get(this,"","dev_addr", dev_addr)) begin
	    `uvm_fatal(get_type_name(), {"Dev Addr must be set for slave I2C Agent: ",get_full_name(),""})       
    end


    if(is_active == UVM_ACTIVE) begin
      
	    driver.seq_item_port.connect(sequencer.seq_item_export); //connect the driver to the sequencer
      driver.arbitration_lost.connect(monitor.arb_lost_imp);   //connect driver to mointor for arbitration
	    driver.agent_kind = agent_kind;
      driver.dev_addr = dev_addr;

      monitor.item_collected_port.connect(coverage.analysis_export);
    end
  endfunction

endclass

`endif