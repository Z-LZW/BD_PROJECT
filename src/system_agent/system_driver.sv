`ifndef SYSTEM_DRIVER_GUARD
`define SYSTEM_DRIVER_GUARD

class system_driver extends uvm_driver#(system_trans);

  `uvm_component_utils(system_driver)

  virtual interface system_interface vif;

  bit         do_reset; //when active[1] a system reset will be initiated
  bit [6-1:0] width   ; //width of reset [in time units]
  rand bit [4-1:0] func_clock_period;

  //factory
  function new(string name,uvm_component parent = null);
    super.new(name,parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual system_interface)::get(this,"","system_vif", vif)) begin
      `uvm_fatal(get_type_name(), {"Virtual interface must be set for: ",get_full_name(),".vif"})       
    end
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    super.run_phase(phase);

    fork
      drive_apb_clock();
      drive_reset();
      drive_funk_clock();
      wait_seq();
    join

  endtask

  task wait_seq();
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(),$sformatf("SYSTEM WILL DRIVE A RESET WITH THE FOLLOWING PARAMETERS:\n%s",req.sprint()),UVM_HIGH)
      width = req.reset_width;
      #req.delay_before_reset;
      do_reset = 1;
      @(posedge vif.rst_n);
      @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask

  task drive_apb_clock();
    `uvm_info(get_type_name(), $sformatf("System will start driving the clock"), UVM_HIGH)
    #40;
    forever begin
      if(do_reset) begin
        vif.clk <= 0;
        #width do_reset = 0;
      end
      else begin
        #10 vif.clk <= ~vif.clk;
      end
    end
  endtask

  task drive_funk_clock();
    assert(std::randomize(func_clock_period) with {func_clock_period >= 1; func_clock_period <= 10;});
    `uvm_info(get_type_name(), $sformatf("System will start driving the function clock with period %d",func_clock_period), UVM_HIGH)
    #40;
    forever begin
      if(do_reset) begin
        vif.f_clk <= 0;
        #width do_reset = 0;
      end
      else begin
        #func_clock_period vif.f_clk <= ~vif.f_clk;
      end
    end
  endtask

  task drive_reset();
    #57;
    vif.rst_n <= 1;
    forever begin
      wait(do_reset);
      #15 vif.rst_n <= 0;
      #width vif.rst_n <= 1;
    end
  endtask

endclass

`endif