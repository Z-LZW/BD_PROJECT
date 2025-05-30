`ifndef COVERAGE_GUARD
`define COVERAGE_GUARD

class coverage#(AW=32,DW=32) extends uvm_component;


//--------------------------REGISTER FIELDS-----------------------------------//

  bit [ 8-1:0] tx_fifo_data; //fifo data
  bit [ 8-1:0] rx_fifo_data; //fifo data

  bit [ 7-1:0] dev_addr   ; //device address in slave mode
  bit [ 7-1:0] target_addr; //target address in master mode

  bit [ 8-1:0] tx_fifo_lim; //number of data to be transmitted
  bit [ 8-1:0] rx_fifo_lim; //number of data to be received

  bit          enable_ack; //enable slave mode
  bit          enable_dev; //enable device
  bit          mode      ; //mode -> MASTER | SLAVE

  bit          clear_irq; //clear interrupt register
  bit          clear_rx ; //clear rx fifo
  bit          clear_tx ; //clear tx_fifo

  bit          read ; //initiate read
  bit          write; //initiate write

  bit [ 9-1:0] byte_cnt; //number of bytes transferred via I2C

  bit          arb_lost; //arbitration lost
  bit          nack    ; //nack detected
  bit          bsy     ; //devise buse
  bit          tip     ; //transfer in progress

  bit          rx_fifo_empty;
  bit          tx_fifo_full ;
  bit          rx_fail      ;
  bit          tx_fail      ;
  bit          rx_done      ;
  bit          tx_done      ;

  bit          rx_fifo_empty_mask;
  bit          tx_fifo_full_mask ;
  bit          rx_fail_mask      ;
  bit          tx_fail_mask      ;
  bit          rx_done_mask      ;
  bit          tx_done_mask      ;

  bit [16-1:0] divider;

//----------------------------INTERRUPT------------------------------------------//

  bit irq;

//----------------------------EVENTS---------------------------------------------//
  event tx_acces_e      ;
  event rx_acces_e      ;
  event addr_acces_e    ;
  event ctrl_acces_e    ;
  event cmd_acces_e     ;
  event status_acces_e  ;
  event irq_acces_e     ;
  event irq_mask_acces_e;
  event divider_acces_e ;
  event irq_asserted_e  ;

//----------------------------TLM PORTS---------------------------------------------//

  uvm_tlm_analysis_fifo #(apb_trans#(AW,DW)) apb_analysis_port;
  uvm_tlm_analysis_fifo #(bit)               irq_analysis_port;

  apb_trans#(AW,DW) apb_t;

//----------------------------COVERGROUPS---------------------------------------------//

  covergroup tx_fifo_reg_cov @(tx_acces_e);
    option.per_instance = 1;

    bit_toggle_up: coverpoint tx_fifo_data{
      wildcard bins b0 = {8'b???????1};
      wildcard bins b1 = {8'b??????1?};
      wildcard bins b2 = {8'b?????1??};
      wildcard bins b3 = {8'b????1???};
      wildcard bins b4 = {8'b???1????};
      wildcard bins b5 = {8'b??1?????};
      wildcard bins b6 = {8'b?1??????};
      wildcard bins b7 = {8'b1???????};
    }
    bit_toggle_low: coverpoint tx_fifo_data{
      wildcard bins b0 = {8'b???????0};
      wildcard bins b1 = {8'b??????0?};
      wildcard bins b2 = {8'b?????0??};
      wildcard bins b3 = {8'b????0???};
      wildcard bins b4 = {8'b???0????};
      wildcard bins b5 = {8'b??0?????};
      wildcard bins b6 = {8'b?0??????};
      wildcard bins b7 = {8'b0???????};
    }
  endgroup

  covergroup rx_fifo_reg_cov @(rx_acces_e);
    option.per_instance = 1;

    bit_toggle: coverpoint rx_fifo_data{
      wildcard bins b0 = {8'b???????1};
      wildcard bins b1 = {8'b??????1?};
      wildcard bins b2 = {8'b?????1??};
      wildcard bins b3 = {8'b????1???};
      wildcard bins b4 = {8'b???1????};
      wildcard bins b5 = {8'b??1?????};
      wildcard bins b6 = {8'b?1??????};
      wildcard bins b7 = {8'b1???????};
    }
    bit_toggle_low: coverpoint rx_fifo_data{
      wildcard bins b0 = {8'b???????0};
      wildcard bins b1 = {8'b??????0?};
      wildcard bins b2 = {8'b?????0??};
      wildcard bins b3 = {8'b????0???};
      wildcard bins b4 = {8'b???0????};
      wildcard bins b5 = {8'b??0?????};
      wildcard bins b6 = {8'b?0??????};
      wildcard bins b7 = {8'b0???????};
    }
  endgroup

  covergroup addr_reg_cov @(addr_acces_e or cmd_acces_e or status_acces_e);
    option.per_instance = 1;

    dev_addr_cov: coverpoint dev_addr{
      bins minim     = {0};
      bins maxim     = {127};
      bins range[10] = {[1:126]};
    }
    target_addr_cov: coverpoint target_addr{
      bins minim     = {0};
      bins maxim     = {127};
      bins range[10] = {[1:126]};
    }

    address_x_operation_master: cross target_addr_cov,mode,read,write{
      ignore_bins slave_mode   = address_x_operation_master with (mode  == 0);
      ignore_bins no_command = address_x_operation_master with (write == 0 & read == 0);
    }

    address_x_operation_slave: cross dev_addr_cov,mode,bsy{
      ignore_bins master_mode  = address_x_operation_slave with (mode == 1);
      ignore_bins idle         = address_x_operation_slave with (bsy  == 0);
    }

  endgroup

  covergroup ctrl_reg_cov @(ctrl_acces_e);
    option.per_instance = 1;

    tx_lim_cov: coverpoint tx_fifo_lim{
      bins minim     = {1};
      bins maxim     = {0};
      bins range[10] = {[2:255]};
    }
    rx_lim_cov: coverpoint rx_fifo_lim{
      bins minim     = {1};
      bins maxim     = {0};
      bins range[10] = {[2:255]};
    }
    enable_ack_tog: coverpoint enable_ack;
    enable_tog:     coverpoint enable_dev;
    mode_tog:       coverpoint mode      ;
  endgroup

  covergroup cmd_reg_cov @(cmd_acces_e);
  option.per_instance = 1;
    clear_irq_tog: coverpoint clear_irq;
    clear_rx_tog:  coverpoint clear_rx ;
    clear_tx_tog:  coverpoint clear_tx ;
    read_tog:      coverpoint read     {
      bins read_command = {1};
    }
    write_tog:     coverpoint write    {
      bins write_command = {1};
    }

    write_priority: cross read_tog,write_tog,mode{
      bins read_write_command = write_priority with (mode == 1);
    }
  endgroup

  covergroup status_reg_cov @(status_acces_e);
    option.per_instance = 1;

    byte_cnt_tog: coverpoint byte_cnt {
      bins minim     = {0};
      bins maxim     = {256};
      bins range[10] = {[1:255]};
    }
    arb_lost_tog: coverpoint arb_lost;
    nack_tog:     coverpoint nack    ;
    bsy_tog:      coverpoint bsy     ;
    tip_tog:      coverpoint tip     ;
  endgroup

  covergroup irq_reg_cov @(irq_acces_e);
    option.per_instance = 1;

    rx_fifo_empty_tog: coverpoint rx_fifo_empty;
    tx_fifo_full_tog:  coverpoint tx_fifo_full ;
    rx_fail_tog:       coverpoint rx_fail      ;
    tx_fail_tog:       coverpoint tx_fail      ;
    rx_done_tog:       coverpoint rx_done      ;
    tx_done_tog:       coverpoint tx_done      ;

    rx_fifo_empty_x_irq: cross rx_fifo_empty_tog , irq, rx_fifo_empty_mask{
      ignore_bins irq_masked = rx_fifo_empty_x_irq with (rx_fifo_empty_mask == 0);
    }
    tx_fifo_full_x_irq:  cross tx_fifo_full_tog, irq, tx_fifo_full_mask{
      ignore_bins irq_masked = tx_fifo_full_x_irq with (tx_fifo_full_mask == 0);
    }
    rx_fail_x_irq:       cross rx_fail_tog     , irq, rx_fail_mask, mode{
      ignore_bins irq_masked = rx_fail_x_irq with (rx_fail_mask == 0);
    }
    tx_fail_x_irq:       cross tx_fail_tog     , irq, tx_fail_mask, mode{
      ignore_bins irq_masked = tx_fail_x_irq with (tx_fail_mask == 0);
    }
    rx_done_x_irq:       cross rx_done_tog     , irq, rx_done_mask, mode{
      ignore_bins irq_masked = rx_done_x_irq with (rx_done_mask == 0);
    }
    tx_done_x_irq:       cross tx_done_tog     , irq, tx_done_mask, mode{
      ignore_bins irq_masked = tx_done_x_irq with (tx_done_mask == 0);
    }

  endgroup

  covergroup irq_mask_reg_cov @(irq_mask_acces_e);
    option.per_instance = 1;

    rx_fifo_empty_mask_tog: coverpoint rx_fifo_empty_mask;
    tx_fifo_full_mask_tog:  coverpoint tx_fifo_full_mask ;
    rx_fail_mask_tog:       coverpoint rx_fail_mask      ;
    tx_fail_mask_tog:       coverpoint tx_fail_mask      ;
    rx_done_mask_tog:       coverpoint rx_done_mask      ;
    tx_done_mask_tog:       coverpoint tx_done_mask      ;
  endgroup

  covergroup divider_cov @(divider_acces_e);
    option.per_instance = 1;

    divider_val_cov: coverpoint divider {
      bins minim     = {8};
      bins maxim     = {'hffff};
      bins range[16] = {[9:'hfffe]};
    }
  endgroup
//----------------------------FUNCTIONS AND TASKS------------------------------------//

  `uvm_component_param_utils(coverage#(AW,DW))

  function new(string name = "coverage", uvm_component parent = null);
    super.new(name,parent);
    apb_analysis_port = new("apb_analysis_port",this);
    irq_analysis_port = new("irq_analysis_port",this);
    tx_fifo_reg_cov = new;
    rx_fifo_reg_cov = new;
    addr_reg_cov = new;
    ctrl_reg_cov = new;
    cmd_reg_cov = new;
    status_reg_cov = new;
    irq_reg_cov = new;
    irq_mask_reg_cov = new;
    divider_cov = new;
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    fork
      get_apb_trans();
      get_irq_trans();
    join
  endtask

  task get_irq_trans();
    forever begin
      irq_analysis_port.get(irq);
      if(irq)
        ->irq_asserted_e;
    end
  endtask

  task get_apb_trans();
    forever begin
      apb_analysis_port.get(apb_t);
      if(apb_t.kind == APB_WRITE)
        case (apb_t.addr)
          'h0 : begin
                  tx_fifo_data = apb_t.data;
                  ->tx_acces_e;
                  `uvm_info(get_type_name(),"TX ACCESS TRIGGERED",UVM_DEBUG)
                end
          'h8 : begin 
                  target_addr = apb_t.data[14:8]; 
                  dev_addr    = apb_t.data[ 6:0]; 
                  ->addr_acces_e;
                  `uvm_info(get_type_name(),"ADDR ACCESS TRIGGERED",UVM_DEBUG)
                end
          'hc : begin 
                  rx_fifo_lim = apb_t.data[23:16]; 
                  tx_fifo_lim = apb_t.data[15: 8]; 
                  enable_ack  = apb_t.data[2]; 
                  enable_dev  = apb_t.data[1]; 
                  mode        = apb_t.data[0];
                  ->ctrl_acces_e;
                  `uvm_info(get_type_name(),"CTRL ACCESS TRIGGERED",UVM_DEBUG)
                end
          'h10: begin
                  clear_irq = apb_t.data[4];
                  clear_rx  = apb_t.data[3];
                  clear_tx  = apb_t.data[2];
                  read      = apb_t.data[1];
                  write     = apb_t.data[0];
                  ->cmd_acces_e;
                  `uvm_info(get_type_name(),"CMD ACCESS TRIGGERED",UVM_DEBUG)
                end
          'h1c: begin 
                  rx_fifo_empty_mask = apb_t.data[5];
                  tx_fifo_full_mask  = apb_t.data[4];
                  rx_fail_mask       = apb_t.data[3];
                  tx_fail_mask       = apb_t.data[2];
                  rx_done_mask       = apb_t.data[1];
                  tx_done_mask       = apb_t.data[0];
                  ->irq_mask_acces_e;
                  `uvm_info(get_type_name(),"IRQ MASK ACCESS TRIGGERED",UVM_DEBUG)
                end
          'h20: begin
                  divider = apb_t.data;
                  ->divider_acces_e;
                  `uvm_info(get_type_name(),"DIVIDER ACCESS TRIGGERED",UVM_DEBUG)
                end
        endcase
      else
        case(apb_t.addr)
          'h4 : begin
                  rx_fifo_data = apb_t.data;
                  ->rx_acces_e;
                end
          'h14: begin
                  byte_cnt = apb_t.data[16:8];
                  arb_lost = apb_t.data[3];
                  nack     = apb_t.data[2];
                  bsy      = apb_t.data[1];
                  tip      = apb_t.data[0];
                  ->status_acces_e;
                end
          'h18: begin
                  rx_fifo_empty = apb_t.data[5];
                  tx_fifo_full  = apb_t.data[4];
                  rx_fail       = apb_t.data[3];
                  tx_fail       = apb_t.data[2];
                  rx_done       = apb_t.data[1];
                  tx_done       = apb_t.data[0];
                  ->irq_acces_e;
                end
        endcase

        if (clear_irq & enable_dev) begin
          rx_fifo_empty = 0;
          tx_fifo_full  = 0;
          rx_fail       = 0;
          tx_fail       = 0;
          rx_done       = 0;
          tx_done       = 0;
        end

        clear_irq = 0;
        clear_rx  = 0;
        clear_tx  = 0;
        read      = 0;
        write     = 0;
    end
  endtask

endclass

`endif