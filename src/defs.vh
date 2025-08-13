//======================================================================
// File    : defs.vh
// Purpose : Common definitions (widths, enums, opcodes, helpers)
// Project : digital_risc_toy_pipeline
// Author  : Jooho Hwang
// License : MIT
//----------------------------------------------------------------------
// Notes
// - Keep this header minimal and implementation-agnostic.
// - If the ISA bit layout differs, adjust the field ranges in Section 4.
// - All RTL modules should `include "defs.vh"` and avoid magic numbers.
//======================================================================

`ifndef __DEFS_VH__
`define __DEFS_VH__

//----------------------------------------------------------------------
// 1) Core widths / common parameters
//----------------------------------------------------------------------
`define XLEN            32              // Datapath width
`define ADDR_W          32              // PC / address width

`define REG_COUNT       32              // General-purpose registers
`define REG_ADDR_W      5               // log2(REG_COUNT)

`define MEM_ADDR_W      16              // On-chip SRAM address width (sim)
`define MEM_DATA_W      `XLEN
`define MEM_DEPTH       (1 << `MEM_ADDR_W)

// Reset convention (active-low async, sync release by default)
`define RST_ACTIVE_L    1'b0

//----------------------------------------------------------------------
// 2) Pipeline stage IDs (for tracing / debug)
//----------------------------------------------------------------------
`define STG_IF          3'd0
`define STG_ID          3'd1
`define STG_EX          3'd2
`define STG_MEM         3'd3
`define STG_WB          3'd4

//----------------------------------------------------------------------
// 3) ALU operation codes (internal control)
//    Keep compact; only list what the design actually uses.
//----------------------------------------------------------------------
`define ALU_ADD         5'd0
`define ALU_SUB         5'd1
`define ALU_NEG         5'd2
`define ALU_AND         5'd3
`define ALU_OR          5'd4
`define ALU_XOR         5'd5
`define ALU_SLL         5'd6
`define ALU_SRL         5'd7
`define ALU_SRA         5'd8
`define ALU_SLT         5'd9
// ... extend if/when needed

//----------------------------------------------------------------------
// 4) Instruction field map (tentative; adjust to match original ISA)
//    Example (MIPS-like for convenience):
//      [31:26] opcode
//      [25:21] rd (or rs1)
//      [20:16] rs  (or rs2)
//      [15:11] rt  (or rd2 / func-hi)
//      [15:0 ] imm16
//----------------------------------------------------------------------
`define OPCODE_W        6
`define OPCODE_RNG      31:26
`define RD_RNG          25:21
`define RS_RNG          20:16
`define RT_RNG          15:11
`define IMM16_RNG       15:0

// Sign/Zero extend helpers for immediate
`define SXT16(x)        {{(`XLEN-16){(x)[15]}}, (x)[15:0]}
`define ZXT16(x)        {{(`XLEN-16){1'b0}},   (x)[15:0]}

//----------------------------------------------------------------------
// 5) Top-level opcodes (symbolic placeholders)
//    These are safe defaults; update values to match the original code.
//    Keep them unique to avoid decode ambiguities.
//----------------------------------------------------------------------
`define OP_ADD          6'h00   // ADD rd, rs, rt
`define OP_SUB          6'h01   // SUB rd, rs, rt
`define OP_NEG          6'h02   // NEG rd, rs
`define OP_AND          6'h03
`define OP_OR           6'h04
`define OP_XOR          6'h05

`define OP_LDR          6'h10   // LDR rd, [rs + imm]
`define OP_STR          6'h11   // STR rs, [rd + imm]

`define OP_BR           6'h20   // BR  target (register/cond-style as per ISA)
`define OP_BRL          6'h21   // BRL target, link
`define OP_J            6'h22   // J   imm/abs
`define OP_JL           6'h23   // JL  imm/abs, link

`define OP_NOP          6'h3F   // NOP (reserved)

//----------------------------------------------------------------------
// 6) Branch / jump type (internal control mux)
//----------------------------------------------------------------------
`define BR_NONE         3'd0
`define BR_BR           3'd1
`define BR_BRL          3'd2
`define BR_J            3'd3
`define BR_JL           3'd4

//----------------------------------------------------------------------
// 7) Load/store width (if used by MEM unit)
//----------------------------------------------------------------------
`define LSU_WB          2'd0    // word/XLEN
`define LSU_HB          2'd1    // half
`define LSU_BB          2'd2    // byte

//----------------------------------------------------------------------
// 8) Utility macros (simulation only)
//----------------------------------------------------------------------
`ifdef SIM
  `define ASSERT(cond, msg) \
    if (!(cond)) begin \
      $display("[%0t] ASSERTION FAILED: %s", $time, msg); \
      $stop; \
    end
`else
  `define ASSERT(cond, msg)
`endif

//----------------------------------------------------------------------
// 9) Default register indices (conventions, if needed)
//    Adjust if your design reserves specific registers for link/zero.
//----------------------------------------------------------------------
`define REG_ZERO        5'd0    // hard-wired zero if implemented
`define REG_LINK        5'd31   // link register candidate (JL/BRL)

//======================================================================
`endif // __DEFS_VH__