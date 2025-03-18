`ifndef APB_BASE_SEQUENCE_GUARD
`define APB_BASE_SEQUENCE_GUARD

class apb_base_sequence #(AW=32,DW=32) extends uvm_sequence #(apb_trans #(AW,DW));

  `uvm_object_param_utils(apb_base_sequence)
  
  function new(string name = "apb_base_sequence");
    super.new(name);
  endfunction:new
  
  // Raising objection before starting body
  virtual task pre_body();
    starting_phase.raise_objection(this);
  endtask

  task whatchdog();
    bit [12-1:0] counter     = 'd3000;
    bit          trans_ended         ;
    bit          trans_started       ;
    fork
      begin
        while (counter != 0) begin
          if (trans_ended) begin
            trans_ended = 0;
            counter = 3000;
          end
          else begin
            if(trans_started)
              counter--;
            #1;
          end
        end
      end
      forever begin
        wait_for_grant();
        trans_started = 1;
        wait_for_item_done();
        trans_ended   = 1;
        trans_started = 0;
      end
    join_any
  endtask
  
  // Droping objection after finishing body
  virtual task post_body();
    starting_phase.drop_objection(this);
  endtask
  
endclass:apb_base_sequence

`endif