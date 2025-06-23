`ifndef BASIC_SLAVE_RX_TEST
`define BASIC_SLAVE_RX_TEST

class basic_slave_rx_test extends base_test;

  configure_slave  slave_conf;

  i2c_master_wirte_sequence i2c_write;

  read_irq read_interrupt;

  read_rx_fifo  read_rx;

  rand bit [7-1:0] i2c_addr;
  
  `uvm_component_utils(basic_slave_rx_test)
   
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
   
  virtual function void build_phase(uvm_phase phase);
    // Configuration
    assert (std::randomize(i2c_addr)) else $fatal("ERROR INN RANDOMIZATION");
    uvm_config_db #(int)::set(this,"env", "number_of_masters",1);
    uvm_config_db #(int)::set(this,"env", "number_of_slaves",1);
    uvm_config_db #(int)::set(this,"env.i2c_slave_agent[0]", "dev_addr",i2c_addr);
    
    super.build_phase(phase);
    slave_conf = configure_slave::type_id::create("slave_conf",this);
    i2c_write = i2c_master_wirte_sequence::type_id::create("i2c_write",this);
    read_interrupt = read_irq::type_id::create("read_interrupt",this);
    read_rx = read_rx_fifo::type_id::create("read_rx",this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    super.run_phase(phase);

    //slave_conf.randomize_conf();
    slave_conf.rx_fifo_empty_mask = 0;
    slave_conf.tx_fifo_full_mask = 0;
    slave_conf.rx_fail_mask = 0;
    slave_conf.tx_fail_mask = 0;
    slave_conf.rx_done_mask = 0;
    slave_conf.tx_done_mask = 0;

    slave_conf.device_addr = i2c_addr;

    slave_conf.start(env.v_sequencer);
    read_interrupt.start(env.v_sequencer);

    i2c_write.target_addr = 7'h55;
    i2c_write.start(env.v_sequencer);

    read_rx.start(env.v_sequencer);

    read_interrupt.start(env.v_sequencer);

    phase.drop_objection(this);
  endtask

endclass

`endif