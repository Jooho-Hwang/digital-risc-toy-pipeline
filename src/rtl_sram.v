//======================================================================
// File    : rtl_sram.v
// Purpose : Simple synchronous single-port RAM (1-cycle read latency)
// Project : digital_risc_toy_pipeline
// Author  : Jooho Hwang
// License : MIT
//----------------------------------------------------------------------
// Notes
// - Intended for simulation / lightweight synthesis.
// - Read data is registered (valid next cycle).
// - Optional hex initialization via INIT_HEX parameter.
//======================================================================

`include "defs.vh"

module rtl_sram #(
  parameter integer ADDR_W   = `MEM_ADDR_W,
  parameter integer DATA_W   = `MEM_DATA_W,
  parameter string  INIT_HEX = ""        // set to a .mem/.hex file to preload
)(
  input  wire                   clk,
  input  wire                   rst_n,
  input  wire                   ce,      // chip enable
  input  wire                   we,      // write enable
  input  wire [ADDR_W-1:0]      addr,
  input  wire [DATA_W-1:0]      wdata,
  output reg  [DATA_W-1:0]      rdata
);
  localparam integer DEPTH = (1 << ADDR_W);

  reg [DATA_W-1:0] mem [0:DEPTH-1];

  // optional preload
  initial begin
    if (INIT_HEX != "") begin
      $display("[rtl_sram] INIT_HEX = %0s", INIT_HEX);
      $readmemh(INIT_HEX, mem);
    end
  end

  // synchronous read & write
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rdata <= {DATA_W{1'b0}};
    end else if (ce) begin
      if (we) begin
        mem[addr] <= wdata;
      end
      rdata <= mem[addr];
    end
  end

endmodule