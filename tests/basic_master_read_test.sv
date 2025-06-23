`ifndef BASIC_MASTER_READ_TEST
`define BASIC_MASTER_READ_TEST

class basic_master_read_test extends base_test;

  configure_master_read  read_conf;
  read_rx_fifo read_fifo;
  read_irq read_interrupt;

  i2c_slave_seq i2c_slave;

  rand bit [7-1:0] i2c_addr;
  
  `uvm_component_utils(basic_master_read_test)
   
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
    read_conf = configure_master_read::type_id::create("read_conf",this);
    i2c_slave  = i2c_slave_seq::type_id::create("i2c_slave",this);

    read_fifo  = read_rx_fifo::type_id::create("read_fifo",this);
    read_interrupt = read_irq::type_id::create("read_interrupt",this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    super.run_phase(phase);

    read_conf.randomize_conf();

    read_conf.target_addr = i2c_addr;

    read_conf.start(env.v_sequencer);
    
    i2c_slave.start(env.v_sequencer);
    #100ns;
    read_fifo.start(env.v_sequencer);

    read_interrupt.start(env.v_sequencer);

    phase.drop_objection(this);
  endtask

endclass

`endif