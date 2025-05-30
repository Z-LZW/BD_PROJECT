`ifndef REG_APB_ADAPTER_GUARD
`define REG_APB_ADAPTER_GUARD

class reg_apb_adapter#(AW=32,DW=32) extends uvm_reg_adapter;

  `uvm_object_param_utils(reg_apb_adapter#(AW,DW))

  function new(string name = "reg_apb_adapter");
    super.new(name);
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    apb_trans#(AW,DW) trans;
    trans = new;
    assert (trans.randomize());
    trans.kind = (rw.kind == UVM_READ) ? APB_READ : APB_WRITE;
    trans.addr = rw.addr;
    if(trans.addr != 0)
      trans.data = rw.data;
    return trans;
  endfunction

  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    apb_trans#(AW,DW) trans;
    if (!$cast(trans,bus_item)) begin
      `uvm_fatal("NOT_APB_TYPE","Provided bus_item is not of the correct type")
      return;
    end
      rw.kind = (trans.kind == APB_READ) ? UVM_READ : UVM_WRITE;
      rw.addr = trans.addr;
      rw.data = trans.data;
      rw.status = UVM_IS_OK;
  endfunction

endclass

`endif