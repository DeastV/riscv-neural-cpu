# Spike CPU Architecture and RISC-V Neural Network Classifier

[![Language](https://img.shields.io/badge/Language-RISC--V%20Assembly-brown.svg)](https://riscv.org/)
[![Tool](https://img.shields.io/badge/Tool-Logisim--evolution-blue.svg)](https://github.com/logisim-evolution/logisim-evolution)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Computer architecture project implementing an 8-bit single-cycle processor architecture in Logisim-evolution alongside a 2-layer feedforward neural network image classifier written in RISC-V assembly.

Developed as part of the **Introdução à Arquitetura de Computadores (IAC)** curriculum at **Instituto Superior Técnico (IST), Universidade de Lisboa**.

---

## Overview

The repository is structured into two core systems:

1. **8-Bit Spike Processor (`cpu/`)**:
   - A single-cycle 8-bit microarchitecture built in Logisim-evolution.
   - Custom instruction set architecture (ISA) with variable-length opcode encoding (2-bit and 3-bit) designed to maximize immediate operand resolution within an 8-bit word.
   - Hardware-level implementation of Instruction Fetch (IF), Instruction Decode (ID), Execution (EX), and Write-Back (WB) stages.

2. **RISC-V Assembly Linear Algebra & Neural Classifier (`assembly/`)**:
   - Fundamental mathematical and tensor kernels (`abs`, `relu`, `argmax`).
   - Matrix multiplication (`matmul`) and contiguous vector dot product (`dotproduct`).
   - File I/O system calls for loading binary neural network weights and input vectors.
   - Complete 2-layer forward propagation pipeline classifying 28x28 digit images into 10 target classes (MNIST classification).

---

## 8-Bit Spike CPU Architecture

### Instruction Set Architecture (ISA)

The Spike processor uses an 8-bit instruction format designed to balance immediate precision and operation coverage:

| Instruction | Type | Opcode | Immediate / Operands | Semantics |
| :--- | :--- | :--- | :--- | :--- |
| `addi` | Immediate Arithmetic | `00` (2 bits) | `imm` (6 bits) | $R_1 \leftarrow R_1 + \text{ext}_{8}(imm)$ |
| `subi` | Immediate Arithmetic | `01` (2 bits) | `imm` (6 bits) | $R_1 \leftarrow R_1 - \text{ext}_{8}(imm)$ |
| `li`   | Immediate Load       | `11` (2 bits) | `imm` (6 bits) | $R_1 \leftarrow \text{ext}_{8}(imm)$ |
| `relu` | Unary Non-linear     | `100` (3 bits)| None (5 bits don't-care) | $R_1 \leftarrow \max(0, R_1)$ |
| `abs`  | Unary Non-linear     | `101` (3 bits)| None (5 bits don't-care) | $R_1 \leftarrow \|R_1\|$ |

### Control Unit Signals

| Operation | ALU Control Signal | Description |
| :--- | :--- | :--- |
| `addi` | `00` | Addition with 6-bit sign-extended immediate |
| `subi` | `01` | Subtraction with 6-bit sign-extended immediate |
| `li` | `11` | Immediate pass-through to write-back stage |
| `relu` | `100` | Rectified linear unit activation |
| `abs` | `101` | Two's complement absolute value |

### Microarchitecture Datapath

```text
+-------------+      +----------------+      +---------------+      +----------------+
|  Fetch (IF) | ---> |   Decode (ID)  | ---> |  Execute (EX) | ---> | Write-Back(WB) |
| PC, Addr+1, |      | Splitters,     |      | Extender, ALU,|      | MUX,           |
| Program ROM |      | MUX Control    |      | Sub, Negator  |      | Register R1    |
+-------------+      +----------------+      +---------------+      +----------------+
```

- **Instruction Fetch (IF):** Program Counter (`PC`) register increments sequentially via an 8-bit adder, addressing instruction ROM.
- **Instruction Decode (ID):** Bit splitters isolate the most significant bits for the opcode and the lowest 6 bits for immediates. Control logic drives downstream datapath multiplexers.
- **Execute (EX):** Features a 6-to-8 bit extender, an 8-bit ripple adder/subtractor, and conditional 2's complement negation logic for `abs` and `relu`.
- **Write-Back (WB):** A multiplexer routes the final calculated value back into register $R_1$.

Detailed architectural notes and design tradeoffs are available in [`cpu/docs/isa-specification.md`](cpu/docs/isa-specification.md).

---

## RISC-V Neural Network Classifier

The assembly pipeline implements full forward propagation for a multi-layer perceptron (MLP) trained to classify handwritten digit representations.

### Network Architecture and Mathematics

$$\begin{aligned}
\mathbf{h} &= \text{ReLU}(\mathbf{M_0} \times \mathbf{x}) && \quad \mathbf{M_0} \in \mathbb{Z}^{128 \times 784}, \; \mathbf{x} \in \mathbb{Z}^{784 \times 1} \implies \mathbf{h} \in \mathbb{Z}^{128 \times 1} \\
\mathbf{o} &= \mathbf{M_1} \times \mathbf{h} && \quad \mathbf{M_1} \in \mathbb{Z}^{10 \times 128}, \; \mathbf{h} \in \mathbb{Z}^{128 \times 1} \implies \mathbf{o} \in \mathbb{Z}^{10 \times 1} \\
\text{prediction} &= \text{argmax}(\mathbf{o}) && \quad \text{prediction} \in \{0, 1, \dots, 9\}
\end{aligned}$$

### Assembly Modules

| Module | Location | Description |
| :--- | :--- | :--- |
| `abs.s` | `assembly/kernels/` | Computes in-place absolute value of a signed integer in memory. |
| `relu.s` | `assembly/kernels/` | In-place vector ReLU activation; zeroes out negative elements in memory arrays. |
| `argmax.s` | `assembly/kernels/` | Scans a 1D vector and returns the index of the highest integer element. |
| `dotproduct.s` | `assembly/nn-classifier/` | Computes inner product between two contiguous integer arrays with element-wise accumulation. |
| `matmul.s` | `assembly/nn-classifier/` | 2D integer matrix multiplication with dimension compatibility checking and row-major memory traversal. |
| `readfiles.s` | `assembly/nn-classifier/` | File descriptor management and binary buffer ingestion via RISC-V system calls (`open`, `read`, `close`). |
| `classify.s` | `assembly/nn-classifier/` | End-to-end classifier orchestrating file ingestion, dynamic stack frame preservation, hidden layer activation, and argmax prediction. |

### Error Codes and Exception Handling

The RISC-V routines enforce strict parameter validation and terminate via syscall `exit2` with specific status codes:
- **Code 36:** Empty or invalid vector length in `relu` (length < 1).
- **Code 37:** Empty or invalid vector length in `argmax` (length < 1).
- **Code 38:** Invalid vector length in `dotproduct` (length < 1).
- **Code 39:** Non-positive matrix dimension in `matmul` (rows or columns < 1).
- **Code 40:** Incompatible matrix dimensions in `matmul` (columns of A ≠ rows of B).
- **Code 41:** File opening failure or invalid file descriptor in `readfiles`.
- **Code 42:** Invalid read byte length (< 1) in `readfiles`.

---

## Repository Structure

```text
riscv-neural-cpu/
├── cpu/
│   ├── Processador_8bit_Spike_T16.circ   # Logisim-evolution CPU circuit schematic
│   └── docs/
│       └── isa-specification.md          # Formatted ISA & datapath documentation
├── assembly/
│   ├── kernels/                          # Core mathematical subroutines
│   │   ├── abs.s                         # Absolute value routine
│   │   ├── argmax.s                      # Vector argmax routine
│   │   └── relu.s                        # In-place ReLU routine
│   └── nn-classifier/                    # Neural network inference pipeline
│       ├── classify.s                    # Main 2-layer classifier orchestration
│       ├── dotproduct.s                  # Strided dot product kernel
│       ├── matmul.s                      # Matrix multiplication kernel
│       └── readfiles.s                   # Binary file reader via syscalls
├── .gitignore
├── LICENSE                               # MIT License
└── README.md
```

---

## Running and Simulation

### Simulating the 8-Bit Spike Processor

The circuit was designed for [Logisim-evolution](https://github.com/logisim-evolution/logisim-evolution) (v3.8+ / v3.9+):

1. Launch Logisim-evolution:
   ```bash
   logisim-evolution cpu/Processador_8bit_Spike_T16.circ
   ```
2. In the explorer panel, navigate to `Processador8bitSpike`.
3. Enable simulation ticks via **Simulate** -> **Ticks Enabled** (or `Ctrl + K`).
4. Step through instructions manually using `Ctrl + T` to observe register and multiplexer state changes across stages.

### Simulating RISC-V Assembly

The RISC-V assembly files target the RV32I base integer instruction set and can be executed using [RARS](https://github.com/TheThirdOne/rars) or [Venus](https://github.com/61c-teach/venus):

1. **Running a Kernel (e.g., Matrix Multiplication):**
   ```bash
   java -jar rars.jar sm nc assembly/nn-classifier/matmul.s
   ```
2. **Running the Full Classifier:**
   Place model weight matrices (`m0.bin`, `m1.bin`) and input vector (`input.bin`) in the working directory:
   ```bash
   java -jar rars.jar sm nc assembly/nn-classifier/classify.s
   ```

---

## Known Limitations

* **Contiguous Vector Alignment:** Vector dot product routines operate on contiguous word arrays; strided column lookups require explicit row-major indexing during matrix multiplication.
* **Monolithic classify.s Pipeline:** `classify.s` inlines arithmetic kernels directly to minimize simulator stack frame overhead during end-to-end forward propagation runs.

---

## Credits

* **David Vasques** ([@DeastV](https://github.com/DeastV)), **Guilherme Marques** ([@marques-jpg](https://github.com/marques-jpg))
* Collaborative group coursework developed for Introdução à Arquitetura de Computadores (IAC) at Instituto Superior Técnico, Universidade de Lisboa. Architecture specifications, simulator harnesses (RARS, Logisim-evolution), and benchmarks provided by the teaching staff.
