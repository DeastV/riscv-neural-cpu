# 8-Bit Spike CPU: ISA and Architecture Specification

This document details the instruction set architecture (ISA), datapath stages, and control signals for the 8-bit single-cycle **Spike CPU**, designed in Logisim-evolution.

---

## Instruction Set Architecture (ISA)

The processor utilizes an 8-bit instruction word with variable-length opcode encoding to maximize immediate value ranges within a single byte.

### 1. Format: `li`, `addi`, `subi`

Used for arithmetic and constant loading with an immediate operand:

```text
+--------+------------------+
| Opcode |  Immediate (imm) |
| [7:6]  |       [5:0]      |
+--------+------------------+
  2 bits          6 bits
```

- **Immediate Range:** 6-bit sign-extended or zero-extended depending on instruction semantics.
- **Opcode [7:6]:**
  - `00`: `addi R1, imm` -> $R_1 \leftarrow R_1 + \text{ext}(imm)$
  - `01`: `subi R1, imm` -> $R_1 \leftarrow R_1 - \text{ext}(imm)$
  - `11`: `li R1, imm` -> $R_1 \leftarrow \text{ext}(imm)$

### 2. Format: `abs`, `relu`

Used for unary non-linear operations on register $R_1$:

```text
+---------------+------------------+
|    Opcode     |    Don't Care    |
|     [7:5]     |      [4:0]       |
+---------------+------------------+
     3 bits            5 bits
```

- **Opcode [7:5]:**
  - `100`: `relu R1` -> $R_1 \leftarrow \max(0, R_1)$
  - `101`: `abs R1` -> $R_1 \leftarrow |R_1|$
- By using 3 bits for operations that do not require an immediate field, 5 distinct operations are supported without increasing instruction width beyond 8 bits.

---

## Control Unit and ALU Signals

| Instruction | Opcode `[7:6]` / `[7:5]` | ALU Control Signal | Description |
| :--- | :--- | :--- | :--- |
| `addi` | `00` | `00` | Addition with 6-bit immediate |
| `subi` | `01` | `01` | Subtraction with 6-bit immediate |
| `li` | `11` | `11` | Load 6-bit immediate directly into $R_1$ |
| `relu` | `100` | `100` | Rectified Linear Unit ($\max(0, R_1)$) |
| `abs` | `101` | `101` | Absolute value ($|R_1|$) |

---

## Datapath Stages (Single-Cycle)

The CPU operates as a single-cycle machine without pipeline registers to minimize hardware footprint and register count.

1. **Instruction Fetch (IF):**
   - **Components:** Program Counter register (`PC`), increment adder (+1), instruction `ROM`.
   - **Function:** Reads the 8-bit instruction located at the address indicated by `PC`.

2. **Instruction Decode (ID):**
   - **Components:** Splitters, multiplexers.
   - **Function:** Separates opcode bits (`[7:6]` / `[7:5]`) and operand bits (`[5:0]`). Directs control signals to the datapath multiplexers.

3. **Execution (EX):**
   - **Components:** Bit extender (6-to-8 bits), 8-bit adder, 8-bit subtractor, 2 multiplexers, 2's complement negator.
   - **Function:**
     - Immediate value is extended to 8 bits.
     - Adder and subtractor perform arithmetic between $R_1$ and the extended immediate.
     - For `abs`, the negator inverts negative numbers; a MUX selects between the original value and negated value based on the sign bit.
     - For `relu`, a MUX selects 0 if the sign bit indicates a negative value, or the original value if positive.

4. **Write-Back (WB):**
   - **Components:** Multiplexer and destination register (`R1`).
   - **Function:** Selects the computed result (from adder, subtractor, immediate, `abs`, or `relu`) and updates register `R1` on the clock edge.

---

## Architectural Highlights

1. **Multiplexer-Driven Datapath:** Reuses functional units and minimizes redundant hardware components.
2. **Control-Data Decoupling:** Clean modular distinction between control logic routing and arithmetic execution.
3. **Optimized Instruction Encoding:** Variable 2/3-bit opcodes allow a 6-bit immediate in an 8-bit word while supporting 5 distinct machine operations.
