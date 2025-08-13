//======================================================================
// File    : rtl_regfile.v
// Purpose : 2R1W register file with hard-wired x0 (optional)
// Project : digital_risc_toy_pipeline
// Author  : Jooho Hwang
// License : MIT
//----------------------------------------------------------------------
// Notes
// - Synchronous write at posedge clk.
// - Combinational read ports (typical for simple pipelines).
// - If REG_ZERO is 0, read returns zero regardless of storage.
//======================================================================

`include "defs.vh"

module rtl_regfile (
  input  wire                  clk,
  input  wire                  rst_n,

  input  wire                  we,
  input  wire [`REG_ADDR_W-1:0] waddr,
  input  wire [`XLEN-1:0]      wdata,

  input  wire [`REG_ADDR_W-1:0] raddr_a,
  output wire [`XLEN-1:0]      rdata_a,

  input  wire [`REG_ADDR_W-1:0] raddr_b,
  output wire [`XLEN-1:0]      rdata_b,

  // Optional debug tap
  output wire [`XLEN-1:0]      dbg_x1
);

  localparam NREG = `REG_COUNT;

  reg [`XLEN-1:0] mem [0:NREG-1];
  integer i;

  // init/reset (simulation-friendly; hardware may ignore)
  always @(negedge rst_n) begin : gpr_reset
    if (!rst_n) begin
      for (i = 0; i < NREG; i = i + 1) mem[i] <= {`XLEN{1'b0}};
    end
  end

  // write port
  always @(posedge clk) begin
    if (we && (waddr != `REG_ZERO)) begin
      mem[waddr] <= wdata;
    end
  end

  // read ports (combinational)
  wire [`XLEN-1:0] raw_a = mem[raddr_a];
  wire [`XLEN-1:0] raw_b = mem[raddr_b];

  assign rdata_a = (raddr_a == `REG_ZERO) ? {`XLEN{1'b0}} : raw_a;
  assign rdata_b = (raddr_b == `REG_ZERO) ? {`XLEN{1'b0}} : raw_b;

  // debug (x1 example)
  assign dbg_x1  = mem[5'd1];

endmodule