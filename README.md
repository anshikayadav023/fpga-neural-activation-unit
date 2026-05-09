# FPGA Neural Activation Unit

> Pipelined fixed-point (Q8.8) activation function hardware for neural network inference on FPGA.

Synthesizable Verilog RTL implementations of common neural network activation functions — optimized for low-latency, resource-efficient inference on FPGA targets.

---

## Features

- **Q8.8 Fixed-Point Arithmetic** — 16-bit signed representation (8 integer + 8 fractional bits) balancing precision and area
- **Pipelined Design** — deterministic latency with full throughput (1 result/cycle after pipeline fill)
- **LUT-Based Sigmoid** — 256-entry synchronous ROM with symmetry exploitation, halving storage
- **Saturation Arithmetic** — overflow-safe computations across all modules
- **Modular Architecture** — each activation is a standalone module with standard `valid`-based handshaking

---

## Supported Activations

| Activation | Latency (cycles) | Type | Description |
|:----------:|:-----------------:|:----:|:------------|
| **ReLU** | 0 | Combinational | `y = max(0, x)` — sign-bit gating |
| **Sigmoid** | 2 | Pipelined | `y = σ(x)` — LUT + symmetry fixup |
| **Tanh** | 3 | Pipelined | `y = tanh(x) = 2σ(2x) − 1` — reuses sigmoid |
| **Swish** | 3 | Pipelined | `y = x · σ(x)` — sigmoid + fixed-point multiply |

---

## Architecture

### Sigmoid Pipeline

```
         ┌──────────────────────────────────────────────────────┐
         │                  Sigmoid Module                      │
         │                                                      │
  x ────►│  |x|, sign ──► LUT addr ──► ROM read ──► symmetry  ──►  y
         │   (Stage 0)      (comb)     (Stage 1)    (Stage 1)   │
         └──────────────────────────────────────────────────────┘
                    Latency: 2 clock cycles
```

- **Stage 0** — Compute absolute value, extract sign, generate 8-bit LUT address, detect saturation.
- **Stage 1** — Synchronous ROM read + symmetry correction (`σ(−x) = 1 − σ(x)`).

### Tanh Pipeline (reuses Sigmoid)

```
  x ──► 2x (saturate) ──► Sigmoid(2x) ──► 2·σ(2x) − 1 ──► y
          (Stage 0)        (2 cycles)       (Stage 2)
                    Latency: 3 clock cycles
```

### Swish Pipeline

```
  x ──► Sigmoid(x) ──────────────────┐
  │      (2 cycles)                   ▼
  └──► delay x by 2 cycles ──► x × σ(x) ──► y
                               (multiplier)
                    Latency: 3 clock cycles
```

### ReLU (Combinational)

```
  x ──► sign bit check ──► 0 or x ──► y
              Latency: 0 cycles (pure combinational)
```

---

## 📁 Project Structure

```
fpga-neural-activation-unit/
├── README.md
├── LICENSE
├── .gitignore
│
├── rtl/                        # Synthesizable RTL source
│   ├── relu.v                  # ReLU — combinational max(0, x)
│   ├── sigmoid.v               # Sigmoid — 2-stage pipelined LUT
│   ├── sigmoid_lut.v           # Synchronous ROM (256 × 16-bit)
│   ├── tanh_act.v              # Tanh — via 2·sigmoid(2x) − 1
│   ├── swish.v                 # Swish — x · sigmoid(x)
│   └── fixed_point_mult.v      # Q8.8 signed fixed-point multiplier
│
├── lut/                        # Look-up table data
│   └── sigmoid_lut.hex         # 256-entry sigmoid ROM (Q8.8, $readmemh)
│
├── tb/                         # Testbenches (simulation)
│   └── ...
│
└── docs/                       # Documentation & diagrams
    └── architecture.md
```

---

## Fixed-Point Format: Q8.8

All data paths use **Q8.8 signed fixed-point**:

```
  Bit 15       Bits [14:8]        Bits [7:0]
 ┌──────┐   ┌──────────────┐   ┌──────────────┐
 │ Sign │   │ Integer (7b) │   │ Fraction (8b)│
 └──────┘   └──────────────┘   └──────────────┘
```

### Synthesis

All modules are fully synthesizable. To target an FPGA:

1. Add all files under `rtl/` to your project
2. Ensure `sigmoid_lut.hex` is accessible in the synthesis working directory (or update the `$readmemh` path)
3. Set top-level module to the desired activation function
4. Constrain clock and I/O as needed

---

## Sigmoid LUT Details

The sigmoid lookup table stores `σ(x)` for `x ∈ [0, 8.0)` in 256 entries:

| Parameter | Value |
|:----------|:------|
| Depth | 256 entries |
| Width | 16 bits (Q8.8 unsigned) |
| Address mapping | `addr = floor(x × 32)` |
| Coverage | x ∈ [0.0, 7.96875] |
| Saturation | x ≥ 5.5 → σ(x) ≈ 1.0 |

Negative inputs are handled via the **symmetry property**: `σ(−x) = 1 − σ(x)`, so only the positive half is stored — effectively halving the ROM requirement.

---

## Design Decisions

- **LUT over CORDIC** — For 8-bit fractional precision, a 256-entry LUT is more area-efficient and lower-latency than iterative CORDIC
- **Sigmoid reuse in Tanh** — The identity `tanh(x) = 2σ(2x) − 1` avoids a separate tanh LUT entirely
- **Saturation arithmetic** — All intermediate computations use sign-extended accumulators with explicit clamping to prevent wraparound
- **Valid-signal handshaking** — Simple `in_valid` / `out_valid` protocol enables straightforward integration into larger pipelines


---

<p align="center">
  <i>Designed for efficient neural network inference at the hardware level.</i>
</p>
