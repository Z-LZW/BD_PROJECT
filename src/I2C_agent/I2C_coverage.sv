`ifndef I2C_COVERAGE_GUARD
`define I2C_COVERAGE_GUARD

class i2c_coverage extends uvm_subscriber#(i2c_trans);

  i2c_trans trans;

  i2c_resp_kind_t resp;
  bit [8-1:0]     data;

  `uvm_component_utils(i2c_coverage)

  covergroup i2c_address_frame_cov;
    option.per_instance = 1;

    address_cov: coverpoint trans.addr{
      bins minim     = {     0 };
      bins maxim     = {   127 };
      bins range[10] = {[1:126]};
    }

    operation_cov: coverpoint trans.kind{
      bins read  = {I2C_READ };
      bins write = {I2C_WRITE}; 
    }

    addr_response_cov: coverpoint trans.resp.pop_front(){
      bins ack  = {I2C_ACK };
      bins nack = {I2C_NACK};
    }

    size_range: coverpoint trans.data_q.size(){
      bins no_data   = {     0 };
      bins minim     = {     1 };
      bins maxim     = {   256 };
      bins range[10] = {[2:255]};

      ignore_bins outside_range = {[257:$]};
    }

    clock_streaching_cov: coverpoint trans.clock_strech{
      bins no_strech = {0};
      bins strech    = {1};
    }

    repeated_start_cov: coverpoint trans.repeated_start{
      bins repeated_start = {1};
      bins normal_stop    = {0};
    }

    clock_period_cov: coverpoint trans.clock_period{
      bins range[16] = {[10:$]};
    }

    arb_lost_cov: coverpoint trans.arb_lost{
      bins arb_lost     = {1};
      bins arb_not_lsot = {0};
    }

    address_x_operation: cross address_cov, operation_cov;

    operation_x_size_cross: cross size_range,operation_cov;

    operation_x_response_x_size_cross: cross size_range, operation_cov, resp{
      ignore_bins read = binsof(operation_cov.read);
    }

    address_x_response: cross address_cov,addr_response_cov;
  endgroup

  covergroup i2c_data_frames_cov;
    option.per_instance = 1;

    data_cov: coverpoint data{
      bins range[10] = {[0:$]};
    }

    data_response_cov: coverpoint resp{
      bins ack  = {I2C_ACK };
      bins nack = {I2C_NACK};
    }

    data_x_operation_cross: cross data_cov, trans.kind;
  endgroup

  function new(string name = "i2c_coverage", uvm_component parent = null);
    super.new(name,parent);
    i2c_address_frame_cov = new;
    i2c_data_frames_cov   = new;
    trans = new;
  endfunction

  virtual function void write(i2c_trans t);
    i2c_trans trans_local;

    trans.copy(t);
    resp = trans.resp[$];
    i2c_address_frame_cov.sample();

    while(trans.data_q.size() != 0) begin
      data = trans.data_q.pop_front();
      resp = trans.resp.pop_front();
      i2c_data_frames_cov.sample();
    end
  endfunction

endclass

`endif