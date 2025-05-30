`ifndef IRQ_AGENT_GUARD
`define IRQ_AGENT_GUARD

class irq_agent extends uvm_agent;

  `uvm_component_utils(irq_agent)

  irq_monitor monitor;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = irq_monitor::type_id::create("monitor",this);
  endfunction

endclass

`endif