`ifndef BASE_TEST_GUARD
`define BASE_TEST_GUARD

class base_test extends uvm_test;

  `uvm_component_utils(base_test)

  environment#(6,32) env;

  uvm_report_server srvr;
  int get_uvm_error_count;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    srvr = uvm_report_server::get_server();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    //apb config
    uvm_config_db #(uvm_bitstream_t)::set(this,"env.apb_master_agent", "agent_kind", APB_MASTER);
    uvm_config_db #(uvm_bitstream_t)::set(this,"env.apb_master_agent", "is_active", UVM_ACTIVE);
    uvm_config_db #(int)::set(this,"env.apb_master_agent.monitor", "has_checks", 1);
    uvm_config_db #(int)::set(this,"env.apb_master_agent.monitor", "has_coverage", 1);

    uvm_config_db #(uvm_bitstream_t)::set(this,"env.apb_slave_agent", "agent_kind", APB_SLAVE);
    uvm_config_db #(uvm_bitstream_t)::set(this,"env.apb_slave_agent", "is_active", UVM_ACTIVE);
    uvm_config_db #(int)::set(this,"env.apb_slave_agent.monitor", "has_checks", 1);
    uvm_config_db #(int)::set(this,"env.apb_slave_agent.monitor", "has_coverage", 1);

    //system agent
    uvm_config_db #(uvm_bitstream_t)::set(this,"env.sys_agent","is_active",UVM_ACTIVE);

    env = environment#(6,32)::type_id::create("env",this);
  endfunction

  virtual function void start_of_simulation_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  function void report_phase(uvm_phase phase);
 
    get_uvm_error_count = srvr.get_severity_count(UVM_ERROR);


    if(get_uvm_error_count == 0) begin
      $display("\n");
      $display("PPPPPPPPPPPPPPPPP        AAA                 SSSSSSSSSSSSSSS    SSSSSSSSSSSSSSS ");
      $display("P::::::::::::::::P      A:::A              SS:::::::::::::::S SS:::::::::::::::S");
      $display("P::::::PPPPPP:::::P    A:::::A            S:::::SSSSSS::::::SS:::::SSSSSS::::::S");
      $display("PP:::::P     P:::::P  A:::::::A           S:::::S     SSSSSSSS:::::S     SSSSSSS");
      $display("  P::::P     P:::::P A:::::::::A          S:::::S            S:::::S            ");
      $display("  P::::P     P:::::PA:::::A:::::A         S:::::S            S:::::S            ");
      $display("  P::::PPPPPP:::::PA:::::A A:::::A         S::::SSSS          S::::SSSS         ");
      $display("  P:::::::::::::PPA:::::A   A:::::A         SS::::::SSSSS      SS::::::SSSSS    ");
      $display("  P::::PPPPPPPPP A:::::A     A:::::A          SSS::::::::SS      SSS::::::::SS  ");
      $display("  P::::P        A:::::AAAAAAAAA:::::A            SSSSSS::::S        SSSSSS::::S ");
      $display("  P::::P       A:::::::::::::::::::::A                S:::::S            S:::::S");
      $display("  P::::P      A:::::AAAAAAAAAAAAA:::::A               S:::::S            S:::::S");
      $display("PP::::::PP   A:::::A             A:::::A  SSSSSSS     S:::::SSSSSSSS     S:::::S");
      $display("P::::::::P  A:::::A               A:::::A S::::::SSSSSS:::::SS::::::SSSSSS:::::S");
      $display("P::::::::P A:::::A                 A:::::AS:::::::::::::::SS S:::::::::::::::SS ");
      $display("PPPPPPPPPPAAAAAAA                   AAAAAAASSSSSSSSSSSSSSS    SSSSSSSSSSSSSSS   ");
    end
    else begin
      $display("\n");
      $display("FFFFFFFFFFFFFFFFFFFFFF      AAA               IIIIIIIIIILLLLLLLLLLL             ");
      $display("F::::::::::::::::::::F     A:::A              I::::::::IL:::::::::L             ");
      $display("F::::::::::::::::::::F    A:::::A             I::::::::IL:::::::::L             ");
      $display("FF::::::FFFFFFFFF::::F   A:::::::A            II::::::IILL:::::::LL             ");
      $display("  F:::::F       FFFFFF  A:::::::::A             I::::I    L:::::L               ");
      $display("  F:::::F              A:::::A:::::A            I::::I    L:::::L               ");
      $display("  F::::::FFFFFFFFFF   A:::::A A:::::A           I::::I    L:::::L               ");
      $display("  F:::::::::::::::F  A:::::A   A:::::A          I::::I    L:::::L               ");
      $display("  F:::::::::::::::F A:::::A     A:::::A         I::::I    L:::::L               ");
      $display("  F::::::FFFFFFFFFFA:::::AAAAAAAAA:::::A        I::::I    L:::::L               ");
      $display("  F:::::F         A:::::::::::::::::::::A       I::::I    L:::::L               ");
      $display("  F:::::F        A:::::AAAAAAAAAAAAA:::::A      I::::I    L:::::L         LLLLLL");
      $display("FF:::::::FF     A:::::A             A:::::A   II::::::IILL:::::::LLLLLLLLL:::::L");
      $display("F::::::::FF    A:::::A               A:::::A  I::::::::IL::::::::::::::::::::::L");
      $display("F::::::::FF   A:::::A                 A:::::A I::::::::IL::::::::::::::::::::::L");
      $display("FFFFFFFFFFF  AAAAAAA                   AAAAAAAIIIIIIIIIILLLLLLLLLLLLLLLLLLLLLLLL");
    end
  endfunction

endclass

`endif