`ifndef ENVIRONMENT_GUARD
`define ENVIRONMENT_GUARD

class environment #(AW=32,DW=32) extends uvm_env;

  `uvm_component_utils(environment#(AW,DW))

  //apb agents
  apb_agent apb_master_agent;
  apb_agent apb_slave_agent;

  //i2c agents
  i2c_agent i2c_master_agent;
  i2c_agent i2c_slave_agent;

  i2c_agent i2c_master_agent_arb;

  system_agent sys_agent;

  virtual_sequencer v_sequencer;

  reg_blk                               reg_model        ;
  reg_apb_adapter                       apb_reg_adapter  ;
  uvm_reg_predictor#(apb_trans#(32,32)) apb_reg_predictor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);

    //apb config
    uvm_config_db #(uvm_bitstream_t)::set(this,"apb_master_agent", "agent_kind", APB_MASTER);
    uvm_config_db #(uvm_bitstream_t)::set(this,"apb_master_agent", "is_active", UVM_ACTIVE);
    uvm_config_db #(int)::set(this,"apb_master_agent.monitor", "has_checks", 1);
    uvm_config_db #(int)::set(this,"apb_master_agent.monitor", "has_coverage", 1);
    uvm_config_db #(uvm_bitstream_t)::set(this,"apb_slave_agent", "agent_kind", APB_SLAVE);
    uvm_config_db #(uvm_bitstream_t)::set(this,"apb_slave_agent", "is_active", UVM_ACTIVE);
    uvm_config_db #(int)::set(this,"apb_slave_agent.monitor", "has_checks", 1);
    uvm_config_db #(int)::set(this,"apb_slave_agent.monitor", "has_coverage", 1);

    //i2c config
    uvm_config_db #(uvm_bitstream_t)::set(this,"i2c_master_agent", "agent_kind", I2C_MASTER);
    uvm_config_db #(uvm_bitstream_t)::set(this,"i2c_master_agent", "is_active", UVM_ACTIVE);

    uvm_config_db #(uvm_bitstream_t)::set(this,"i2c_master_agent_arb", "agent_kind", I2C_MASTER);
    uvm_config_db #(uvm_bitstream_t)::set(this,"i2c_master_agent_arb", "is_active", UVM_ACTIVE);
    // uvm_config_db #(int)::set(this,"i2c_master_agent.monitor", "has_checks", 1);
    // uvm_config_db #(int)::set(this,"i2c_master_agent.monitor", "has_coverage", 1);
    uvm_config_db #(uvm_bitstream_t)::set(this,"i2c_slave_agent", "agent_kind", I2C_SLAVE);
    uvm_config_db #(uvm_bitstream_t)::set(this,"i2c_slave_agent", "is_active", UVM_ACTIVE);
    uvm_config_db #(uvm_bitstream_t)::set(this,"i2c_slave_agent", "dev_addr", 'h55);
    // uvm_config_db #(int)::set(this,"i2c_slave_agent.monitor", "has_checks", 1);
    // uvm_config_db #(int)::set(this,"i2c_slave_agent.monitor", "has_coverage", 1);

    uvm_config_db #(uvm_bitstream_t)::set(this,"sys_agent","is_active",UVM_ACTIVE);

    super.build_phase(phase);
    
    apb_master_agent = apb_agent#(AW,DW)::type_id::create("apb_master_agent",this);
    apb_slave_agent  = apb_agent#(AW,DW)::type_id::create("apb_slave_agent",this);

    i2c_master_agent = i2c_agent::type_id::create("i2c_master_agent",this);
    i2c_master_agent_arb = i2c_agent::type_id::create("i2c_master_agent_arb",this);
    i2c_slave_agent  = i2c_agent::type_id::create("i2c_slave_agent",this);

    sys_agent = system_agent::type_id::create("sys_agent",this);

    v_sequencer = virtual_sequencer::type_id::create("v_sequencer",this);

    reg_model = reg_blk::type_id::create("reg_model",this);

    reg_model.build();
    reg_model.reset();
    reg_model.lock_model();

    apb_reg_adapter = reg_apb_adapter::type_id::create("apb_reg_adapter",this);
    apb_reg_predictor = uvm_reg_predictor#(apb_trans#(32,32))::type_id::create("apb_reg_predictor",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    v_sequencer.apb_master_seqr = apb_master_agent.sequencer;
    v_sequencer.apb_slave_seqr  = apb_slave_agent.sequencer;
    
    v_sequencer.i2c_master_seqr = i2c_master_agent.sequencer;
    v_sequencer.i2c_master_seqr_arb = i2c_master_agent_arb.sequencer;
    v_sequencer.i2c_slave_seqr  = i2c_slave_agent.sequencer; 
     
    v_sequencer.p_reg_model     = reg_model;

    reg_model.apb_regs_map.set_sequencer(apb_master_agent.sequencer,apb_reg_adapter);

    reg_model.apb_regs_map.set_auto_predict(0);

    apb_reg_predictor.map = reg_model.apb_regs_map;
    apb_reg_predictor.adapter = apb_reg_adapter;

    apb_master_agent.monitor.item_collected_port.connect(apb_reg_predictor.bus_in);

  endfunction

endclass

`endif