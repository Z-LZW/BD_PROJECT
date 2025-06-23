`ifndef BASIC_SLAVE_TX_TEST
`define BASIC_SLAVE_TX_TEST

class basic_slave_tx_test extends base_test;

  configure_slave  slave_conf;

  i2c_master_read_sequence i2c_read;

  read_irq read_interrupt;

 // read_rx_fifo  read_rx;

  rand bit [7-1:0] i2c_addr;
  
  `uvm_component_utils(basic_slave_tx_test)
   
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
   
  virtual function void build_phase(uvm_phase phase);
    // Configuration
    assert (std::randomize(i2c_addr)) else $fatal("ERROR INN RANDOMIZATION");
    uvm_config_db #(int)::set(this,"env", "number_of_masters",1);
    uvm_config_db #(int)::set(this,"env", "number_of_slaves",1);
    uvm_config_db #(int)::set(this,"env.i2c_slave_agent[0]", "dev_addr",0);
    
    super.build_phase(phase);
    slave_conf = configure_slave::type_id::create("slave_conf",this);
    i2c_read = i2c_master_read_sequence::type_id::create("i2c_read",this);
    read_interrupt = read_irq::type_id::create("read_interrupt",this);
    //read_rx = read_rx_fifo::type_id::create("read_rx",this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    super.run_phase(phase);

    slave_conf.randomize_conf();

    slave_conf.device_addr = i2c_addr;

    slave_conf.start(env.v_sequencer);
    read_interrupt.start(env.v_sequencer);

    i2c_read.target_addr = i2c_addr;
    i2c_read.transfer_size = slave_conf.tx_lim;
    i2c_read.start(env.v_sequencer);

    //read_rx.start(env.v_sequencer);

    read_interrupt.start(env.v_sequencer);

    phase.drop_objection(this);
  endtask

endclass

`endif