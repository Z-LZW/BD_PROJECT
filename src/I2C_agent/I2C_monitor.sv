`ifndef I2C_MONITOR_GUARD
`define I2C_MONITOR_GUARD

class i2c_monitor extends uvm_monitor;

  //analysis port
  uvm_analysis_port #(i2c_trans) item_collected_port;

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

  bit         tip ;

  //events
  event reset_e;
  event nack_e;

  //factory
  `uvm_component_utils_begin(i2c_monitor)
    `uvm_field_int(has_checks  , UVM_ALL_ON)
    `uvm_field_int(has_coverage, UVM_ALL_ON)
  `uvm_component_utils_end 

//------------------------Covergroups------------------------------

  //reset coverage
  covergroup i2c_reset_cov @(reset_e);
    reset_occured: coverpoint tip {
      bins outside_transfer = {0};
      bins inside_transfer  = {1};
    }
  endgroup

  covergroup i2c_signal_toggle @(vif.sda or vif.scl)
    scl_toggle: coverpoint vif.scl;
    sda_toggle: coverpoint vif.sda;
  endgroup

//-----------------------------------------------------------------

  //constructor
  function new(string name, uvm_component parent);
    super.new(name,parent);
    item_collected_port = new("item_collected_port",this);
    if (has_coverage) begin
      
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
  task run_phase();
    transfer_number = 0;

    @(posedge vif.rst_n); //skip initial reset

    fork
      collect_transactions();
      wait_reset();
    join
  endtask: run_phase

  task collect_transactions();
    forever begin
      @(negedge vif.sda iff vif.scl); //wait start condition
      tip = 1;
      collect_address_rw();
      
      if(vif.mon_cb.sda) begin
        fork
          collect_bytes();
          @(posedge vif.sda iff scl);
        join_any
        disable fork;
      end
      
      tip = 0;
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
    
    collect_resp();

  endtask

  task collect_bytes();
    forever begin
      for(int i = 7; i >= 0; i--) begin
        @(posedge vif.scl);
        data[i] = vif.mon_cb.sda;
      end

      trans.data_q.push_back(data);
      collect_resp();
    end
  endtask

  task collect_resp();
    @(posedge vif.scl);
    if (vif.sda) begin
      trans.resp.push_back(I2C_NACK);
      ->nack_e;
    end
    else
      trans.resp.push_back(I2C_ACK);
  endtask

  task wait_reset();
  @(posedge vif.rst_n); //skip initial reset
  forever begin
    @(negedge vif.rst_n);
    ->reset_e;
  end
  endtask

endclass

`endif