`ifndef SYSTEM_DRIVER_GUARD
`define SYSTEM_DRIVER_GUARD

class system_driver extends uvm_driver#(system_trans);

  `uvm_component_utils(system_driver)

  virtual interface system_interface vif;

  bit         do_reset; //when active[1] a system reset will be initiated
  bit [6-1:0] width   ; //width of reset [in time units]

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
      drive_clock();
      drive_reset();
      wait_seq();
    join

  endtask

  task wait_seq();
    forever begin
      seq_item_port.get_next_item(req);
      width = req.reset_width;
      #req.delay_before_reset;
      do_reset = 1;
      @(posedge vif.rst_n);
      seq_item_port.item_done();
    end
  endtask

  task drive_clock();
    `uvm_info(get_type_name(), $sformatf("System will start driving the clock"), UVM_HIGH)
    #50;
    forever begin
      if(do_reset) begin
        vif.clk <= 0;
        #width do_reset = 0;
      end
      else begin
        #5 vif.clk <= ~vif.clk;
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