`ifndef SCOREBOARD_GUARD
`define SCOREBOARD_GUARD

class scoreboard#(AW=32,DW=32) extends uvm_scoreboard;

  `uvm_component_param_utils(scoreboard#(AW,DW))

  uvm_tlm_analysis_fifo #(apb_trans#(AW,DW)) APB_FIFO;
  uvm_tlm_analysis_fifo #(i2c_trans)         I2C_FIFO;
  uvm_tlm_analysis_fifo #(bit)               IRQ_FIFO;

  apb_trans#(AW,DW) apb_t;
  i2c_trans         i2c_t;
  bit               irq  ; //irq mirror value

  reg_blk reg_model; //pointer to the register model

  //---------------------------------
  bit [8-1:0] rx_fifo [$:256]; //register data fifo used in comparing data integrity
  bit [8-1:0] tx_fifo [$:256]; //register data fifo used in comparing data integrity

  bit rw_conf; //command mirror given from configuration [I2C read/write while in master mode] 

  event i2c_trnas_e; //event that signal when a transaction was received
  event apb_trnas_e; //event that signal when a transaction was received

  uvm_event start_read_rx_fifo; //global event thaa is used to signal the test to start reading the rx fifo register
  uvm_event done_read_rx_fifo ; //global event that is used to signal that the test finished reading the rx fifo register

  uvm_event i2c_start_condition; //i2c start condition detected on he bus
  uvm_event i2c_stop_condition;  //i2c stop condition detectedon the bus

  bit mode;

  //---------------------------------

  function new (string name = "scoreboard", uvm_component parent = null);
    super.new (name, parent);

    //declare global events
    start_read_rx_fifo = uvm_event_pool::get_global("start_read_rx_fifo");
    done_read_rx_fifo  = uvm_event_pool::get_global("done_read_rx_fifo");

    i2c_start_condition = uvm_event_pool::get_global("i2c_start_condition");
    i2c_stop_condition  = uvm_event_pool::get_global("i2c_stop_condition");

    //instantiate TLM fifos
    APB_FIFO = new("APB_FIFO",this);
    I2C_FIFO = new("I2C_FIFO",this);
    IRQ_FIFO = new("IRQ_FIFO",this);

    apb_t = new;
    i2c_t = new;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

    fork
      get_transactions();
      run_checks();
    join
  endtask

  task get_transactions();
    fork
      get_apb_trans();
      get_i2c_trans();
    join
  endtask

  task get_apb_trans();
    apb_trans#(AW,DW) apb_p;
    forever begin
      APB_FIFO.get(apb_p);
      apb_t.copy(apb_p);
      ->apb_trnas_e;

      //store TX data in a queue and predict when full
      if (apb_t.addr == 'h00 & apb_t.kind == APB_WRITE) begin
        tx_fifo.push_back(apb_t.data);
        if (tx_fifo.size() == 256)
          void'(reg_model.irq.tx_fifo_full.predict(1));
        else
          void'(reg_model.irq.tx_fifo_full.predict(0));
      end
      
      //store RX data in a queue and predict when empty
      if (apb_t.addr == 'h04 & apb_t.kind == APB_READ) begin
        rx_fifo.push_back(apb_t.data);
        if (rx_fifo.size() == i2c_t.data_q.size())
          void'(reg_model.irq.rx_fifo_empty.predict(1));
        else
          void'(reg_model.irq.rx_fifo_empty.predict(0));
      end
    end
  endtask

  task get_i2c_trans();
    i2c_trans i2c_p;
    forever begin
      I2C_FIFO.get(i2c_p);
      i2c_t.copy(i2c_p);
      `uvm_info(get_type_name(), $sformatf("The scoreboard has collected the following i2c transaction:\n%s",i2c_t.sprint()), UVM_HIGH)
      ->i2c_trnas_e;
    end
  endtask

//--------------------CHECKERS----------------------------------

  task run_checks();
    fork 

      //APB
      check_slave_error();
      check_comand_register();
      //I2C
      check_i2c_address();
      check_divider_formula();
      //IRQ
      check_irq_assertion();
      check_irq_tx();
      check_irq_rx();
      //GENERAL
      check_data_integrity();
      predict_busy();
      predict_tip();

    join
  endtask

  task check_irq_tx();
    forever begin
      @(i2c_trnas_e);
      if (reg_model.ctrl.mode.get()) begin //I2C master
        if ((i2c_t.kind == I2C_WRITE) & (i2c_t.data_q.size() == tx_fifo.size()) & (i2c_t.resp[$] == I2C_ACK)) //TBD PROTOCOL VIOLATION
          void'(reg_model.irq.tx_done.predict(1));
        else begin
          void'(reg_model.irq.tx_fail.predict(1));
        end
      end
      else begin //I2C slave
        if ((i2c_t.kind == I2C_READ) & (i2c_t.data_q.size() == tx_fifo.size()) & (i2c_t.resp[0] == I2C_ACK)) //TBD PROTOCOL VIOLATION
          void'(reg_model.irq.tx_done.predict(1));
        else begin
          void'(reg_model.irq.tx_fail.predict(1));
        end
      end
    end
  endtask

  task check_irq_rx();
    forever begin
      done_read_rx_fifo.wait_trigger();
      if (reg_model.ctrl.mode.get()) begin //I2C master
        if ((i2c_t.kind == I2C_READ) & (i2c_t.data_q.size() == rx_fifo.size()) & (i2c_t.resp[0] == I2C_ACK)) //TBD PROTOCOL VIOLATION
          void'(reg_model.irq.tx_done.predict(1));
        else begin
          void'(reg_model.irq.tx_fail.predict(1));
        end
      end
      else begin //I2C slave
        if ((i2c_t.kind == I2C_WRITE) & (i2c_t.data_q.size() == rx_fifo.size()) & (i2c_t.resp[$] == I2C_ACK)) //TBD PROTOCOL VIOLATION
          void'(reg_model.irq.tx_done.predict(1));
        else begin
          void'(reg_model.irq.tx_fail.predict(1));
        end
      end
    end
  endtask

  task predict_busy();
    forever begin 
      i2c_start_condition.wait_trigger();
      void'(reg_model.status.bsy.predict(1));
      i2c_stop_condition.wait_trigger();
      void'(reg_model.status.bsy.predict(0));
    end
  endtask

  task predict_tip();
    // bit mode;
    // forever begin
    //   @(apb_trnas_e);
    //   if (apb_t.addr == 'h0c & apb_t.kind == APB_WRITE)begin
    //     mode = apb_t.data[0];
    //   end
    //   if (mode)
    //     i2c_start_condition.wait_trigger();
    //   else
        
    // end
  endtask

  task check_comand_register();
    forever begin
      @(apb_trnas_e);
      //predict the operation type and the start of the i2c transaction
      if (apb_t.addr == 'h10 & apb_t.kind == APB_WRITE)begin
        if (reg_model.ctrl.enable_dev.get()) begin
          if (|apb_t.data[1:0])begin
              rw_conf = apb_t.data[0];
          end
          
          //clear mirror values and predict cleared interrupt
          if (apb_t.data[4])
            void'(reg_model.irq.predict(0));
          if (apb_t.data[3]) begin
            rx_fifo.delete();
            //i2c_t.data_q.delete();
          end
          if (apb_t.data[2]) begin
            tx_fifo.delete();
            //i2c_t.data_q.delete();
            void'(reg_model.irq.tx_fifo_full.predict(0));
          end
        end
      end
    end
  endtask

  task check_irq_assertion();
    forever begin
      
      IRQ_FIFO.get(irq);

      if (irq) begin
        if (reg_model.irq_mask.get() == 0)
          `uvm_error(get_type_name(),"IRQ asserted while it was masked")
        
        if (reg_model.irq.get() == 0)
          `uvm_error(get_type_name(),"IRQ asserted vector is empty")
      end
    end
  endtask

  task check_slave_error();
    forever begin
      @(apb_trnas_e);
      if((apb_t.addr > 'h20 | (|apb_t.addr[1:0]))) begin
        if (apb_t.resp == APB_OKAY)
          `uvm_error(get_type_name(),"PSLVERR not asserted when accesing illegal address") 
      end
      else
        if (apb_t.resp == APB_ERROR)
          `uvm_error(get_type_name(),"PSLVERR asserted when accesing legal address") 
    end
  endtask

  task check_i2c_address();
    forever begin
      @(i2c_trnas_e);

      if(reg_model.ctrl.mode.get()) begin //I2C master
        if(i2c_t.addr != reg_model.addr.target_addr.get())
          `uvm_error(get_type_name(),"I2C address not matching configurations")
        
        if((i2c_t.kind == I2C_WRITE & ~rw_conf) | (i2c_t.kind == I2C_READ & rw_conf))
          `uvm_error(get_type_name(),"I2C operation not matching configurations")
        
        if(reg_model.ctrl.enable_dev.get() == 0)
          `uvm_error(get_type_name(),"I2C master launched a transaction while not enabled")
      end
      else begin //I2C slave
        if((i2c_t.addr != reg_model.addr.device_addr.get()) & (i2c_t.resp[0] == I2C_ACK))
          `uvm_error(get_type_name(),"I2C slave responded with ACK while address not matching configurations")
        
        if((i2c_t.addr == reg_model.addr.device_addr.get()) & (i2c_t.resp[0] == I2C_ACK) & ((reg_model.ctrl.enable_ack.get() == 0) | (reg_model.ctrl.enable_dev.get() == 0)))
          `uvm_error(get_type_name(),"I2C slave responded with ACK while not enabled")
        
      end
    end
  endtask

  task check_data_integrity();
    bit [8-1:0] i2c_byte;
    bit [8-1:0] reg_byte;
    forever begin
      @(i2c_trnas_e);

      void'(reg_model.status.byte_cnt.predict(i2c_t.data_q.size()));
      
      //predict the nack field of status register when nack is detected
      if(i2c_t.resp[$] == I2C_NACK)
        void'(reg_model.status.nack.predict(1));
      else
        void'(reg_model.status.nack.predict(0));

      if(reg_model.ctrl.mode.get()) begin //I2C MASTER
        if (i2c_t.resp[0] == I2C_ACK) begin
          if (i2c_t.kind == I2C_WRITE) begin //I2C WRITE
            if (i2c_t.data_q.size() != tx_fifo.size()) begin
              //`uvm_error(get_type_name(),$sformatf("Number of bytes transferred does not equal the number of bytes written in register: I2C byte number: %0d | Register byte number: %0d",i2c_t.data_q.size(),tx_fifo.size()))
              void'(reg_model.irq.tx_fail.predict(1));
              void'(reg_model.irq.tx_done.predict(0));
              //i2c_t.data_q.delete();
              tx_fifo.delete();
            end
            else begin
              void'(reg_model.irq.tx_fail.predict(0));
              void'(reg_model.irq.tx_done.predict(1));
              while(tx_fifo.size() != 0) begin
                i2c_byte = i2c_t.data_q.pop_front();
                reg_byte = tx_fifo.pop_front();
                if (i2c_byte != reg_byte)
                  `uvm_error(get_type_name(),$sformatf("Data mismatch: i2c byte: %0h | register byte: %0h",i2c_byte,reg_byte))
              end
              `uvm_info(get_type_name(),"DONE CHECKING DATA QUEUES",UVM_MEDIUM)
            end
          end
          else begin //I2C READ
            start_read_rx_fifo.trigger();
            done_read_rx_fifo.wait_trigger(); 
            if ((i2c_t.data_q.size() != reg_model.ctrl.rx_fifo_lim.get())) begin
              //`uvm_error(get_type_name(),$sformatf("Number of bytes transferred does not equal the number of bytes written in register: I2C byte number: %0d | Register byte number: %0d",i2c_t.data_q.size(),rx_fifo.size()))
              void'(reg_model.irq.rx_fail.predict(1));
              void'(reg_model.irq.rx_done.predict(0));
              //i2c_t.data_q.delete();
              rx_fifo.delete();
            end
            else begin
              void'(reg_model.irq.rx_fail.predict(0));
              void'(reg_model.irq.rx_done.predict(1));
              while(rx_fifo.size() != 0) begin
                i2c_byte = i2c_t.data_q.pop_front();
                reg_byte = rx_fifo.pop_front();
                if (i2c_byte != reg_byte)
                  `uvm_error(get_type_name(),$sformatf("Data mismatch: i2c byte: %0f | register byte: %0f",i2c_byte,reg_byte))
              end
            end
          end
        end
        else begin
          if(i2c_t.kind == I2C_WRITE) begin
            void'(reg_model.irq.tx_fail.predict(1));
          end
          else begin
            void'(reg_model.irq.rx_fail.predict(1));
          end
        end
      end
    end
  endtask

  task check_divider_formula();
    forever begin
      @(i2c_trnas_e);
      if(reg_model.ctrl.mode.get())
        if(i2c_t.clock_period != (5 * reg_model.divider.get()) + 5)
          `uvm_error(get_type_name(),"Frequency of SCL does not match specifications")
    end
  endtask
endclass

`endif