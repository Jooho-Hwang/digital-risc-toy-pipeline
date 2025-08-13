//======================================================================
// File    : risc_toy_core.v
// Purpose : Minimal 5-stage pipelined toy RISC CPU (skeleton)
// Project : digital_risc_toy_pipeline
// Author  : Jooho Hwang
// License : MIT
//----------------------------------------------------------------------
// Notes
// - This is a minimal, compile-oriented skeleton to organize the code.
// - Focus: structure of IF/ID/EX/MEM/WB, basic decode/ALU placeholders.
// - No full hazard/forwarding/CSR/exception handling yet.
// - Branch/jump and LSU paths are intentionally simplified.
// - Adjust instruction field mapping in defs.vh to match the original ISA.
//======================================================================

`include "defs.vh"

module RISC_TOY_CORE #(
  parameter string IMEM_INIT = "prog_basic.mem", // simulation program image
  parameter string DMEM_INIT = ""                // optional data init
)(
  input  wire                  clk,
  input  wire                  rst_n,

  // (Optional) simple visibility for TB
  output wire [`ADDR_W-1:0]    dbg_pc,
  output wire [`XLEN-1:0]      dbg_reg_x1
);

  // ------------------------------------------------------------
  // Local parameters / types
  // ------------------------------------------------------------
  localparam XLEN = `XLEN;

  // ------------------------------------------------------------
  // Register file
  // ------------------------------------------------------------
  wire                  rf_we_wb;
  wire [`REG_ADDR_W-1:0]rf_waddr_wb;
  wire [`XLEN-1:0]      rf_wdata_wb;

  wire [`REG_ADDR_W-1:0]rs1_id;
  wire [`REG_ADDR_W-1:0]rs2_id;
  wire [`REG_ADDR_W-1:0]rd_id;

  wire [`XLEN-1:0]      rs1_val_id;
  wire [`XLEN-1:0]      rs2_val_id;

  rtl_regfile u_regfile (
    .clk    (clk),
    .rst_n  (rst_n),
    .we     (rf_we_wb),
    .waddr  (rf_waddr_wb),
    .wdata  (rf_wdata_wb),
    .raddr_a(rs1_id),
    .rdata_a(rs1_val_id),
    .raddr_b(rs2_id),
    .rdata_b(rs2_val_id),
    .dbg_x1 (dbg_reg_x1)
  );

  // ------------------------------------------------------------
  // Memories: separate IMEM/DMEM (simple, sim-oriented)
  // ------------------------------------------------------------
  wire [`ADDR_W-1:0] pc_if;
  wire [31:0]        instr_if;

  rtl_sram #(
    .ADDR_W (`MEM_ADDR_W),
    .DATA_W (32),
    .INIT_HEX(IMEM_INIT)
  ) u_imem (
    .clk   (clk),
    .rst_n (rst_n),
    .ce    (1'b1),
    .we    (1'b0),
    .addr  (pc_if[`MEM_ADDR_W+1:2]), // word aligned
    .wdata (32'h0),
    .rdata (instr_if)
  );

  // Data memory
  reg                 dmem_ce_mem;
  reg                 dmem_we_mem;
  reg  [`MEM_ADDR_W-1:0] dmem_addr_mem;
  reg  [`XLEN-1:0]    dmem_wdata_mem;
  wire [`XLEN-1:0]    dmem_rdata_mem;

  rtl_sram #(
    .ADDR_W (`MEM_ADDR_W),
    .DATA_W (`XLEN),
    .INIT_HEX(DMEM_INIT)
  ) u_dmem (
    .clk   (clk),
    .rst_n (rst_n),
    .ce    (dmem_ce_mem),
    .we    (dmem_we_mem),
    .addr  (dmem_addr_mem),
    .wdata (dmem_wdata_mem),
    .rdata (dmem_rdata_mem)
  );

  // ------------------------------------------------------------
  // IF stage
  // ------------------------------------------------------------
  reg  [`ADDR_W-1:0] pc_r;
  wire [`ADDR_W-1:0] pc_next;

  // Very simple next PC logic (no stall/flush yet)
  assign pc_next = pc_r + 32'd4;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc_r <= {`ADDR_W{1'b0}};
    end else begin
      pc_r <= pc_next;
    end
  end

  assign pc_if  = pc_r;
  assign dbg_pc = pc_r;

  // IF/ID pipeline regs
  reg  [31:0]        ifid_instr;
  reg  [`ADDR_W-1:0] ifid_pc;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ifid_instr <= 32'h0000_0000;
      ifid_pc    <= {`ADDR_W{1'b0}};
    end else begin
      ifid_instr <= instr_if;
      ifid_pc    <= pc_if;
    end
  end

  // ------------------------------------------------------------
  // ID stage (very light decode for skeleton)
  // Field slices defined in defs.vh; adapt to your ISA
  wire [5:0] opcode_id   = ifid_instr[`OPCODE_RNG];
  assign rd_id           = ifid_instr[`RD_RNG];
  assign rs1_id          = ifid_instr[`RS_RNG];
  assign rs2_id          = ifid_instr[`RT_RNG];

  wire [`XLEN-1:0] imm_sx_id = `SXT16(ifid_instr[`IMM16_RNG]);

  // Decode to ALU op (minimal subset)
  reg [4:0]  alu_op_id;
  reg        uses_imm_id;
  reg        is_load_id, is_store_id;
  reg        wb_en_id;
  reg [2:0]  br_type_id;

  always @* begin
    alu_op_id   = `ALU_ADD;
    uses_imm_id = 1'b0;
    is_load_id  = 1'b0;
    is_store_id = 1'b0;
    wb_en_id    = 1'b0;
    br_type_id  = `BR_NONE;

    unique case (opcode_id)
      `OP_ADD: begin alu_op_id = `ALU_ADD; wb_en_id = 1'b1; end
      `OP_SUB: begin alu_op_id = `ALU_SUB; wb_en_id = 1'b1; end
      `OP_NEG: begin alu_op_id = `ALU_NEG; wb_en_id = 1'b1; end
      `OP_LDR: begin is_load_id  = 1'b1; uses_imm_id = 1'b1; wb_en_id = 1'b1; end
      `OP_STR: begin is_store_id = 1'b1; uses_imm_id = 1'b1; wb_en_id = 1'b0; end
      `OP_BR : begin br_type_id  = `BR_BR;  end
      `OP_BRL: begin br_type_id  = `BR_BRL; end
      `OP_J  : begin br_type_id  = `BR_J;   end
      `OP_JL : begin br_type_id  = `BR_JL;  wb_en_id = 1'b1; end
      default: begin /* NOP */ end
    endcase
  end

  // ID/EX pipeline regs
  reg [4:0]          idex_alu_op;
  reg                idex_uses_imm, idex_is_load, idex_is_store, idex_wb_en;
  reg [2:0]          idex_br_type;
  reg [`XLEN-1:0]    idex_rs1_val, idex_rs2_val, idex_imm;
  reg [`REG_ADDR_W-1:0] idex_rd;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      idex_alu_op    <= `ALU_ADD;
      idex_uses_imm  <= 1'b0;
      idex_is_load   <= 1'b0;
      idex_is_store  <= 1'b0;
      idex_wb_en     <= 1'b0;
      idex_br_type   <= `BR_NONE;
      idex_rs1_val   <= {`XLEN{1'b0}};
      idex_rs2_val   <= {`XLEN{1'b0}};
      idex_imm       <= {`XLEN{1'b0}};
      idex_rd        <= {`REG_ADDR_W{1'b0}};
    end else begin
      idex_alu_op    <= alu_op_id;
      idex_uses_imm  <= uses_imm_id;
      idex_is_load   <= is_load_id;
      idex_is_store  <= is_store_id;
      idex_wb_en     <= wb_en_id;
      idex_br_type   <= br_type_id;
      idex_rs1_val   <= rs1_val_id;
      idex_rs2_val   <= rs2_val_id;
      idex_imm       <= imm_sx_id;
      idex_rd        <= rd_id;
    end
  end

  // ------------------------------------------------------------
  // EX stage (tiny ALU)
  // ------------------------------------------------------------
  reg [`XLEN-1:0] alu_b_ex;
  always @* begin
    alu_b_ex = idex_uses_imm ? idex_imm : idex_rs2_val;
  end

  reg [`XLEN-1:0] alu_y_ex;
  always @* begin
    unique case (idex_alu_op)
      `ALU_ADD: alu_y_ex = idex_rs1_val + alu_b_ex;
      `ALU_SUB: alu_y_ex = idex_rs1_val - alu_b_ex;
      `ALU_NEG: alu_y_ex = -idex_rs1_val;
      `ALU_AND: alu_y_ex = idex_rs1_val & alu_b_ex;
      `ALU_OR : alu_y_ex = idex_rs1_val | alu_b_ex;
      `ALU_XOR: alu_y_ex = idex_rs1_val ^ alu_b_ex;
      default : alu_y_ex = idex_rs1_val + alu_b_ex;
    endcase
  end

  // Branch target (very simplified: PC+imm)
  wire [`ADDR_W-1:0] br_target_ex = ifid_pc + idex_imm; // NOTE: crude

  // EX/MEM regs
  reg                exmem_is_load, exmem_is_store, exmem_wb_en;
  reg [`XLEN-1:0]    exmem_alu_y, exmem_rs2_val;
  reg [`REG_ADDR_W-1:0] exmem_rd;
  reg [`ADDR_W-1:0]  exmem_br_tgt;
  reg [2:0]          exmem_br_type;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      exmem_is_load <= 1'b0;
      exmem_is_store<= 1'b0;
      exmem_wb_en   <= 1'b0;
      exmem_alu_y   <= {`XLEN{1'b0}};
      exmem_rs2_val <= {`XLEN{1'b0}};
      exmem_rd      <= {`REG_ADDR_W{1'b0}};
      exmem_br_tgt  <= {`ADDR_W{1'b0}};
      exmem_br_type <= `BR_NONE;
    end else begin
      exmem_is_load <= idex_is_load;
      exmem_is_store<= idex_is_store;
      exmem_wb_en   <= idex_wb_en;
      exmem_alu_y   <= alu_y_ex;
      exmem_rs2_val <= idex_rs2_val;
      exmem_rd      <= idex_rd;
      exmem_br_tgt  <= br_target_ex;
      exmem_br_type <= idex_br_type;
    end
  end

  // ------------------------------------------------------------
  // MEM stage
  // ------------------------------------------------------------
  always @* begin
    dmem_ce_mem    = exmem_is_load | exmem_is_store;
    dmem_we_mem    = exmem_is_store;
    dmem_addr_mem  = exmem_alu_y[`MEM_ADDR_W+1:2]; // word address
    dmem_wdata_mem = exmem_rs2_val;
  end

  reg [`XLEN-1:0] mem_data_r; // registered load data (1-cycle SRAM)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) mem_data_r <= {`XLEN{1'b0}};
    else        mem_data_r <= dmem_rdata_mem;
  end

  // Branch commit (NOTE: no flush/stall here; placeholder)
  // In a real pipeline, this must produce PC redirect and flush IF/ID/ID/EX.
  // For now we keep pc_next = pc + 4 to remain side-effect free.

  // MEM/WB regs
  reg                memwb_wb_en;
  reg [`REG_ADDR_W-1:0] memwb_rd;
  reg [`XLEN-1:0]    memwb_wdata;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      memwb_wb_en  <= 1'b0;
      memwb_rd     <= {`REG_ADDR_W{1'b0}};
      memwb_wdata  <= {`XLEN{1'b0}};
    end else begin
      memwb_wb_en  <= exmem_wb_en;
      memwb_rd     <= exmem_rd;
      memwb_wdata  <= exmem_is_load ? mem_data_r : exmem_alu_y;
    end
  end

  // ------------------------------------------------------------
  // WB stage
  // ------------------------------------------------------------
  assign rf_we_wb     = memwb_wb_en;
  assign rf_waddr_wb  = memwb_rd;
  assign rf_wdata_wb  = memwb_wdata;

endmodule