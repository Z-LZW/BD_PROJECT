`ifndef REGISTER_MODEL_GUARD
`define REGISTER_MODEL_GUARD

class tx_fifo_data_reg extends uvm_reg;

  rand uvm_reg_field value;

  `uvm_object_utils(tx_fifo_data_reg)

  function new(string name = "tx_fifo_data_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    value = uvm_reg_field::type_id::create("value");

    value.configure(this,8,0,"WO",0,32'h0,1,1,0);
  endfunction
endclass

class rx_fifo_data_reg extends uvm_reg;

  rand uvm_reg_field value;

  `uvm_object_utils(rx_fifo_data_reg)

  function new(string name = "rx_fifo_data_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    value = uvm_reg_field::type_id::create("value");

    value.configure(this,8,0,"RO",0,32'h0,1,1,0);
  endfunction
endclass

class addr_reg extends uvm_reg;

  rand uvm_reg_field target_addr;
  rand uvm_reg_field device_addr;

  `uvm_object_utils(addr_reg)

  function new(string name = "addr_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    target_addr = uvm_reg_field::type_id::create("target_addr");
    device_addr = uvm_reg_field::type_id::create("device_addr");

    target_addr.configure(this,7,8,"RW",0,32'h0,1,1,0);
    device_addr.configure(this,7,0,"RW",0,32'h0,1,1,0);
  endfunction
endclass

class ctrl_reg extends uvm_reg;

  rand uvm_reg_field rx_fifo_lim;
  rand uvm_reg_field tx_fifo_lim;
  rand uvm_reg_field enable_ack ;
  rand uvm_reg_field enable_dev ;
  rand uvm_reg_field mode       ;

  `uvm_object_utils(ctrl_reg)

  function new(string name = "ctrl_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    rx_fifo_lim = uvm_reg_field::type_id::create("rx_fifo_lim");
    tx_fifo_lim = uvm_reg_field::type_id::create("tx_fifo_lim");
    enable_ack  = uvm_reg_field::type_id::create("enable_ack" );
    enable_dev  = uvm_reg_field::type_id::create("enable_dev" );
    mode        = uvm_reg_field::type_id::create("mode"       );

    rx_fifo_lim.configure(this,8,16,"RW",0,32'h0,1,1,0);
    tx_fifo_lim.configure(this,8, 8,"RW",0,32'h0,1,1,0);
    enable_ack.configure (this,1, 2,"RW",0,32'h0,1,1,0); 
    enable_dev.configure (this,1, 1,"RW",0,32'h0,1,1,0); 
    mode.configure       (this,1, 0,"RW",0,32'h0,1,1,0);       
  endfunction
endclass

class cmd_reg extends uvm_reg;

  rand uvm_reg_field clear_irq;
  rand uvm_reg_field clear_rx ;
  rand uvm_reg_field clear_tx ;
  rand uvm_reg_field read_f     ;
  rand uvm_reg_field write_f    ;

  `uvm_object_utils(cmd_reg)

  function new(string name = "cmd_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    clear_irq = uvm_reg_field::type_id::create("clear_irq");
    clear_rx  = uvm_reg_field::type_id::create("clear_rx" );
    clear_tx  = uvm_reg_field::type_id::create("clear_tx" );
    read_f    = uvm_reg_field::type_id::create("read_f"   );
    write_f   = uvm_reg_field::type_id::create("write_f"  );

    clear_irq.configure(this,1,4,"WO",0,32'h0,1,1,0);
    clear_rx.configure (this,1,3,"WO",0,32'h0,1,1,0);
    clear_tx.configure (this,1,2,"WO",0,32'h0,1,1,0); 
    read_f.configure   (this,1,1,"WO",0,32'h0,1,1,0); 
    write_f.configure  (this,1,0,"WO",0,32'h0,1,1,0);       

  endfunction
endclass

class status_reg extends uvm_reg;

  rand uvm_reg_field byte_cnt;
  rand uvm_reg_field al      ;
  rand uvm_reg_field nack    ;
  rand uvm_reg_field bsy     ;
  rand uvm_reg_field tip     ;

  `uvm_object_utils(status_reg)

  function new(string name = "status_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    byte_cnt = uvm_reg_field::type_id::create("byte_cnt");
    al       = uvm_reg_field::type_id::create("al"      );
    nack     = uvm_reg_field::type_id::create("nack"    );
    bsy      = uvm_reg_field::type_id::create("bsy"     );
    tip      = uvm_reg_field::type_id::create("tip"     );

    byte_cnt.configure(this,9,8,"RO",0,32'h0,1,1,0);
    al.configure      (this,1,3,"RO",0,32'h0,1,1,0);
    nack.configure    (this,1,2,"RO",0,32'h0,1,1,0); 
    bsy.configure     (this,1,1,"RO",0,32'h0,1,1,0); 
    tip.configure     (this,1,0,"RO",0,32'h0,1,1,0);       
  endfunction
endclass

class irq_reg extends uvm_reg;

  rand uvm_reg_field rx_fifo_empty;
  rand uvm_reg_field tx_fifo_full ;
  rand uvm_reg_field rx_fail      ;
  rand uvm_reg_field tx_fail      ;
  rand uvm_reg_field rx_done      ;
  rand uvm_reg_field tx_done      ;

  `uvm_object_utils(irq_reg)

  function new(string name = "irq_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    rx_fifo_empty = uvm_reg_field::type_id::create("rx_fifo_empty");
    tx_fifo_full  = uvm_reg_field::type_id::create("tx_fifo_full ");
    rx_fail       = uvm_reg_field::type_id::create("rx_fail");
    tx_fail       = uvm_reg_field::type_id::create("tx_fail");
    rx_done       = uvm_reg_field::type_id::create("rx_done");
    tx_done       = uvm_reg_field::type_id::create("tx_done");

    rx_fifo_empty.configure(this,1,5,"RO",0,32'h0,1,1,0);
    tx_fifo_full .configure(this,1,4,"RO",0,32'h0,1,1,0);
    rx_fail.configure      (this,1,3,"RO",0,32'h0,1,1,0); 
    tx_fail.configure      (this,1,2,"RO",0,32'h0,1,1,0); 
    rx_done.configure      (this,1,1,"RO",0,32'h0,1,1,0);       
    tx_done.configure      (this,1,0,"RO",0,32'h0,1,1,0);       
  endfunction
endclass

class irq_mask_reg extends uvm_reg;

  rand uvm_reg_field rx_fifo_empty_mask;
  rand uvm_reg_field tx_fifo_full_mask ;
  rand uvm_reg_field rx_fail_mask      ;
  rand uvm_reg_field tx_fail_mask      ;
  rand uvm_reg_field rx_done_mask      ;
  rand uvm_reg_field tx_done_mask      ;

  `uvm_object_utils(irq_mask_reg)

  function new(string name = "irq_mask_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    rx_fifo_empty_mask = uvm_reg_field::type_id::create("rx_fifo_empty");
    tx_fifo_full_mask  = uvm_reg_field::type_id::create("tx_fifo_full" );
    rx_fail_mask       = uvm_reg_field::type_id::create("rx_fail"      );
    tx_fail_mask       = uvm_reg_field::type_id::create("tx_fail"      );
    rx_done_mask       = uvm_reg_field::type_id::create("rx_done"      );
    tx_done_mask       = uvm_reg_field::type_id::create("tx_done"      );

    rx_fifo_empty_mask.configure(this,1,5,"RW",0,32'h0,1,1,0);
    tx_fifo_full_mask.configure (this,1,4,"RW",0,32'h0,1,1,0);
    rx_fail_mask.configure      (this,1,3,"RW",0,32'h0,1,1,0); 
    tx_fail_mask.configure      (this,1,2,"RW",0,32'h0,1,1,0); 
    rx_done_mask.configure      (this,1,1,"RW",0,32'h0,1,1,0);       
    tx_done_mask.configure      (this,1,0,"RW",0,32'h0,1,1,0);       
  endfunction
endclass

class divider_reg extends uvm_reg;
   
  rand uvm_reg_field clock_div;
  
  `uvm_object_utils(divider_reg)
    
  function new(string name = "divider_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    clock_div = uvm_reg_field::type_id::create("clock_div");

    clock_div.configure(this,16,0,"RW",0, 32'h0000ffff,1,1,0);
  endfunction                                               
endclass

class reg_blk extends uvm_reg_block;

  `uvm_object_utils(reg_blk)

  rand tx_fifo_data_reg tx_fifo_data;
  rand rx_fifo_data_reg rx_fifo_data;
  rand addr_reg         addr        ;
  rand ctrl_reg         ctrl        ; 
  rand cmd_reg          cmd         ;
  rand status_reg       status      ;
  rand irq_reg          irq         ;
  rand irq_mask_reg     irq_mask    ;
  rand divider_reg      divider     ;

  uvm_reg_map apb_regs_map;

  function new(string name = "reg_blk");
    super.new(.name(name), .has_coverage(UVM_NO_COVERAGE));
  endfunction

  virtual function void build();
  
    apb_regs_map = create_map("reg_map", 'h0, 4, UVM_LITTLE_ENDIAN);

    tx_fifo_data = tx_fifo_data_reg::type_id::create("tx_fifo_data");
    tx_fifo_data.configure(this);
    tx_fifo_data.build();

    rx_fifo_data = rx_fifo_data_reg::type_id::create("rx_fifo_data");
    rx_fifo_data.configure(this);
    rx_fifo_data.build();

    addr = addr_reg::type_id::create("addr");
    addr.configure(this);
    addr.build();

    ctrl = ctrl_reg::type_id::create("ctrl");
    ctrl.configure(this);
    ctrl.build();

    cmd = cmd_reg::type_id::create("cmd");
    cmd.configure(this);
    cmd.build();

    status = status_reg::type_id::create("status");
    status.configure(this);
    status.build();

    irq = irq_reg::type_id::create("irq");
    irq.configure(this);
    irq.build();

    irq_mask = irq_mask_reg::type_id::create("irq_mask");
    irq_mask.configure(this);
    irq_mask.build();

    divider = divider_reg::type_id::create("divider");
    divider.configure(this);
    divider.build();

    // add each cmd to the registers map
    apb_regs_map.add_reg(tx_fifo_data,'h00,"WO");
    apb_regs_map.add_reg(rx_fifo_data,'h04,"RO");
    apb_regs_map.add_reg(addr        ,'h08,"RW");
    apb_regs_map.add_reg(ctrl        ,'h0C,"RW");
    apb_regs_map.add_reg(cmd         ,'h10,"WO");
    apb_regs_map.add_reg(status      ,'h14,"RO");
    apb_regs_map.add_reg(irq         ,'h18,"RO");
    apb_regs_map.add_reg(irq_mask    ,'h1C,"RW");
    apb_regs_map.add_reg(divider     ,'h20,"RW");
    
  endfunction

endclass

`endif