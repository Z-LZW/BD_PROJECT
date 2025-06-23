`ifndef FIFO_FULL_TEST
`define FIFO_FULL_TEST

class fifo_full_test extends base_test;

  configure_master_write  write_conf;
  read_irq read_interrupt;
  
  `uvm_component_utils(fifo_full_test)
   
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
   
  virtual function void build_phase(uvm_phase phase);
    // Configuration
    uvm_config_db #(int)::set(this,"env", "number_of_masters",1);
    uvm_config_db #(int)::set(this,"env", "number_of_slaves",1);
    uvm_config_db #(int)::set(this,"env.i2c_slave_agent[0]", "dev_addr",0);
    
    super.build_phase(phase);
    write_conf = configure_master_write::type_id::create("write_conf",this);

    read_interrupt = read_irq::type_id::create("read_interrupt",this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    super.run_phase(phase);

    write_conf.randomize_conf();
    write_conf.rx_fifo_empty_mask = 1;
    write_conf.tx_fifo_full_mask = 1;
    write_conf.rx_fail_mask = 1;
    write_conf.tx_fail_mask = 1;
    write_conf.rx_done_mask = 1;
    write_conf.tx_done_mask = 1;
    write_conf.tx_lim = 256;

    write_conf.start(env.v_sequencer);

    read_interrupt.start(env.v_sequencer);

    phase.drop_objection(this);
  endtask

endclass

`endif