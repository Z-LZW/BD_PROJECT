`ifndef ENVIRONMENT_GUARD
`define ENVIRONMENT_GUARD

class environment #(AW=32,DW=32) extends uvm_env;

  `uvm_component_utils(environment#(AW,DW))

  //apb agents
  apb_agent master_agent;
  apb_agent slave_agent;
  system_agent sys_agent;

  virtual_sequencer v_sequencer;

  reg_blk reg_model;

  reg_apb_adapter apb_reg_adapter;

  uvm_reg_predictor#(apb_trans#(32,32)) apb_reg_predictor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);

    uvm_config_db #(uvm_bitstream_t)::set(this,"master_agent", "agent_kind", APB_MASTER);
    uvm_config_db #(uvm_bitstream_t)::set(this,"master_agent", "is_active", UVM_ACTIVE);
    uvm_config_db #(int)::set(this,"master_agent.monitor", "has_checks", 1);
    uvm_config_db #(int)::set(this,"master_agent.monitor", "has_coverage", 1);
    uvm_config_db #(uvm_bitstream_t)::set(this,"slave_agent", "agent_kind", APB_SLAVE);
    uvm_config_db #(uvm_bitstream_t)::set(this,"slave_agent", "is_active", UVM_ACTIVE);
    uvm_config_db #(int)::set(this,"slave_agent.monitor", "has_checks", 1);
    uvm_config_db #(int)::set(this,"slave_agent.monitor", "has_coverage", 1);
    uvm_config_db #(uvm_bitstream_t)::set(this,"sys_agent","is_active",UVM_ACTIVE);

    super.build_phase(phase);
    
    master_agent = apb_agent#(AW,DW)::type_id::create("master_agent",this);
    slave_agent = apb_agent#(AW,DW)::type_id::create("slave_agent",this);
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

    v_sequencer.apb_master_seqr = master_agent.sequencer;
    v_sequencer.apb_slave_seqr  = slave_agent.sequencer;
    v_sequencer.p_reg_model     = reg_model;

    reg_model.apb_regs_map.set_sequencer(master_agent.sequencer,apb_reg_adapter);

    reg_model.apb_regs_map.set_auto_predict(0);

    apb_reg_predictor.map = reg_model.apb_regs_map;
    apb_reg_predictor.adapter = apb_reg_adapter;

    master_agent.monitor.item_collected_port.connect(apb_reg_predictor.bus_in);

  endfunction

endclass

`endif