`ifndef APB_COVERAGE_GUARD
`define APB_COVERAGE_GUARD

class apb_coverage extends uvm_subscriber#(apb_trans #(AW,DW));

  apb_trans trans;

  `uvm_component_utils(reg_bank_coverage)

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
      ignore_bins {'h00,'h04,'h08,'h0c,'h10,'h14,'h18,'h1c,'h20};
    }

    read_write_cov: coverpoint trans.kind{
      bins write = {APB_WRITE};
      bins read  = {APB_READ };
    }

    

  endgroup

endclass

`endif