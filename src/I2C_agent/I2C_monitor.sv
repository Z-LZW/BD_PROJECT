`ifndef I2C_MONITOR_GUARD
`define I2C_MONITOR_GUARD

class i2c_monitor extends uvm_monitor;

  //analysis port
  uvm_analysis_port #(i2c_trans) item_collected_port;

  //put port from driver
  uvm_blocking_put_imp #(bit,i2c_monitor) arb_lost_imp;

  //virtual interface
  virtual i2c_interface vif;

  //colected transaction
  i2c_trans trans;

  //number of collected transactions
  int unsigned transfer_number;

  bit has_checks  ;
  bit has_coverage;

  //vaiables used in serial parallel conversion
  bit [7-1:0] addr;
  bit [8-1:0] data;

  bit         tip ; //transfer in progress

  bit         repeated_start;

  int         clock_period;
  int         actual_period;

  //events
  event nack_e;

  //factory
  `uvm_component_utils_begin(i2c_monitor)
    `uvm_field_int(has_checks  , UVM_ALL_ON)
    `uvm_field_int(has_coverage, UVM_ALL_ON)
  `uvm_component_utils_end 

//------------------------Covergroups------------------------------

  //reset coverage
  covergroup i2c_reset_cov @(negedge vif.rst_n);
    reset_occured: coverpoint tip {
      bins outside_transfer = {0};
      bins inside_transfer  = {1};
    }
  endgroup

//-----------------------------------------------------------------

  //constructor
  function new(string name, uvm_component parent);
    super.new(name,parent);
    item_collected_port = new("item_collected_port",this);
    arb_lost_imp = new("arb_lost_imp", this);
    if (has_coverage) begin
      i2c_reset_cov = new;
    end
   endfunction:new

   //build phase
   function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    //link virtual interface
    if (!uvm_config_db#(virtual i2c_interface)::get(this,"","i2c_vif", vif)) begin
	    `uvm_fatal(get_type_name(), {"Virtual interface must be set for: ",get_full_name(),".vif"})       
    end
  endfunction:build_phase

  //run phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    transfer_number = 0;

    @(posedge vif.rst_n); //skip initial reset

    fork
      collect_transactions();
      check_clock_streching();
    join
  endtask: run_phase

  task collect_transactions();
    forever begin
      fork
        monitor_normal_trans();
        wait (trans.arb_lost);
      join_any  
      disable fork;
      transfer_number++;
      tip = 0;
      `uvm_info(get_type_name(), $sformatf("The I2C MONITOR has collected the following transaction:\n%s",trans.sprint()), UVM_MEDIUM)
      item_collected_port.write(trans);
    end
  endtask

  task monitor_normal_trans();
    trans = new;

    if (~repeated_start)
      @(negedge vif.sda iff vif.scl); //start condition
    else
      repeated_start = 0;
    
    tip = 1;
    collect_address_rw();

    if(~vif.mon_cb.sda) begin
      fork :collect_bytes_fork
        collect_bytes();
        @(posedge vif.sda iff vif.scl); //stop condition
        begin @(negedge vif.sda iff vif.scl); repeated_start = 1; end //repeated start condition
      join_any
      disable collect_bytes_fork;
      trans.repeated_start = repeated_start;
    end
  endtask

  task collect_address_rw();
    for(int i = 6; i >= 0; i--) begin
      @(posedge vif.scl);
      addr[i] = vif.mon_cb.sda;
    end

    trans.addr = addr;

    @(posedge vif.scl);

    if(vif.mon_cb.sda)
      trans.kind = I2C_READ;
    else
      trans.kind = I2C_WRITE;
    `uvm_info(get_type_name(), $sformatf("I2C MONITOR COLLECTED ADDRESS AND RW"), UVM_MEDIUM)
    collect_resp();
  endtask

  task collect_bytes();
    forever begin
      for(int i = 7; i >= 0; i--) begin
        @(posedge vif.scl);
        data[i] = vif.mon_cb.sda;
      end

      trans.data_q.push_back(data);
      `uvm_info(get_type_name(), $sformatf("I2C MONITOR COLLECTED A BYTE"), UVM_MEDIUM)
      collect_resp();
    end
  endtask

  task collect_resp();
    @(posedge vif.scl);
    if (vif.mon_cb.sda) begin
      trans.resp.push_back(I2C_NACK);
      ->nack_e;
    end
    else
      trans.resp.push_back(I2C_ACK);
    `uvm_info(get_type_name(), $sformatf("I2C MONITOR COLLECTED A RESPONSE"), UVM_MEDIUM)
  endtask

  task check_clock_streching();
  bit repeated_start_local;
  forever begin
    `uvm_info(get_type_name(), $sformatf("CLOCK TASK"), UVM_MEDIUM)
    if (~repeated_start_local)
      @(negedge vif.sda iff vif.scl); //start condition
    else
      repeated_start_local = 0;
    
    @(negedge vif.scl);
    
    collect_clock_period(actual_period);
    trans.clock_period = actual_period;
    `uvm_info(get_type_name(), $sformatf("ACTUAL CLOCK PERIOD %0d",actual_period), UVM_MEDIUM)
    fork: check_strech
      forever begin
        collect_clock_period(clock_period);
        `uvm_info(get_type_name(), $sformatf("CLOCK PERIOD %0d",clock_period), UVM_MEDIUM)
        if(clock_period > actual_period)
          trans.clock_strech = 1;
      end
      begin @(negedge vif.sda iff vif.scl); repeated_start_local = 1; end//start condition
      @(posedge vif.sda iff vif.scl); //stop condition
    join_any
    disable check_strech;
  end
  endtask

  task collect_clock_period(output int per);
    per = 0;
    //`uvm_info(get_type_name(), $sformatf("MINI CLOCK TASK"), UVM_MEDIUM)
    @(negedge vif.scl);
    
    fork: count_period
      forever begin 
        @(vif.mon_cb);
        per++;
      end
      @(negedge vif.scl);
    join_any
    disable count_period;
  endtask

  virtual task put(bit arb_lost);
    trans.arb_lost = 1;
    //`uvm_info(get_type_name(), $sformatf("The I2C MONITOR has collected the following transaction:\n%s",trans.sprint()), UVM_MEDIUM)

  endtask

  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("I2C Monitor has collected %0d transfers",transfer_number), UVM_LOW)
  endfunction

endclass

`endif