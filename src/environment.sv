`ifndef ENVIRONMENT_GUARD
`define ENVIRONMENT_GUARD

class environment #(AW=32,DW=32) extends uvm_env;

  `uvm_component_param_utils(environment#(AW,DW))

  //apb agents
  apb_agent#(AW,DW) apb_master_agent;

  //i2c agents
  i2c_agent i2c_master_agent [];
  i2c_agent i2c_slave_agent [];

  int number_of_masters;
  int number_of_slaves;

  randc bit [6:0] slave_address;

  //i2c_agent i2c_master_agent_arb;

  irq_agent irq_slave_agent;

  system_agent sys_agent;

  virtual_sequencer#(AW,DW) v_sequencer;

  reg_blk                               reg_model        ;
  reg_apb_adapter#(AW,DW)               apb_reg_adapter  ;
  uvm_reg_predictor#(apb_trans#(AW,DW)) apb_reg_predictor;

  scoreboard#(AW,DW) scb;
  coverage#(AW,DW) cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
  
    if (!uvm_config_db#(int)::get(this,"","number_of_masters", number_of_masters)) begin
	    `uvm_fatal(get_type_name(), {"Number of I2C masters must be set for: ",get_full_name(),""})       
    end

    if (!uvm_config_db#(int)::get(this,"","number_of_slaves", number_of_slaves)) begin
	    `uvm_fatal(get_type_name(), {"Number of I2C slaves must be set for: ",get_full_name(),""})       
    end

    if (number_of_masters == 0 & number_of_slaves == 0)
      `uvm_fatal(get_type_name(), {"The number if I2c agents cannot be 0 in: ",get_full_name(),""})

    //apb config
    // uvm_config_db #(uvm_bitstream_t)::set(this,"apb_master_agent", "agent_kind", APB_MASTER);
    // uvm_config_db #(uvm_bitstream_t)::set(this,"apb_master_agent", "is_active", UVM_ACTIVE);
    // uvm_config_db #(int)::set(this,"apb_master_agent.monitor", "has_checks", 1);
    // uvm_config_db #(int)::set(this,"apb_master_agent.monitor", "has_coverage", 1);

    // uvm_config_db #(uvm_bitstream_t)::set(this,"apb_slave_agent", "agent_kind", APB_SLAVE);
    // uvm_config_db #(uvm_bitstream_t)::set(this,"apb_slave_agent", "is_active", UVM_ACTIVE);
    // uvm_config_db #(int)::set(this,"apb_slave_agent.monitor", "has_checks", 1);
    // uvm_config_db #(int)::set(this,"apb_slave_agent.monitor", "has_coverage", 1);

    //i2c master config
    i2c_master_agent = new [number_of_masters];
    
    for(int i = 0; i < number_of_masters; i++) begin
      i2c_master_agent[i]  = i2c_agent::type_id::create($sformatf("i2c_master_agent[%0d]",i),this);
      uvm_config_db #(uvm_bitstream_t)::set(this,$sformatf("i2c_master_agent[%0d]",i), "agent_kind", I2C_MASTER);
      uvm_config_db #(uvm_bitstream_t)::set(this,$sformatf("i2c_master_agent[%0d]",i), "is_active", UVM_ACTIVE);
    end

    //i2c slave config
    i2c_slave_agent = new [number_of_slaves];
    for(int i = 0; i < number_of_slaves; i++) begin
      i2c_slave_agent[i]  = i2c_agent::type_id::create($sformatf("i2c_slave_agent[%0d]",i),this);
      uvm_config_db #(uvm_bitstream_t)::set(this,$sformatf("i2c_slave_agent[%0d]",i), "agent_kind", I2C_SLAVE);
      uvm_config_db #(uvm_bitstream_t)::set(this,$sformatf("i2c_slave_agent[%0d]",i), "is_active",  UVM_ACTIVE);
    end

    //uvm_config_db #(uvm_bitstream_t)::set(this,"i2c_master_agent_arb", "agent_kind", I2C_MASTER);
    //uvm_config_db #(uvm_bitstream_t)::set(this,"i2c_master_agent_arb", "is_active", UVM_ACTIVE);
    // uvm_config_db #(int)::set(this,"i2c_master_agent.monitor", "has_checks", 1);
    // uvm_config_db #(int)::set(this,"i2c_master_agent.monitor", "has_coverage", 1);

    //uvm_config_db #(uvm_bitstream_t)::set(this,"i2c_slave_agent", "is_active", UVM_ACTIVE);
    //uvm_config_db #(uvm_bitstream_t)::set(this,"i2c_slave_agent", "agent_kind", I2C_SLAVE);
    //uvm_config_db #(uvm_bitstream_t)::set(this,"i2c_slave_agent", "dev_addr", 'h55);

    // uvm_config_db #(int)::set(this,"i2c_slave_agent.monitor", "has_checks", 1);
    // uvm_config_db #(int)::set(this,"i2c_slave_agent.monitor", "has_coverage", 1);

    // uvm_config_db #(uvm_bitstream_t)::set(this,"sys_agent","is_active",UVM_ACTIVE);

    super.build_phase(phase);
    
    apb_master_agent = apb_agent#(AW,DW)::type_id::create("apb_master_agent",this);

    //i2c_master_agent = i2c_agent::type_id::create("i2c_master_agent",this);
    //i2c_master_agent_arb = i2c_agent::type_id::create("i2c_master_agent_arb",this);
    
    irq_slave_agent = irq_agent::type_id::create("irq_slave_agent",this);
    
    sys_agent = system_agent::type_id::create("sys_agent",this);

    v_sequencer = virtual_sequencer#(AW,DW)::type_id::create("v_sequencer",this);

    reg_model = reg_blk::type_id::create("reg_model",this);

    reg_model.build();
    reg_model.reset();
    reg_model.lock_model();

    apb_reg_adapter = reg_apb_adapter#(AW,DW)::type_id::create("apb_reg_adapter",this);
    apb_reg_predictor = uvm_reg_predictor#(apb_trans#(AW,DW))::type_id::create("apb_reg_predictor",this);

    scb = scoreboard#(AW,DW)::type_id::create("scb",this);
  
    cov = coverage#(AW,DW)::type_id::create("cov",this);

  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    v_sequencer.system_seqr = sys_agent.sequencer;

    v_sequencer.apb_master_seqr = apb_master_agent.sequencer;
    
    v_sequencer.i2c_master_seqr = i2c_master_agent[0].sequencer;
    v_sequencer.i2c_slave_seqr  = i2c_slave_agent[0].sequencer; 
     
    v_sequencer.p_reg_model     = reg_model;
    scb.reg_model               = reg_model;

    reg_model.apb_regs_map.set_sequencer(apb_master_agent.sequencer,apb_reg_adapter);

    reg_model.apb_regs_map.set_auto_predict(0);

    apb_reg_predictor.map = reg_model.apb_regs_map;
    apb_reg_predictor.adapter = apb_reg_adapter;

    apb_master_agent.monitor.item_collected_port.connect(apb_reg_predictor.bus_in);

    apb_master_agent.monitor.item_collected_port.connect(scb.APB_FIFO.analysis_export);
    irq_slave_agent.monitor.item_collected_port.connect(scb.IRQ_FIFO.analysis_export);

    if(number_of_masters != 0)
      i2c_master_agent[0].monitor.item_collected_port.connect(scb.I2C_FIFO.analysis_export);
    else
      i2c_slave_agent[0].monitor.item_collected_port.connect(scb.I2C_FIFO.analysis_export);

    apb_master_agent.monitor.item_collected_port.connect(cov.apb_analysis_port.analysis_export);
    irq_slave_agent.monitor.item_collected_port.connect(cov.irq_analysis_port.analysis_export);

  endfunction

endclass

`endif