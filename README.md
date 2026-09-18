# Verilog / SystemVerilog Design Exercises

A collection of independent RTL design and verification exercises in Verilog and SystemVerilog. Each file is self-contained (its own module(s), and in most cases its own testbench) and can be simulated on its own.

## Contents

| File | Module(s) | Description |
|---|---|---|
| [`Risc-v_.v`](#risc-v_v--single-cycle-rv32i-core) | `RISCV_Top` + 9 sub-modules, `tb_top` | Single-cycle RV32I RISC-V CPU core with a self-checking testbench |
| [`Ram.v`](#ramv--single-port-ram) | `single_port_ram` | Synchronous single-port RAM |
| [`STA.v`](#stav--static-timing-analysis-circuit) | `sta_circuit` | Small clocked circuit with explicit delay annotations, for static timing analysis practice |
| [`paritygen.v`](#paritygenv--parity-generator) | `parity_generator` | Combinational 8-bit even/odd parity generator |
| [`trafficligt.v`](#trafficligtv--traffic-light-controller) | `traffic_light_simple` | FSM-style traffic light controller |
| [`Systemverilog.sv`](#systemverilogsv--systemverilog-algorithm-exercises) | `tb_sv` | SystemVerilog array-algorithm exercises (partition, max consecutive ones, second maximum) |

---

## `Risc-v_.v` — Single-Cycle RV32I Core

A single-cycle RISC-V CPU implementing the RV32I base integer instruction set, built from separate, individually-instantiated modules and wired together in a top-level `RISCV_Top`.

**Sub-modules:**
- `ALU_unit` — 32-bit ALU (AND, OR, ADD, XOR, SLL, SRL, SUB, SRA, SLT, SLTU, NOR) with a `zero` flag
- `ALU_Control` — decodes `ALUOp` + `funct3`/`funct7` into the 4-bit ALU control code
- `Control_Unit` — main decoder; generates `Branch`, `MemRead`, `MemToReg`, `MemWrite`, `ALUSrc`, `RegWrite`, `ALUOp` from the opcode (covers R-, I-, S-, B-, U-, and J-type opcodes)
- `ImmGen` — sign-extends and assembles immediates for I/S/B/U/J instruction formats
- `I_mem` — instruction memory (32×32-bit), preloaded in an `initial` block with a 5-instruction test program (`addi`, `addi`, `add`, `sw`, `lw`)
- `Data_Memory` — 32×32-bit data memory with synchronous write / combinational read
- `Reg_File` — 32×32-bit register file; `x0` is hardwired to read as zero and protected from writes
- `Mux1`, `AND_logic`, `Adder` — small combinational helpers used for the PC and ALU-source muxing/branch logic
- `RISCV_Top` — connects the fetch → decode → execute → memory → writeback datapath

**Testbench (`tb_top`):** drives `clk`/`rst`, runs the core for 100 ns after reset, then dumps registers `x1`–`x4` and self-checks them against the expected results of the preloaded test program (`x1=5, x2=10, x3=15, x4=15`), printing `SUCCESS` or `ERROR`.

**Scope / limitations:** single-cycle (no pipelining or hazards), RV32I base ISA only (no M/F extensions), no interrupt/exception handling, memory is small (32 words) and only word-addressed.

---

## `Ram.v` — Single-Port RAM

`single_port_ram`: an 8-bit-wide synchronous RAM with a single read/write port.

- **Ports:** `clk`, `we` (write enable), `addr` (4-bit), `din` (8-bit), `dout` (8-bit, registered)
- **Behavior:** on each rising clock edge, writes `din` to `ram[addr]` when `we` is high, and always registers `ram[addr]` onto `dout` (read-first behavior)

**Note:** `addr` is declared as 4 bits (16 possible addresses) but the memory array is only sized `0:(1<<3)` (8 words). Addresses 8–15 will index out of the declared range — worth widening the array to `0:15` (or narrowing `addr` to 3 bits) before relying on the full address space.

---

## `STA.v` — Static Timing Analysis Circuit

`sta_circuit`: a minimal two-flip-flop pipeline with explicit gate/net delays, intended as a worked example for static timing analysis (STA) exercises rather than a functional design block.

- **Ports:** `clk`, `in_1`, `in_2` → `out_1`, `out_2`
- `ff1` captures `in_1` with a `#2.0` delay; `ff2` registers `ff1` with a `#2.0` delay
- `out_1` is `ff2` delayed by `#2.4`; `out_2` is a direct, `#1.0`-delayed combinational path from `in_2`
- The annotated delays make this convenient for hand-calculating (or tool-checking) setup/hold and path delay numbers across the two clocked stages and the one combinational path.

---

## `paritygen.v` — Parity Generator

`parity_generator`: purely combinational 8-bit parity generator.

- **Ports:** `data_in` (8-bit) → `even_parity`, `odd_parity`
- `even_parity` is the XOR-reduction of `data_in`; `odd_parity` is its complement
- No clock or state — a single `assign`-based module, useful as a building block in a larger UART/communication design or as a standalone parity checker.

---

## `trafficligt.v` — Traffic Light Controller

`traffic_light_simple`: a synchronous FSM that cycles a 3-bit `lights` output through RED → GREEN → YELLOW → RED using a free-running counter.

- **Ports:** `clk`, `rst_n` (active-low reset) → `lights` (`3'b100`=RED, `3'b010`=YELLOW, `3'b001`=GREEN)
- Durations are counter-based: GREEN holds for 10 cycles, YELLOW for 3 cycles, RED for 12 cycles (counts reset to 0 on each transition)
- On reset, the light is forced to RED and the counter cleared; an unreachable `default` case also forces RED as a safety fallback.

---

## `Systemverilog.sv` — SystemVerilog Algorithm Exercises

`tb_sv`: not a hardware design — a SystemVerilog module used to practice array-manipulation algorithms with dynamic arrays and `automatic` functions.

- `partition(ref int a[])` — Lomuto-scheme quicksort partition step; reorders `a` around the last element as pivot and returns the pivot's final index
- `max_consecutive_ones(int a[])` — returns the length of the longest run of `1`s in `a`
- `find_second_max(int a[])` — returns the second-largest distinct value in `a`

The module declares no stimulus (`initial` block) of its own — it's meant to be driven from a separate test harness that calls these functions with sample arrays.

---

## Simulating

Each file can be compiled and run independently with a standard open-source simulator, e.g. [Icarus Verilog](http://iverilog.icarus.com/):

```bash
# RTL + self-checking testbench in one file
iverilog -o sim Risc-v_.v && vvp sim

# SystemVerilog file (needs -g2012 for SV constructs)
iverilog -g2012 -o sim Systemverilog.sv && vvp sim
```

`Ram.v`, `STA.v`, `paritygen.v`, and `trafficligt.v` contain only the design module (no testbench) — instantiate them in a small harness, or use a waveform viewer (e.g. GTKWave with `$dumpfile`/`$dumpvars`) to exercise them interactively.
