```
# 5-Stage Pipelined RISC-V Processor with Hazard Unit & RVC Extension

A modular, synthesizable 5-stage pipelined processor core implementing the **RV32I** base integer instruction set and the **RVC (Compressed Instructions)** extension in Verilog. The core incorporates a dedicated **Hazard Unit** capable of full data forwarding (3:1 multiplexing), load-use stall insertion via synchronous register clears, and pipeline flushing on taken branches and jumps.

---

## Key Microarchitectural Features

- **Classic 5-Stage Pipeline:** Fetch (`F`), Decode (`D`), Execute (`E`), Memory (`M`), and Writeback (`W`) separated by pipeline registers (`FD`, `DE`, `EM`, `MW`).
- **Comprehensive Hazard Handling:**
  - **Data Forwarding (RAW Resolution):** Dual 3:1 forwarding multiplexers feeding ALU inputs (`ForwardAE`, `ForwardBE`) resolving Memory $\to$ Execute and Writeback $\to$ Execute hazards without stalling. Includes store-data forwarding (`SrcBEfwd`) into the `EM` stage register for back-to-back operations.
  - **Half-Cycle RegFile Access:** Dual-phase register file access (write on `negedge clk`, read during high phase) to inherently resolve Writeback $\to$ Decode data dependencies within tight loops.
  - **Load-Use Interlocking:** Early stall detection in Decode (`ResultSrcE[0] & (Rs1D == RdE || Rs2D == RdE)`). Freezes PC (`StallF`) and Decode (`StallD`) while injecting a synchronous bubble into Execute (`FlushE`).
  - **Control Hazard Mitigation:** Synchronous flushing (`FlushD`, `FlushE`) triggered by branch mispredictions and jump redirection (`PCSrcE`).
- **RISC-V Compressed Extension (RVC):**
  - **Hardware Decompressor:** Single-cycle combinational expansion translating 16-bit compressed encodings to equivalent 32-bit standard formats prior to the Decode stage.
  - **Variable PC Incrementer:** Dynamic step update (`+2` for compressed instructions, `+4` for standard 32-bit instructions).
  - **Half-Word Aligned Fetch Subsystem (`imem`):** Capable of fetching across 2-byte boundaries by reading consecutive memory words and dynamically selecting the active window based on `a[1]`.
  - **Zero Clock-Cycle Penalty:** Decompression operates purely combinational, retaining 100% of pipeline throughput while shrinking code footprint by **30.4%**.

---

## Pipeline Architecture


```

```
   +-------+      +--------+      +---------+      +--------+      +-----------+
   | Fetch | ---> | Decode | ---> | Execute | ---> | Memory | ---> | Writeback |
   +-------+      +--------+      +---------+      +--------+      +-----------+
       ^              |                |                |                |
       |          +-------+            |                |                |
       +----------|  PC   |            |                |                |
       |          | Logic |            |                |                |
       |          +-------+            |                |                |
       |              ^                |                |                |
       |              +----------------+                |                |
       |                      Branch Target / PCSrcE    |                |
       |                                                |                |
       +================== HAZARD UNIT =================+================+
             - Forwarding (EX-EX, MEM-EX, WB-EX, MEM Store)
             - Load-Use Interlocking (StallF, StallD, FlushE)
             - Branch Flush (FlushD, FlushE)

```

```

---

## Supported Instruction Set

### RV32I Base Integer ISA
| Type | Instructions |
| :--- | :--- |
| **R-Type** | `add`, `sub`, `and`, `or`, `xor`, `sll`, `srl`, `sra` |
| **I-Type** | `lw`, `addi`, `andi`, `ori`, `xori`, `slli`, `srli`, `srai`, `jalr` |
| **S-Type** | `sw` |
| **B-Type** | `beq`, `bne`, `blt`, `bge` |
| **U-Type** | `lui` |
| **J-Type** | `jal` |

### RVC Extension (20 Instructions)
| Category | Supported Instructions |
| :--- | :--- |
| **Integer Arithmetic & Logic** | `c.addi`, `c.add`, `c.sub`, `c.and`, `c.or`, `c.xor`, `c.li` |
| **Shifts & Immediates** | `c.slli`, `c.srli`, `c.srai`, `c.lui` |
| **Memory Operations** | `c.lw`, `c.sw`, `c.lwsp`, `c.swsp` |
| **Control Flow & Jumps** | `c.beqz`, `c.bnez`, `c.j`, `c.jal`, `c.jr`, `c.jalr` |

*Note: Compressed 3-bit register mappings (`rd'`, `rs1'`, `rs2'`) are translated to physical registers `x8`--`x15` (`01xxx`).*

---

## Hardware Modules & Verification Suite

### Module Hierarchy
- `riscvsingle.v`: Top-level structural wrapper integrating datapath, control unit, decompressor, and hazard unit.
- `controller.v`: Main decoder (`maindec.v`), ALU decoder (`aludec.v`), and branch evaluation logic based on `funct3` conditions.
- `datapath.v`: 5-stage register pipeline, ALU, branch target computation, and operand routing.
- `hazard.v`: Centralized interlocking, hazard detection, forwarding multiplexer selectors, and stall/flush generator.
- `decompressor.v`: Combinational 16-bit to 32-bit instruction translation unit.
- `imem.v`: Byte/half-word aligned instruction memory unit supporting non-aligned 32-bit accesses.
- `dmem.v`: Synchronous data memory.
- `flopenr.v` / `flopenrc.v`: Specialized pipeline registers parameterized with synchronous clear and clock-enable ports.

---

## Benchmarks & Experimental Validation

### Benchmark: In-Place Bubble Sort Algorithm
The microarchitecture was validated against an in-place Bubble Sort routine sorting an arbitrary four-element vector `[4, 1, 3, 2]` into `[1, 2, 3, 4]`. The algorithm exercises nested loops, backward conditional branches, internal branch redirects, and interleaved memory read/write accesses.


```

Initial Vector:   mem[0]=4 | mem[4]=1 | mem[8]=3 | mem[12]=2
Final State:      mem[0]=1 | mem[4]=2 | mem[8]=3 | mem[12]=4  [VERIFIED]

```

### RV32I vs. RVC Performance Comparison

| Metric | Base RV32I | Compressed RVC | Efficiency Gain |
| :--- | :---: | :---: | :---: |
| **Dynamic Instruction Count** | 23 | 23 | Identical |
| **Compressed (16-bit) Count** | 0 | 14 | 60.9% of total stream |
| **Standard (32-bit) Count** | 23 | 9 | - |
| **Code Binary Footprint** | **92 bytes** | **64 bytes** | **-30.4% (-28 bytes)** |
| **Execution Latency (Cycles)** | $N$ cycles | $N$ cycles | **0 cycle overhead** |

Because instruction decompression is entirely combinational between the `Fetch` and `Decode` boundaries, code density improves by **30.4%** without inflating critical path cycles or incurring pipeline stalls.

---

## Hazard Verification Case Studies

1. **Back-to-Back RAW Dependencies (Test 2):**
   - Arithmetic register forwarding verified (`ForwardAE`, `ForwardBE`) on consecutive `addi` and dependent `add` operations without stalling execution.
2. **Load-Use Data Hazards (Test 3):**
   - Verified that a `lw` followed immediately by a dependent arithmetic consumer halts the pipeline for exactly 1 cycle (`StallF=1`, `StallD=1`, `FlushE=1`), preserving pipeline synchronization.
3. **Control Hazards on Taken Branches (Test 4):**
   - Evaluated `bge` branch paths. Synchronous flushes (`FlushD=1`, `FlushE=1`) clear erroneous speculative instructions from the pipeline before state commit, preventing register corruption.

---

## Simulation Setup

### Prerequisites
- ModelSim, QuestaSim, or Icarus Verilog (`iverilog`)
- GTKWave (for waveform visualization)

### Running Simulation (Icarus Verilog Example)
```bash
# Clone the repository
git clone [https://github.com/yoryilv/proyecto-arch.git](https://github.com/yoryilv/proyecto-arch.git)
cd proyecto-arch

# Compile testbench and hardware sources
iverilog -o riscv_pipeline_tb tb_top.v riscvsingle.v datapath.v controller.v hazard.v decompressor.v alu.v regfile.v imem.v dmem.v flopenr.v flopenrc.v

# Execute simulation
vvp riscv_pipeline_tb

# Open generated waveform
gtkwave dump.vcd

```

---
*Course: Computer Architecture (CS3051) —(UTEC).*

```
