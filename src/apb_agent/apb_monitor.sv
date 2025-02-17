`ifndef APB_MONITOR_GUARD
`define APB_MONITOR_GUARD

class apb_monitor #(AW=32,DW=32) extends uvm_monitor;

  //analysys port
  uvm_analysis_port #(apb_trans#(AW,DW)) item_collected_port;

  //virtual interface
  virtual apb_if #(AW,DW) vif;

  //collected transaction
  apb_trans #(AW,DW) trans;

  //number of collected transactions
  int unsigned transfer_number;

  //delay between transactions saved localy
  int unsigned temp_inter_delay;

  //delay inside transaction saved localy
  in unsigned temp_intra_delay;

  bit has_checks  ;  
  bit has_coverage;

  //coverage relevant signals
  //data bit toggle toggle
  bit [DW-1:0] prdata_tgl_cov;
  bit          prdata_dir    ;
  bit [DW-1:0] pwdata_tgl_cov;
  bit          pwdata_dir    ;

  //address bit toggle
  bit [AW-1:0] paddr_tgl_cov ;
  bit          paddr_dir     ;

  //events
  event apb_signal_cov_e ;
  event apb_reset_cov_e  ;
  event apb_trans_ended_e;


//------------------------Covergroups------------------------------
  
  //Sigal toggle
  covergroup apb_signal_cov @apb_signal_cov_e;
    penable_sig: coverpoint vif.penable;
    psel_sig   : coverpoint vif.psel;
    pwrite_sig : coverpoint vif.pwrite;
    pready_sig : coverpoint vif.pready;
    pslverr_sig: coverpoint vif.pslverr;
  endgroup

  //reset coverage
  covergroup apb_reset_cov @apb_reset_cov_e;
    preset_sig: coverpoint vif.preset_n {
      bins reset_asserted = {0};
    }
    psel_sig: coverpoint vif.psel {
      bins outside_transfer = {0};
      bins inside_transfer  = {1};
    }
  endgroup

  //functional
  covergroup apb_cov @apb_trans_ended_e;
    //inter transaction delay
    trans_delay_kind: coverpoint trans.delay_kind {
      bins b2b    = {ZERO};
      bins short  = {SHORT};
      bins medium = {MEDIUM};
      bins long   = {LARGE};
      bins max    = {MAX};
    }

    //intra transaction delay
    trans_ready_delay : coverpoint trans.ready_delay {
      bins instant = {0};
      bins delay_1 = {1};
      bins rest    = {[2:10]};
    }

    //response type
    trans_resp_kind : coverpoint trans.resp {
      bins ok    = {APB_OKAY} ;
      bins error = {APB_ERROR};
    }
  endgroup

  //data | addr toggle
  covergroup apb_pwdata_toggle_cov;
    option.per_instance = 1 ;

    rise_wdata_cov: coverpoint pwdata_tgl_cov iff (pwdata_dir == 1'b1);
    fall_wdata_cov: coverpoint pwdata_tgl_cov iff (pwdata_dir == 1'b0);
  endgroup

  covergroup apb_prdata_toggle_cov;
    option.per_instance = 1 ;

    rise_rdata_cov: coverpoint prdata_tgl_cov iff (prdata_dir == 1'b1);
    fall_rdata_cov: coverpoint prdata_tgl_cov iff (prdata_dir == 1'b0);
  endgroup

  covergroup apb_paddr_toggle_cov;
    option.per_instance = 1 ;

    rise_addr_cov: coverpoint paddr_tgl_cov iff (paddr_dir == 1'b1);
    fall_addr_cov: coverpoint paddr_tgl_cov iff (paddr_dir == 1'b0);
  endgroup
  
//-----------------------------------------------------------------

  //factory
  `uvm_component_utils_begin(apb_monitor #(AW,DW))
      `uvm_field_int(has_checks, UVM_ALL_ON)
      `uvm_field_int(has_coverage, UVM_ALL_ON)
   `uvm_component_utils_end

  //constructor
  function new(string name, uvm_component parent);
    super.new(name,parent);
    item_collected_port = new("item_collected_port",this);
    if (has_coverage) begin
      apb_signal_cov = new;
	    apb_reset_cov  = new;
      apb_cov        = new;
    end
   endfunction:new

  //build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    //get virtual interface
    if (!uvm_config_db#(virtual apb_if #(AW,DW))::get(this,"","apb_vif", vif)) begin
	    `uvm_fatal(get_type_name(), {"Virtual interface must be set for: ",get_full_name(),".vif"})       
    end
  endfunction:build_phase

  //run phase
  task run_phase(uvm_phase phase);
    transfer_number = 0;

    //skip initial reset
    if (vif.preset_n !== 0) @(negedge vif.preset_n);
    @(posedge vif.preset_n);

    //start monitoring
    fork
      monitor_inter_trans_delay();
      apb_signal_toggle();
      monitor_hw_reset();
      collect_transactions();
      monitor_toggle_bits();
    join
  endtask:run_phase

  task monitor_inter_trans_delay();
    forever begin
      temp_inter_delay = 0;
	    fork
	      begin
	        // wait for the next transation
	        if (vif.psel !== 1'b1) @(posedge vif.mon_cb.psel);
	      end
	      begin
	        forever begin
	          @(posedge vif.pclk);
		        if (vif.mon_cb.psel === 1'b0) temp_inter_delay++; // increment the delay only if in idle state
	        end
	      end
	    join_any
	    disable fork;
	    @(negedge vif.mon_cb.penable);
    end
  endtask

  task apb_signal_toggle();
    forever begin
       @(vif.penable or vif.psel or vif.pwrite or vif.pready or vif.pslverr);
       -> apb_signal_cov_e;
    end
  endtask

  task monitor_hw_reset();
    // Go over the initial reset
    @(negedge vif.preset_n);
    forever begin
      @(negedge vif.preset_n);
	    -> apb_reset_cov_e;
    end
  endtask

  task monitor_toggle_bits();
    bit [DW:0]          last_prdata;
    bit [DW:0]          last_pwdata;
    bit [AW:0]          last_paddr;
    bit                 first_read  = 1'b1;
    bit                 first_write = 1'b1; 

    forever begin
      @(apb_trans_ended_e);

      if(~(first_write & first_read))
        for(int i=0; i<AW; i++)
          if(trans.data[i] ^ last_pwdata[i]) begin
            pwdata_id_cov = i;
            pwdata_dir    = trans.data[i];
            apb_pwdata_toggle_cov.sample();
          end

      last_paddr  = trans.addr;   

      if(trans.kind == APB_WRITE) begin
        if (first_write) begin
          last_pwdata = trans.pwdata;
          first_write = 0;
        end
        else begin
          for(int i = 0; i < DW; i++) begin
            if(trans.data[i] ^ last_pwdata[i]) begin
              pwdata_id_cov = i;
              pwdata_dir    = trans.data[i];
              apb_pwdata_toggle_cov.sample();
            end
          end

          last_pwdata = trans.data;;
        end
      end
      else begin
        if(first_read) begin
          last_prdata = trans.data;
          first_read = 1'b0;
        end
        else begin
          for(int i = 0; i < 32; i++) begin
            if(trans.data[i] ^ last_prdata[i]) begin
              prdata_id_cov = i;
              prdata_dir = trans.data[i];
              apb_prdata_toggle_cov.sample();  
            end
          end

          last_prdata = trans.data;  
        end
      end
    end
  endtask

  task collect_transactions();
    forever begin
      wait (viv.mon_cb.psel === 1'b1); //wait untill start of the transaction
      trans = new;

      trans.addr = vif.mon_cb.paddr;
      trans.kind =(vif.mon_cb.pwrite) ? APB_WRITE : APB_READ;
      if (trans.kind == APB_WRITE) trans.data = vif.pwdata;

      @(posedge vif.mon_cb); //go to acces phase

      while (vif.mon_cb.pready !== 1'b1) begin
        @(posedge vif.pclk);
	      @(vif.mon_cb);
	      trans.ready_delay++;
      end

      if (trans.kind == APB_READ) trans.data = vif.mon_cb.prdata;
      trans.resp  = (vif.mon_cb.pslverr == 1'b1) ? APB_ERROR : APB_OKAY;
      trans.delay = temp_inter_delay;

      case (temp_inter_delay) inside
             0 : trans.delay_kind = ZERO  ;
        [1 : 5]: trans.delay_kind = SHORT ;
        [6 :10]: trans.delay_kind = MEDIUM;
        [11:19]: trans.delay_kind = LARGE ;
        default: trans.delay_kind = MAX   ;
      endcase

      transfer_number++; //increment transfer number

      item_collected_port.write(trans); //write to subcribers and scoreboard
    end
  endtask

  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("APB Monitor has collected %0d transfers",transfer_number), UVM_LOW)
  endfunction

endclass

`endif