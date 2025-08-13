//======================================================================
// File    : tb_risc_toy_core.v
// Purpose : Minimal testbench for RISC_TOY_CORE (compile/run harness)
// Project : digital_risc_toy_pipeline
// Author  : Jooho Hwang
// License : MIT
//----------------------------------------------------------------------
// Usage (Icarus Verilog):
//   iverilog -g2012 -DSIM -o tb \
//     ../src/rtl_sram.v ../src/rtl_regfile.v ../src/risc_toy_core.v tb_risc_toy_core.v && \
//   vvp tb +IMEM=prog_basic.mem +MAX=2000
//
// Notes
// - This TB is intentionally light: it drives clk/rst, instantiates the DUT,
//   and runs a bounded number of cycles while dumping a VCD.
// - Program image path is passed to the core via parameter IMEM_INIT.
// - No self-checkers beyond simple assertions (extend in future).
//======================================================================

`timescale 1ns/1ps
`define TB_HZ     100_000_000        // 100 MHz default
`define TB_TCK_NS (1_000_000_000/`TB_HZ)

`include "../src/defs.vh"

module tb_risc_toy_core;

  // --------------------------------------------
  // Clock / Reset
  // --------------------------------------------
  reg clk;
  reg rst_n;

  initial begin
    clk = 1'b0;
    forever #(`TB_TCK_NS/2) clk = ~clk; // 100 MHz by default
  end

  // Active-low reset: hold low for a few cycles
  initial begin
    rst_n = 1'b0;
    repeat (8) @(posedge clk);
    rst_n = 1'b1;
  end

  // --------------------------------------------
  // Plusargs: IMEM image path and max cycles
  // --------------------------------------------
  string imem_path;
  integer max_cycles;

  initial begin
    imem_path = "prog_basic.mem"; // default stub (file optional for now)
    if ($value$plusargs("IMEM=%s", imem_path)) begin
      $display("[TB] Using IMEM image: %0s", imem_path);
    end else begin
      $display("[TB] IMEM not specified, default: %0s", imem_path);
    end

    max_cycles = 2000;
    void'($value$plusargs("MAX=%d", max_cycles));
    $display("[TB] MAX cycles: %0d", max_cycles);
  end

  // --------------------------------------------
  // DUT
  // --------------------------------------------
  wire [`ADDR_W-1:0] dbg_pc;
  wire [`XLEN-1:0]   dbg_reg_x1;

  RISC_TOY_CORE #(
    .IMEM_INIT(imem_path),
    .DMEM_INIT("")
  ) dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .dbg_pc    (dbg_pc),
    .dbg_reg_x1(dbg_reg_x1)
  );

  // --------------------------------------------
  // Wave dump
  // --------------------------------------------
  initial begin
    $dumpfile("tb_risc_toy_core.vcd");
    $dumpvars(0, tb_risc_toy_core);
  end

  // --------------------------------------------
  // Cycle counter / stop condition
  // --------------------------------------------
  integer cycles;
  initial cycles = 0;

  always @(posedge clk) begin
    if (!rst_n) begin
      cycles <= 0;
    end else begin
      cycles <= cycles + 1;

      // Simple live log every N cycles (reduce spam if needed)
      if ((cycles % 50) == 0) begin
        $display("[%0t] cyc=%0d  PC=0x%08h  x1=0x%08h",
                 $time, cycles, dbg_pc, dbg_reg_x1);
      end

      // Bounded run
      if (cycles >= max_cycles) begin
        $display("[TB] Reached MAX cycles (%0d). Finishing.", max_cycles);
        $finish;
      end
    end
  end

  // --------------------------------------------
  // Basic sanity assertions (SIM only)
  // --------------------------------------------
`ifdef SIM
  // Example: PC must stay word-aligned
  always @(posedge clk) if (rst_n) begin
    `ASSERT(dbg_pc[1:0] == 2'b00, "PC not word-aligned")
  end
`endif

endmodule