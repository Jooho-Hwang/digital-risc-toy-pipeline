# Digital RISC Toy (5-Stage)

A simple 32-bit **RISC toy CPU** implemented in Verilog HDL, organized as a **5-stage pipeline** (IF → ID → EX → MEM → WB) with minimal hazard and branch handling.  
Designed for educational purposes and simulation. The project follows a clean directory structure and coding convention for maintainability.

> **Note:** This version focuses on structural clarity and compilation.  
> Hazard, forwarding, and control logic are minimal placeholders and can be extended in future iterations.

## Overview

- **Architecture:** Classic 5-stage pipeline (Instruction Fetch, Decode, Execute, Memory, Writeback)
- **Datapath Width:** 32 bits
- **Registers:** 32 general-purpose registers (x0 hard-wired to zero)
- **Memories:** Separate instruction and data SRAM models (`rtl_sram`)
- **Instruction Set:** Minimal subset for ALU, load/store, and branch/jump (placeholders for unsupported ops)
- **Reset:** Active-low asynchronous reset, synchronous release
- **Clocking:** Single-clock synchronous design
- **Testbench:** Minimal simulation harness with program memory preload

## Architecture

![Block Diagram](docs/block%20diagram.png)

**Pipeline Stages:**
1. **IF – Instruction Fetch**  
   - Fetches 32-bit instruction from Instruction Memory (IMEM) using the Program Counter (PC).
   - PC increments by 4 each cycle (no branch delay handling yet).
   
2. **ID – Instruction Decode / Control**  
   - Decodes opcode, register addresses, and immediate fields.
   - Reads register operands from `rtl_regfile`.
   - Generates control signals for ALU, memory, and writeback.

3. **EX – Execute**  
   - Performs arithmetic/logic operations in ALU.
   - Computes branch target addresses (placeholder logic).

4. **MEM – Memory Access**  
   - Accesses Data Memory (DMEM) for load/store instructions.
   - Data memory is modeled with `rtl_sram` (synchronous, 1-cycle read latency).

5. **WB – Writeback**  
   - Writes results back into the Register File.

**Pipeline Registers:**  
- IF/ID, ID/EX, EX/MEM, MEM/WB are implemented as separate register groups inside the core for clarity.

**Supporting Modules:**  
- `rtl_regfile`: Dual read, single write register file with x0 hard-wired to zero.  
- `rtl_sram`: Generic synchronous SRAM model, hex-file preload for simulation.  
- **Hazard / Stall Unit**: Placeholder for future data/control hazard handling.  
- **Branch / Jump Unit**: Placeholder for future branch prediction/target resolution.

## Directory Structure

```bash
digital_risc_toy_pipeline/
├─ README.md 
├─ LICENSE # MIT License
├─ src/
│ ├─ defs.vh # Global parameters, enums, opcodes
│ ├─ risc_toy_core.v # Top-level CPU core (5-stage pipeline)
│ ├─ rtl_regfile.v # Register file (2R1W, x0=0)
│ └─ rtl_sram.v # Simple synchronous RAM model
├─ sim/
│ ├─ tb_risc_toy_core.v # Minimal testbench harness
│ └─ prog_basic.mem # Example program memory image (NOPs & sample ALU ops)
└─ docs/
└─ block_diagram.png # Block diagram of the pipeline
```

## How to Build & Run

Example using **Icarus Verilog**:

```bash
cd sim

# Compile
iverilog -g2012 -DSIM -o tb \
  ../src/rtl_sram.v \
  ../src/rtl_regfile.v \
  ../src/risc_toy_core.v \
  tb_risc_toy_core.v

# Run (optional plusargs: IMEM image, max cycles)
vvp tb +IMEM=prog_basic.mem +MAX=200

# View waveform (optional)
gtkwave tb_risc_toy_core.vcd
Example using Verilator:

verilator -Wall --cc --exe --build \
  -DSIM tb_risc_toy_core.v \
  ../src/risc_toy_core.v \
  ../src/rtl_regfile.v \
  ../src/rtl_sram.v
```

## How to Test

Default Program:
- The testbench loads sim/prog_basic.mem into instruction memory.
- The default program is mostly NOPs with a few ALU ops for path verification.

Custom Program:
- Encode your instructions in 32-bit hex format, one word per line.
- Save as your_prog.mem in the sim/ directory.

Run:

```bash
vvp tb +IMEM=your_prog.mem +MAX=500
```

Waveform Analysis:
- Open tb_risc_toy_core.vcd in GTKWave to inspect PC, register file, and pipeline registers.

## Lessons Learned

Structure First: Establishing a clean repository layout and common definitions (defs.vh) early simplifies later refactoring.
Separation of Concerns: Isolating the register file, memory, and core logic modules improves readability and maintainability.
Simulation-Driven Development: Having a minimal testbench and preloadable program memory makes iteration faster, even without synthesis.
Progressive Enhancement: Starting with a functional skeleton allows step-by-step addition of hazard handling, branch logic, and more complex ISA features.