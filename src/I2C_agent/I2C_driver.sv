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
  `uvm_component_utils_end

  uvm_blocking_put_port #(bit) arbitration_lost;

  //interface
  virtual interface i2c_interface vif;

  //variables used for serial paralell conversion
  bit [8-1:0] data;
  bit [7-1:0] addr;
  bit         rw  ;
  bit [9-1:0] size;
  bit         driven_high;
  bit         arb_lost;
  bit         prev_clk;
  int         clock_period;
  string      trans_kind;
  bit         repeated_start;
  bit         tip;

  //events
  event nack_e;
  event trans_ended_e;

  //constructor
  function new(string name, uvm_component parent = null);
    super.new(name,parent);
    arbitration_lost = new("arbitration_lost", this);
  endfunction:new

  //build
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);

    //link the virtual interface
    if (!uvm_config_db#(virtual i2c_interface)::get(this,"","i2c_vif",vif)) begin
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
        wait(vif.rst_n !== 1);

        begin: drive_normal_condition
          seq_item_port.get_next_item(req); //get item from sequencer
          drive_i2c_trans(req);
        end: drive_normal_condition

        check_tip();
      join_any

      disable fork;
      //`uvm_info(get_type_name(),$sformatf("ITEM_DONE"),UVM_HIGH)
      if (~vif.rst_n) begin
        if(tip) begin
          seq_item_port.item_done();
        end
      end
      else
        seq_item_port.item_done();
      drive_reset_values();
      @(vif.cb);
    end
  endtask:get_and_drive

  task check_tip();
    forever begin
      @(negedge vif.sda iff vif.scl); //start condition
      tip = 1;
      `uvm_info(get_type_name(),$sformatf("TRANSFER IN PROGRESS %d",tip),UVM_HIGH)
      @(posedge vif.sda iff vif.scl); //stop condition
      @(vif.cb);
      tip = 0;
    end
  endtask

  task drive_i2c_trans(i2c_trans trans);
    case(agent_kind)
      I2C_MASTER: begin
        while(tip == 1) @(vif.cb); //wait for the bus to be free
        `uvm_info(get_type_name(),$sformatf("AFTER BUS IS FREE AND TIP IS %d",tip),UVM_HIGH)
        repeat(trans.delay * trans.clock_period) @(vif.cb); //delay before transaction

        size = trans.data_q.size();
        trans_kind = trans.kind == I2C_WRITE ? "WRITE" : "READ";
        `uvm_info(get_type_name(),$sformatf("MASTER WILL DRIVE THE FOLLOWING TRANSACTION:\n%s",trans.sprint()),UVM_HIGH)

        vif.cb.sda <= 0; //start condition
        repeat(trans.clock_period/4) @(vif.cb);
        vif.cb.scl <= 0;
        
        fork: master_driving
          master_drive_clock(trans); //drive scl
          master_drive_trans(trans); //drive transaction
          //heck_arb();               //check if arbitration was lost
          @(nack_e);                 //wait for a NACK response
        join_any

        driven_high = 0;
        `uvm_info(get_type_name(),$sformatf("MASTER OUTSIDE DRIVING FORK"),UVM_DEBUG)

        disable fork;

        if(~arb_lost) begin
          if(trans.repeated_start) begin
            vif.cb.sda <= 1;
            repeat(trans.clock_period/4) @(vif.cb);
            vif.cb.scl <= 1;

            repeat(8) @(vif.cb);
            tip = 0;
          end
          else begin
            vif.cb.sda <= 0;
            repeat(trans.clock_period/2) @(vif.cb);
            vif.cb.scl <= 1;
            repeat(trans.clock_period/4) @(vif.cb);
            vif.cb.sda <= 1;
            repeat(trans.clock_period/4) @(vif.cb);
          end
        end
        else begin
          `uvm_info(get_type_name(),$sformatf("MASTER LOST ARBITRATION, CEIDING CONTROL OVER THE BUS"),UVM_HIGH)
          arbitration_lost.put(1);
          vif.cb.scl <= 1; //free clock
          vif.cb.sda <= 1; //free data
          arb_lost = 0;
          @(vif.cb);
        end
      end

      I2C_SLAVE: begin
        
        if (~repeated_start)
          @(negedge vif.sda iff vif.scl); //start condition
        else
          repeated_start = 0;

        `uvm_info(get_type_name(),$sformatf("SLAVE WILL DRIVE THE FOLLOWING TRANSACTION:\n%s",trans.sprint()),UVM_HIGH)
        
        fork
          slave_read_address(); //get the 7 address bits
          get_clock_period();
        join
        `uvm_info(get_type_name(),$sformatf("SLAVE RECEIVED ADDRESS: %0h, WHILE DEV ADDRESS IS: %0h",addr,dev_addr),UVM_HIGH)
        
        @(posedge vif.scl);
        rw = vif.cb.sda;         //get the operation type
        `uvm_info(get_type_name(),$sformatf("SLAVE RECEIVED OPERATION: %0b",rw),UVM_HIGH)
        @(negedge vif.scl);
        repeat(clock_period/4) @(vif.cb);

        if(addr == dev_addr) begin  //check if the address matches the device address
          
          vif.cb.sda <= 0; //ack

          if(rw) begin
            if(trans.clock_strech)begin
              vif.cb.scl <= 0;
              repeat(2*clock_period) @(vif.cb);
              vif.cb.scl <= 1;
              @(vif.cb);
            end
          end
          
          @(negedge vif.scl);
          repeat(clock_period/4) @(vif.cb);

          if (~rw) begin
            fork: slave_read
              slave_read_byte(trans);   //responde to bytes untill stop condition is detected
              @(posedge vif.sda iff vif.scl); //stop condition
               begin @(negedge vif.sda iff vif.scl); repeated_start = 1; end //repeated start condition
              //@(nack_e);
            join_any
            disable slave_read;
          end
          else begin
            fork: slave_write
              slave_write_byte(trans);  //write bytes until either STOP or NACK happened
              @(nack_e);
            join_any
            disable slave_write;
            vif.cb.sda <= 1;

            fork 
              begin @(negedge vif.sda iff vif.scl); repeated_start = 1; end //repeated start condition
              @(posedge vif.sda iff vif.scl); //stop condition
            join_any

            disable fork;
           
          end
        end
        else begin
          vif.cb.sda <= 1; //nack if address does not match
          @(posedge vif.scl);
        end
      end
    endcase
  endtask: drive_i2c_trans

  task slave_read_address();
    for (int i = 6; i >= 0; i--)begin
      @(posedge vif.scl);
      addr[i] = vif.cb.sda;
    end
  endtask: slave_read_address

  task slave_read_byte(i2c_trans trans);
    forever begin
      vif.cb.sda <= 1; //ceding control over the bus
      // `uvm_info("",$sformatf("WE ARE HERE"),UVM_DEBUG)
      repeat(8) @(negedge vif.scl); 
      repeat(clock_period/4) @(vif.cb);
      //`uvm_info("",$sformatf("THEN HERE"),UVM_DEBUG)
      if(trans.resp.pop_front() == I2C_ACK)begin
        vif.cb.sda <= 0; //ack

        if(trans.clock_strech) begin
          vif.cb.scl <= 0;
          repeat(2*clock_period) @(vif.cb);
          vif.cb.scl <= 1;
          @(vif.cb);
        end

        @(negedge vif.scl);
        repeat(clock_period/4) @(vif.cb);
      end
      else begin
        @(negedge vif.scl);
        repeat(clock_period/4) @(vif.cb);
        ->nack_e;
      end
      
    end
  endtask: slave_read_byte

  task slave_write_byte(i2c_trans trans);
    forever begin
      data = trans.data_q.pop_front();
      `uvm_info(get_type_name(),$sformatf("SLAVE WILL DRIVE BYTE: %b",data),UVM_DEBUG)
      for(int i = 7; i >= 0; i--)begin
        vif.cb.sda <= data[i];
        `uvm_info(get_type_name(),$sformatf("SLAVE DRIVEN BIT: %b",data[i]),UVM_DEBUG)
        @(negedge vif.scl);
        repeat(clock_period/4) @(vif.cb);
      end
      vif.cb.sda <= 1; //ceding control over the bus

      if(trans.clock_strech) begin
        vif.cb.scl <= 0;
        repeat(2*clock_period) @(vif.cb);
        vif.cb.scl <= 1;
        @(vif.cb);
      end
      else
        @(posedge vif.scl);

      if (vif.cb.sda) begin
        `uvm_info(get_type_name(),$sformatf("SLAVE RECEIVED NACK"),UVM_DEBUG)
        ->nack_e;
      end
      else begin
        `uvm_info(get_type_name(),$sformatf("SLAVE RECEIVED ACK"),UVM_DEBUG)
      end
      
      @(negedge vif.scl);
      repeat(clock_period/4) @(vif.cb);
    end
  endtask: slave_write_byte

  task get_clock_period();
    clock_period = 0;

    @(posedge vif.scl);
    fork: count_period
      forever begin 
        @(vif.cb);
        clock_period++;
      end
      @(posedge vif.scl);
    join_any
    disable count_period;
    `uvm_info(get_type_name(),$sformatf("SCL PERIOD IS %0d CLOCK CYCLES",clock_period),UVM_DEBUG)
  endtask

  task master_drive_trans(i2c_trans trans);
    master_write_address_rw(trans);

    driven_high = 0;
    vif.cb.sda <= 1; //ceding control over the bus
    @(posedge vif.scl);
            
    if(~vif.cb.sda) begin //ack
      `uvm_info(get_type_name(),$sformatf("MASTER RECEIVED ACK"),UVM_DEBUG)
      @(negedge vif.scl);
      repeat(trans.clock_period/4) @(vif.cb);
    
      if(trans.kind == I2C_WRITE)
        repeat(size) master_write_byte(trans);
      else
        repeat(size) master_read_byte(trans);
    end
    else begin
      `uvm_info(get_type_name(),$sformatf("MASTER RECEIVED NACK"),UVM_DEBUG)
      @(negedge vif.scl);
      repeat(trans.clock_period/4) @(vif.cb);
    end
  endtask

  task master_drive_clock(i2c_trans trans);
    forever begin
      repeat(trans.clock_period/2) @(vif.cb);
      vif.cb.scl <= 1;
      @(vif.cb);
      if (~vif.cb.scl) begin //check for clock streching
        @(posedge vif.scl);
        repeat(trans.clock_period/2) @(vif.cb);
        vif.cb.scl <= 0;
      end
      else begin
        repeat(trans.clock_period/2 - 1) @(vif.cb);
        vif.cb.scl <= 0;
      end
    end
  endtask: master_drive_clock

  task master_write_address_rw(i2c_trans trans);
    for(int i = 6; i >= 0; i--) begin
      repeat(trans.clock_period/4) @(vif.cb);
      vif.cb.sda <= trans.addr[i];
      driven_high = trans.addr[i];
      `uvm_info(get_type_name(),$sformatf("MASTER DRIVEN ADDRESS BIT: : %0b",trans.addr[i]),UVM_DEBUG)
      @(negedge vif.scl);
    end

    repeat(trans.clock_period/4) @(vif.cb);

    if (trans.kind == I2C_READ) begin
      vif.cb.sda <= 1;
      driven_high = 1;
      `uvm_info(get_type_name(),$sformatf("MASTER DRIVEN OPERATION BIT: : READ"),UVM_DEBUG)
    end
    else begin
      vif.cb.sda <= 0;
      driven_high = 0;
      `uvm_info(get_type_name(),$sformatf("MASTER DRIVEN OPERATION BIT: : WRITE"),UVM_DEBUG)
    end
    @(negedge vif.scl);
    repeat(trans.clock_period/4) @(vif.cb);
    `uvm_info(get_type_name(),$sformatf("MASTER DONE WRITING THE ADDRESS AND RW"),UVM_DEBUG)
  endtask: master_write_address_rw

  task master_write_byte(i2c_trans trans);
    data = trans.data_q.pop_front();
    `uvm_info(get_type_name(),$sformatf("MASTER WILL WRITE BYTE: %b",data),UVM_DEBUG)

    for(int i = 7; i >= 0; i--) begin
      vif.cb.sda <= data[i];
      driven_high = data[i];
      @(negedge vif.scl);
      repeat(trans.clock_period/4) @(vif.cb);
      `uvm_info(get_type_name(),$sformatf("MASTER DRIVEN BIT: : %0b",data[i]),UVM_DEBUG)
    end
    `uvm_info(get_type_name(),$sformatf("MASTER DONE WRITING A BYTE"),UVM_DEBUG)

    vif.cb.sda <= 1; //ceding control over the bus
    driven_high = 0;

    @(posedge vif.scl);
    if (~vif.cb.sda) begin
      @(negedge vif.scl);
      repeat(trans.clock_period/4) @(vif.cb);
      `uvm_info(get_type_name(),$sformatf("MASTER RECEIVED ACK"),UVM_DEBUG)
    end
    else begin
      @(negedge vif.scl);
      repeat(trans.clock_period/4) @(vif.cb);
      `uvm_info(get_type_name(),$sformatf("MASTER RECEIVED NACK"),UVM_DEBUG)
      ->nack_e;
    end
  endtask: master_write_byte

  task master_read_byte(i2c_trans trans);
    vif.cb.sda <= 1; //ceding control over the bus
    driven_high = 0;
    repeat(8) @(posedge vif.scl);
    @(negedge vif.scl);
    repeat(trans.clock_period/4) @(vif.cb);

    if (trans.resp.pop_front() == I2C_ACK) begin
      vif.cb.sda <= 0;
      @(negedge vif.scl);
      repeat(trans.clock_period/4) @(vif.cb);
    end
    else begin
      driven_high = 1;
      @(negedge vif.scl);
      repeat(trans.clock_period/4) @(vif.cb);
      ->nack_e;
    end
  endtask: master_read_byte

  task check_arb();
  arb_lost = 0;
  while (~arb_lost) begin
    @(negedge vif.scl);
    if(~vif.cb.sda & driven_high) begin
      @(vif.cb);
      if (~vif.cb.sda & driven_high)
        arb_lost = 1;
    end
  end
  `uvm_info(get_type_name(),$sformatf("DIFFERENCE IN DRIVING"),UVM_DEBUG)
  endtask

endclass

`endif