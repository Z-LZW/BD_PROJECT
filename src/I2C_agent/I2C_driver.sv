`ifndef I2C_DRIVER_GUARD
`define I2C_DRIVER_GUARD

class i2c_driver extends uvm_driver #(i2c_trans);

  //I2C master or I2C slave
  i2c_agent_kind_t agent_kind;
  bit [7-1:0]      dev_addr  ;

  //factory
  `uvm_component_utils_begin(i2c_driver)
    `uvm_field_enum(i2c_agent_kind_t, agent_kind, UVM_ALL_ON)
    `uvm_field_int (dev_addr, UVM_ALL_ON)
    `uvm_field_int (data    , UVM_ALL_ON)
    `uvm_field_int (addr    , UVM_ALL_ON)
    `uvm_field_int (rw      , UVM_ALL_ON)
  `uvm_component_utils_end

  //interface
  virtual interface i2c_intterface vif;

  //variables used for serial paralell conversion
  bit [8-1:0] data;
  bit [7-1:0] addr;
  bit         rw  ;

  //events
  event stop_condition_e;
  event nack_e          ;

  //constructor
  function new(string name, uvm_component parent = null);
    super.new(name,parent);
  endfunction:new

  //build
  function void build_phase (uvm_phase phase);
    super.new(phase);

    //link the virtual interface
    if (!uvm_config_db#(virtual i2c_intterface::get(this,"","i2c_vif",vif))) begin
      `uvm_fatal(get_type_name(), {"Virtual interface must be set for: ",get_full_name(),".vif"})
    end
  endfunction: build_phase

  //run
  task run_phase(uvm_phase phase);
    super.run_phase(phase);

    drive_reset_values();

    //go over initial reset and sync up with the APB
    @(posedge vif.rst_n);

    get_and_drive();
  endtask:run_phase

  task drive_reset_values();
    vif.cb.scl <= 1'b1;
    vif.cb.sda <= 1'b1;
  endtask: drive_reset_values

  task get_and_drive();
    forever begin
      fork
        if(vif.rst_n !== 1) begin
          disable drive_normal_condition;
          seq_item_port.item_done(); //abandon current transaction
          drive_reset_values();
        end

        begin: drive_normal_condition
          seq_item_port.get_next_item(req); //get item from sequencer
          drive_i2c_trans();
          seq_item_port.item_done(); //signal sequencer that item has been transfered
        end: drive_normal_condition
      join
    end
  endtask:get_and_drive

  task drive_i2c_trans(i2c_trans trans);
    case(agent_kind)
      I2C_MASTER: begin
        vif.cb.sda <= 0; //start condition
        repeat(2)@(vif.cb);
        vif.cb.scl <= 0;
        
        fork
          master_drive_clock();
          
          begin
            master_write_address_rw();

            @(posedge vif.scl);
            repeat(2)@(vif.cb);
            
            if(~vif.cb.sda) begin //ack
              @(negedge vif.scl);
              repeat(2)@(vif.cb);

              if(trans.kind == I2C_WRITE)
                repeat(trans.size) master_write_byte();
              else
                repeat(trans.size) master_read_byte();
            end
          end

          @(nack_e);
        join_any
        disable fork;
        if(~trans.repeated_start)
          master_drive_stop();
      end

      I2C_SLAVE: begin
        
        @(negedge sda iff scl); //start condition
        slave_read_address(); //get the 7 address bits

        @(posedge vif.scl);
        rw = vif.cb.sda;         //get the operation type

        @(negedge vifscl);
        repeat(2)@(vif.cb.cb);

        if(addr == dev_addr) begin  //check if the address matches the device address
          vif.cb.sda <= 0; //ack
          
          @(negedge vif.cb.scl);
          repeat(2)@(vif.cb);

          if (rw) begin
            fork: slave_read
              slave_read_byte();   //responde to bytes untill stop condition is detected
              @(posedge vif.sda iff vif.scl) //stop condition
            join_any:slave_read
            disable slave_read;
          end
          else begin
            fork: slave_write
              slave_write_byte();  //write bytes until either STOP or NACK happened
              @(posedge vif.sda iff vif.scl) //stop condition
              @(nack_e);
            join_any: slave_write
            disable slave_write;
          end
        end
        else
          vif.sda <= 1; //nack if address does not match
          @(posedge vif.scl);
        end
    endcase
  endtask: drive_i2c_trans

  task slave_read_address();
    for (int i = 6; i >= 0; i--)begin
      @(posedge vif.scl);
      addr[i] = vif.cb.sda;
    end
  endtask

  task slave_read_byte();
    forever begin
      vif.cb.sda <= 1; //ceding control over the bus
      repeat(8) @(negedge vif.scl); 
      repeat(2)@(vif.cb)

      if(trans.resp.pop_front() == I2C_ACK)
        vif.sda <= 0; //ack
    end
  endtask

  task slave_write_byte();
    forever begin
      data = trans.data_q.pop_front();
      for(int i = 7; i >= 0; i++)begin
        vif.sda <= data[i];
        @(negedge vif.scl);
        repeat(2)@(vif.cb);
      end
      vif.sda <= 1; //ceding control over the bus
      @(posedge vif.scl);
      if (vif.sda)
        ->nack_e;
      
      @(negedge vif.scl);
      repeat(2)@(vif.cb);
    end
  endtask

  task master_drive_clock();
    forever begin
      repeat(3)@(vif.cb);
      vif.cb.scl <= ~vif.cb.scl;
    end
  endtask

  task master_write_address_rw()
    for(int i = 6; i >= 0; i--) begin
      repeat(2)@(vif.cb);
      vif.cb.sda <= trans.addr[i];
      @(negedge vif.scl);
    end

    repeat(2)@(vif.cb);

    if (trans.kind == I2C_READ)
      vif.sda <= 1;
    @(negedge vif.scl);
    repeat(2)@(vif.cb);
  endtask

  task master_write_byte();
    data = trans.data_q.pop_front();

    for(int i = 7; i >= 0; i--) begin
      vif.cb.sda <= data[i];
      @(negedge vif.scl);
      repeat(2)@(vif.cb);
    end
    vif.sda <= 1; //ceding control over the bus
    @(posedge vif.scl);
    if (~vif.cb.sda) begin
      @(negedge vif.scl);
      repeat(2)@(vif.cb);
    end
    else
      ->nack_e;
  endtask

  task master_read_byte();

  endtask

endclass

`endif