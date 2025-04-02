`ifndef APB_COVERAGE_GUARD
`define APB_COVERAGE_GUARD

class apb_coverage #(AW=32,DW=32) extends uvm_subscriber#(apb_trans #(AW,DW));

  apb_trans trans;

  `uvm_component_param_utils(apb_coverage)

  covergroup apb_func_cov;
    option.per_instance = 1;

    valid_address_cov: coverpoint trans.addr{
      bins tx_fifo_data = {'h00};
      bins rx_fifo_data = {'h04};
      bins addr         = {'h08};
      bins ctrl         = {'h0c};
      bins cmd          = {'h10};
      bins status       = {'h14};
      bins irq          = {'h18};
      bins irq_mask     = {'h1c};
      bins divider      = {'h20};
    }

    invalid_address_cov: coverpoint trans.addr{
      ignore_bins valid = {'h00,'h04,'h08,'h0c,'h10,'h14,'h18,'h1c,'h20};
    }

    read_write_cov: coverpoint trans.kind{
      bins write = {APB_WRITE};
      bins read  = {APB_READ };
    }

    resp_kind_cov: coverpoint trans.resp{
      bins okay  = {APB_OKAY};
      bins error = {APB_ERROR};
    }

    read_write_x_valid_address_cross: cross valid_address_cov,read_write_cov;

    slverr_x_invalid_addr_corss: cross invalid_address_cov,resp_kind_cov{
      ignore_bins apb_ok = binsof(resp_kind_cov.okay);
    }

    endgroup

    function new(string name = "apb_coverage", uvm_component parent = null);
      super.new(name, parent);
      // new to covergroups
      apb_func_cov = new;
    endfunction : new

  virtual function void write (apb_trans t);
    //trans = t;
    //reg_bank_cov.sample();
  endfunction : write
  

endclass

`endif