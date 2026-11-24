# RV32I Single-Cycle Processor (Verilog)

This repository contains a modular, educational 32-bit RISC-V processor implemented in Verilog. The top-level `riscv_single_cycle` fetches and completes one instruction per clock cycle through a combinational datapath. It is intended for simulation and learning, not as a production core.

## Architecture

- **Program counter and instruction memory:** byte-addressed PC, word-wide instructions, asynchronous instruction reads, optional `$readmemh` initialization, and NOP (`ADDI x0,x0,0`) reads for uninitialized or out-of-range locations.
- **Control and immediate generation:** opcode/funct-based control for the supported instruction families and I, S, B, U, and J immediates.
- **Register file:** 32 x 32-bit registers, two asynchronous read ports, one synchronous write port, synchronous reset, and hardwired `x0` reads/writes.
- **Execution:** 32-bit ALU with a shared ripple-carry adder (built from 8-bit adders and full/half adders), logical operations, signed/unsigned comparisons, and a mux-based barrel shifter.
- **Branching and jumps:** conditional branches, JAL, and JALR. JALR clears target bit 0. Link instructions write `PC+4` to `rd`.
- **Data memory:** parameterized byte array, little-endian byte/halfword/word stores and signed/unsigned loads. Reads are combinational; writes occur on the rising clock edge.

## Instruction coverage

The decoder provides the RV32I base integer operations represented by the implemented control paths:

- R-type: `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`.
- Immediate ALU: `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI`.
- Loads: `LB`, `LH`, `LW`, `LBU`, `LHU`.
- Stores: `SB`, `SH`, `SW`.
- Control flow: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`, `JAL`, `JALR`.
- Upper immediates: `LUI`, `AUIPC`.

The top-level defaults are 256 instruction words and 4096 data-memory bytes. These can be changed with `IMEM_WORDS`, `DMEM_BYTES`, and `IMEM_INIT_FILE` parameters.

## Limits and assumptions

- This is a single-cycle, non-pipelined educational core. There is no cache, bus protocol, privilege mode, CSR support, interrupt handling, exception/trap mechanism, or extension support (such as M, C, or F).
- Illegal instruction encodings are not reported as traps. Some opcode/funct combinations outside the documented set may follow decoder defaults; software should use only the listed encodings.
- Misaligned and out-of-range data accesses do not raise exceptions. Out-of-range accesses are ignored on writes and return zero on reads. The data memory is little-endian and byte-addressed; accesses are not required to be naturally aligned.
- Instruction memory is word indexed using `PC[31:2]`, so instruction fetch ignores the low two address bits. There is no alignment exception.
- Memories are simulation-oriented arrays. The data memory starts at zero; register contents become defined when reset is asserted. Reset is synchronous and active high.
- The core has no built-in program loader or runtime I/O. Initialize instruction memory with `IMEM_INIT_FILE` or load its `mem` array from a testbench.
- The source uses Verilog constructs suitable for common simulation flows; no synthesis, timing, or FPGA/ASIC implementation claim is made.

## Source layout

- `primary_units/`: processor, control, ALU, memories, register file, branch comparator, and immediate generator.
- `helper_units/`: adders, mux, and barrel shifter.
- `testbench/`: unit and integration simulation benches, including a control-unit bench matched to the current module interface.

Compile the required helper and primary modules together with the selected testbench in your Verilog simulator. The repository does not include a simulator-specific build script.
