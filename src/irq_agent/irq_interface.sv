`ifndef IRQ_INTERFACE_GUARD
`define IRQ_INTERFACE_GUARD

interface irq_interface(input clk, input rst_n);

  bit irq;

  clocking mon_cb @(posedge clk);
    input irq;
  endclocking

endinterface

`endif