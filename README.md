# DSP48A1 Behavioral Model

A parameterizable Verilog behavioral model of the Xilinx **DSP48A1** arithmetic slice: an 18-bit pre-adder/subtractor, an 18×18 multiplier, and a 48-bit post-adder/subtractor with configurable pipeline registers, synchronous/asynchronous resets, and carry-in/out handling.

The design is verified with a directed self-checking testbench in QuestaSim, and taken through synthesis and implementation in Vivado for an Artix-7 device.

| | |
|---|---|
| **Top module** | `DSP` |
| **Target part** | `xc7a200tffg1156-3` |
| **Clock** | 100 MHz (10 ns period), pin `W5` |
| **Simulation** | QuestaSim |
| **Synthesis / Implementation** | Vivado 2018.2 |
| **Linting** | Questa Lint |

---

## Features

- Pre-adder/subtractor on `D` and `B` (`D ± B`), bypassable via `OPMODE[4]`
- 18×18 signed multiplier producing a 36-bit result `M`
- 48-bit post-adder/subtractor with `X` and `Z` operand multiplexers and carry-in
- Every input, intermediate, and output stage can be registered or bypassed through parameters
- Per-register clock enable (`CE*`) and reset (`RST*`)
- Selectable reset style: synchronous or asynchronous (`RSTTYPE`)
- Cascade support: `BCIN`/`BCOUT` for the B path, `PCIN`/`PCOUT` for the P path

## Architecture

```
        D ─►[D reg]──┐
                     ├─► pre-adder/sub ─► mux(OPMODE[4]) ─►[B1 reg]─┐
 B ─►[B0 reg]────────┘                                    │         │
                                                       BCOUT        ├─► 18×18 multiplier ─►[M reg]─► M
 A ─►[A0 reg]─►[A1 reg]─────────────────────────────────────────────┘          │
                                                                               ▼
 C ─►[C reg]─► Z mux ──┐                                                 X mux (OPMODE[1:0])
 PCIN, P ──────────────┤                                                       │
                       └──────────► post-adder/subtractor ◄────────────────────┘
                                         ▲            │
                          CIN ─►[CYI reg]┘            ├─► [P reg] ─► P, PCOUT
                                                      └─► [CARRYOUT reg] ─► CARRYOUT, CARRYOUTF
```

> Replace the sketch above with your elaborated schematic from Vivado (`docs/elaborated_schematic.png`) if you prefer.

## Repository Structure

```
├── rtl/
│   ├── DSP.v            # Top-level DSP48A1 model
│   └── pip_mux.v        # Configurable register/bypass stage
├── tb/
│   └── DSP_tb.v         # Directed self-checking testbench
├── sim/
│   └── run.do           # QuestaSim run script
├── constraints/
│   └── DSP.xdc          # Clock constraint and pin assignment
├── docs/                # Report and screenshots
└── README.md
```

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `A0REG` | 0 | Register the first A stage (1) or bypass (0) |
| `A1REG` | 1 | Register the second A stage |
| `B0REG` | 0 | Register the first B stage |
| `B1REG` | 1 | Register the second B stage |
| `CREG` | 1 | Register input C |
| `DREG` | 1 | Register input D |
| `MREG` | 1 | Register the multiplier output |
| `PREG` | 1 | Register the post-adder output |
| `CARRYINREG` | 1 | Register the carry-in |
| `CARRYOUTREG` | 1 | Register the carry-out |
| `OPMODEREG` | 1 | OPMODE register option |
| `B_INPUT` | `"DIRECT"` | B source: `"DIRECT"` uses `B`, `"CASCADE"` uses `BCIN` |
| `CARRYINSEL` | `"OPMODE5"` | Carry-in source: `"OPMODE5"` uses `OPMODE[5]`, `"CARRYIN"` uses the `CARRYIN` port |
| `RSTTYPE` | `"SYNC"` | `"SYNC"` or `"ASYNC"` reset |

## Ports

| Port | Dir | Width | Description |
|---|---|---|---|
| `CLK` | in | 1 | Clock |
| `A`, `B`, `D` | in | 18 | Data inputs |
| `C` | in | 48 | Post-adder input |
| `BCIN` | in | 18 | B cascade input |
| `PCIN` | in | 1* | P cascade input |
| `CARRYIN` | in | 1 | External carry-in |
| `OPMODE` | in | 8 | Operation mode (see below) |
| `RSTA`, `RSTB`, `RSTM`, `RSTP`, `RSTC`, `RSTD`, `RSTCARRYIN`, `RSTOPMODE` | in | 1 each | Resets |
| `CEA`, `CEB`, `CEM`, `CEP`, `CEC`, `CED`, `CECARRYIN`, `CEOPMODE` | in | 1 each | Clock enables |
| `BCOUT` | out | 18 | B cascade output |
| `PCOUT` | out | 48 | P cascade output |
| `P` | out | 48 | Post-adder result |
| `M` | out | 36 | Multiplier result |
| `CARRYOUT`, `CARRYOUTF` | out | 1 each | Carry out of the post-adder |

\* Width as declared in the current RTL.

## OPMODE

| Bit(s) | Function |
|---|---|
| `OPMODE[1:0]` | X mux select |
| `OPMODE[3:2]` | Z mux select |
| `OPMODE[4]` | Pre-adder: `1` = use `D ± B`, `0` = bypass (use B) |
| `OPMODE[5]` | Carry-in when `CARRYINSEL = "OPMODE5"` |
| `OPMODE[6]` | Pre-adder operation: `0` = `D + B`, `1` = `D − B` |
| `OPMODE[7]` | Post-adder operation: `0` = `Z + X + CIN`, `1` = `Z − X − CIN` |

X and Z mux encodings (per the DSP48A1 datasheet):

| `OPMODE[1:0]` | X | | `OPMODE[3:2]` | Z |
|---|---|---|---|---|
| `00` | 0 | | `00` | 0 |
| `01` | `M` | | `01` | `PCIN` |
| `10` | `P` | | `10` | `P` |
| `11` | `D:A:B` concatenation | | `11` | `C` |

## Verification

The testbench (`tb/DSP_tb.v`) first checks that asserting all resets drives every output to zero, then applies four directed test paths and checks `BCOUT`, `M`, `P`, `PCOUT`, `CARRYOUT`, and `CARRYOUTF` against expected values. The simulation stops with an error message on the first mismatch.

| Path | OPMODE | Checked outputs |
|---|---|---|
| 1 | `8'b11011101` | `BCOUT = 0xF`, `M = 0x12C`, `P = PCOUT = 0x32`, `CARRYOUT = 0` |
| 2 | `8'b00010000` | `BCOUT = 0x23`, `M = 0x2BC`, `P = PCOUT = 0`, `CARRYOUT = 0` |
| 3 | `8'b00001010` | `BCOUT = 0xA`, `M = 0xC8`, `P = PCOUT = 0`, `CARRYOUT = 0` |
| 4 | `8'b10100111` | `BCOUT = 0x6`, `M = 0x1E`, `P = PCOUT = 0xFE6FFFEC0BB1`, `CARRYOUT = 1` |

Result: **all four paths pass** (`Path 1 … Path 4 succeded` in the QuestaSim transcript).

### Run the simulation

```
cd sim
vsim -do run.do
```

`run.do`:

```tcl
vlib work
vmap work work
vlog -work work pip_mux.v
vlog -work work DSP.v
vlog -work work DSP_tb.v
vsim -voptargs=+acc work.DSP_tb
add wave -r sim:/DSP_tb/DUT/*
run -all
```

## Synthesis and Implementation (Vivado)

Constraints (`constraints/DSP.xdc`):

```tcl
create_clock -period 10.000 -name CLK -waveform {0.000 5.000} [get_ports CLK]
set_property PACKAGE_PIN W5 [get_ports CLK]
set_property IOSTANDARD LVCMOS33 [get_ports CLK]
```

### Utilization (post-implementation)

| Resource | Used |
|---|---|
| Slice LUTs | 228 |
| Slice Registers | 136 |
| Slices | 79 |
| DSP48E1 | 1 |
| Bonded IOB | 325 |
| BUFGCTRL | 1 |

### Timing (100 MHz, all constraints met)

| Metric | Synthesis | Implementation |
|---|---|---|
| Worst Negative Slack (setup) | 5.344 ns | 3.750 ns |
| Worst Hold Slack | 0.341 ns | 0.437 ns |
| Worst Pulse Width Slack | 4.500 ns | 4.500 ns |
| Failing endpoints | 0 | 0 |

With 3.750 ns of setup slack at a 10 ns period, the design has room to run at roughly 160 MHz (estimate, not constrained or verified).

## Linting

Questa Lint reports a **100 % quality score**. The remaining items are informational style notes (`line_char_large`, `multi_ports_in_single_line`).

## Screenshots

| | |
|---|---|
| Simulation waveform | `docs/waveform.png` |
| Transcript (4 paths passed) | `docs/transcript.png` |
| Elaborated schematic | `docs/elaboration.png` |
| Synthesized schematic | `docs/synthesis.png` |
| Implemented device view | `docs/implementation.png` |
| Lint summary | `docs/lint.png` |

## Author

**Omar Gamal Mohamed Hammad**
Electronics and Communication Engineering, Faculty of Engineering, Beni-Suef University
