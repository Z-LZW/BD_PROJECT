`ifndef I2C_INTERFACE_GUARD
`define I2C_INTERFACE_GUARD

interface i2c_interface (input clk,rst_n);

  triand sda;
  triand scl;

  bit enable;

  clocking cb @(posedge clk);
    inout sda;
    inout scl;
  endclocking

  clocking mon_cb @(posedge clk);
    input sda;
    input scl;
  endclocking

  initial forever begin
    @(negedge sda iff scl);
    enable <= 1;
    @(posedge sda iff scl);
    enable <= 0;
  end

//----------------------------ASSERTIONS---------------------------//

  property not_unknown(signal);
    @(posedge clk) disable iff (~rst_n)
      !$isunknown(signal);
  endproperty

  property stable;
    @(posedge clk iff scl) disable iff (~enable)
      $stable(sda);
  endproperty

  scl_known: assert property(not_unknown(sda)) else $fatal("SDA must not be X or Z while reset is not asserted");
  sda_known: assert property(not_unknown(scl)) else $fatal("SCL must not be X or Z while reset is not asserted");

  //sda_stable: assert property(stable) else $fatal("SDA mut be stable durring a transaction while SCL is high");

endinterface

`endif