`ifndef APB_DRIVER_GUARD
`define APB_DRIVER_GUARD

class apb_driver #(AW=32,DW=32) extends uvm_driver #(apb_trans #(AW,DW));

  //APB master or APB slave
  apb_agent_kind_t agent_kind;

  //factory
  `uvm_component_utils_begin(apb_driver#(AW,DW))
    `uvm_field_enum(apb_agent_kind_t, agent_kind, UVM_ALL_ON)
  `uvm_component_utils_end

  //interface
  virtual interface apb_if #(AW,DW) vif;

  //constructor
  function new(string name, uvm_component parent = null);
    super.new(name,parent);
  endfunction:new

  //build
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);

    //link the virtual interface
    if (!uvm_config_db#(virtual apb_if #(AW,DW))::get(this,"","apb_vif", vif)) begin
       `uvm_fatal(get_type_name(), {"Virtual interface must be set for: ",get_full_name(),".vif"})
    end
  endfunction:build_phase

  task run_phase(uvm_phase phase)
    super.run_phase(phase)

    drive_reset_values();

    //go over initial reset
    @(posedge vif.preset_n);

    get_and_drive():

  endtask:run_phase

  task drive_reset_values();
    case (agent_kind)
      APB_MASTER: begin
        vif.mst_cb.psel    <= 1'b0;
        vif.mst_cb.penable <= 1'bx;
        vif.mst_cb.pwrite  <= 1'bx;
        vif.mst_cb.paddr   <=  'bx;
        vif.mst_cb.pwdata  <=  'bx;
      end
      APB_SLAVE: begin
        vif.slv_cb.pready  <= 1'bx;
        vif.slv_cb.pslverr <= 1'bx;
        vif.slv_cb.prdata  <=  'bx;
      end
    endcase
  endtask:drive_reset_values

  task get_and_drive();
    forever begin
      fork
        //drive reset values as soon as preset_n is asserter or unknown
        if(vif.preset_n !== 1) begin 
          disable drive_normal_condition;
          if (vif.psel)
            seq_item_port.item_done(); //abandon transaction when reset comes 
          drive_reset_values(); 
          @(posedge vif.preset_n); 
        end 

        begin:drive_normal_condition
          seq_item_port.get_next_item(req); //get item from sequencer
          drive_apb_trans(req);
          seq_item_port.item_done(); //signal the sequencer it's ok to send the next item
        end:drive_normal_condition
      join
    end
  endtask

  task drive_apb_trans(apb_trans #(AW,DW) trans);
    case (agent_kind)
      APB_MASTER: begin
        `uvm_info(get_type_name(), $sformatf("The APB MASTER Driver will start the following transfer:\n%s",trans.sprint()), UVM_HIGH)

        repeat(trans.delay) @(posedge vif.mst_cb); //delay between the transactions

        //first part of transaction [SETUP]
        vif.mst_cb.paddr   <=  trans.addr              ;
        vif.mst_cb.pwrite  <= (trans.kind == APB_WRITE);
        vif.mst_cb.penable <= 1'b0                     ;
        vif.mst_cb.psel    <= 1'b1                     ;
        if (trans.kind == APB_WRITE) vif.mst_cb.pwdata <= trans.data;

        //second part of transaction [ACCESS]
        @(vif.mst_cb);
        vif.mst_cb.penable <= 1'b1;
        @(vif.mst_cb);

        wait(vif.mst_cb.pready);
        vif.mst_cb.psel      <= 1'b0;
	      vif.mst_cb.penable   <= 1'b0;
      end
      
      APB_SLAVE: begin
        wait (vif.slv_cb.psel);
        `uvm_info(get_type_name(), $sformatf("The APB SLAVE Driver will start the following transfer:\n%s",trans.sprint()), UVM_HIGH)

        vif.slv_cb.pslverr <= 1'b0;
        vif.slv_cb.pready  <= 1'b0;

        repeat(trans.ready_delay) @(vif.slv_cb); //insert ready delay
        vif.slv_cb.pready  <= 1'b1;
        vif.slv_cb.pslverr <= (trans.resp == APB_ERROR);
        if (vif.slv_cb.pwrite == 1'b0)  vif.slv_cb.prdata <= trans.data;
        @(vif.slv_cb);
        
        vif.slv_cb.pslverr <= 1'b0;
      end
    endcase
  endtask


endclass

`endif 