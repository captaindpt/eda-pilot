# RTL To GDS Flow

This is the repo's master digital implementation pattern: verify RTL, synthesize to GPDK045 standard cells, place and route, extract parasitics, sign off timing, run physical verification, and keep the final GDS plus reports.

## Overview

```text
rtl/<top>.v + constraints/<top>.sdc + optional tb/tb_<top>.v
    |
    v
Xcelium RTL sim
    |
    v
DC or Genus synthesis
    |
    v
mapped netlist + output SDC
    |
    v
Innovus place and route
    |
    +--> post-route netlist ------+
    |                             |
    +--> DEF --> Quantus --> SPEF |
    |                             v
    +--> GDS ----------------> PrimeTime
    |                             |
    +--> optional gate sim -------+
    |
    v
Pegasus DRC/LVS
    |
    v
signoff package / GDS
```

## Stage Contract

### 1. RTL and constraints
Inputs:
- `rtl/<top>.v`
- `constraints/<top>.sdc`
- optional `tb/tb_<top>.v`

This stage establishes the top module name, timing intent, and optional functional testbench. Xcelium consumes the RTL and testbench. Synthesis consumes the RTL and SDC.

### 2. Pre-synthesis simulation
Tool: Xcelium
Inputs:
- RTL
- testbench

Outputs:
- `xrun.log`
- optional `waves.shm/`

This does not feed synthesis directly, but it is the first functional gate before spending runtime on backend tools.

Cross-reference: `recipes/xcelium.md`

### 3. Synthesis
Tools:
- Path A: Design Compiler
- Path B: Genus

Inputs:
- RTL
- SDC
- GPDK045 Liberty timing library

Outputs:
- mapped gate netlist
- synthesis reports
- output SDC

Innovus consumes the mapped netlist and constraints. Design Compiler is the default proven path; Genus is a working local alternative.

Cross-reference: `recipes/design-compiler.md`, `recipes/genus.md`

### 4. Place and route
Tool: Innovus
Inputs:
- mapped netlist
- SDC
- GPDK045 tech LEF
- GPDK045 macro LEF
- GPDK045 QRC tech file
- GPDK045 merge GDS

Outputs:
- routed DEF
- post-route netlist
- area/timing/power reports
- GDS

These outputs split the flow: Quantus reads DEF, PrimeTime reads the post-route netlist plus constraints, Pegasus reads GDS, and Xcelium can re-simulate the mapped or post-route netlist.

Cross-reference: `recipes/innovus.md`, `environment/gpdk045.md`

### 5. Parasitic extraction
Tool: Quantus
Inputs:
- routed DEF
- LEF
- QRC tech file

Output:
- SPEF

PrimeTime consumes the SPEF with `read_parasitics`.

Current repo gap:
- the checked-in `alu4` run does not include a Quantus step or saved SPEF
- Innovus did run `extractRC`, but the demo TCL stops before exporting parasitics

Cross-reference: `recipes/quantus.md`, `recipes/primetime.md`

### 6. Timing signoff
Tool: PrimeTime
Inputs:
- post-route netlist
- SDC
- Liberty timing library
- optional SPEF

Outputs:
- setup report
- hold report
- constraint-violation report

Without SPEF, PrimeTime still runs, but it is not full extracted post-route signoff.

Cross-reference: `recipes/primetime.md`

### 7. Post-route simulation
Tool: Xcelium
Inputs:
- mapped or post-route netlist
- testbench
- standard-cell simulation models
- optional SDF timing back-annotation

Outputs:
- gate-level simulation log
- optional waveforms

Current repo state:
- mapped and post-route Verilog netlists exist
- no checked-in SDF export stage exists yet
- treat timing-annotated gate simulation as a future extension, not a proven baseline step

### 8. Physical verification
Tool: Pegasus
Inputs:
- GDS
- DRC rule deck
- optional LVS rule deck and source netlist

Outputs:
- DRC report/database
- optional LVS comparison report

For the current digital flow, DRC is the immediate must-have proof point.

Cross-reference: `recipes/pegasus.md`

## File Naming Convention

Keep one top name across every stage.

- RTL: `rtl/<top>.v`
- constraints: `constraints/<top>.sdc`
- testbench: `tb/tb_<top>.v`
- synthesis: `work/dc/out/<top>_mapped.v`, `work/dc/out/<top>.sdc`
- P&R: `work/innovus/out/<top>.def`, `work/innovus/out/<top>_postroute.v`, `work/innovus/out/<top>.gds`
- extraction: `work/quantus/out/<top>.spef`
- PrimeTime: `work/primetime/reports/<top>_setup.rpt`, `work/primetime/reports/<top>_hold.rpt`, `work/primetime/reports/<top>_constraints.rpt`
- Pegasus: `work/pegasus/<top>_drc.log`, `work/pegasus/<top>_lvs.log`

## Two Synthesis Paths

Design Compiler is the default first-run path because the validated `alu4` flow already proves `DC -> Innovus`. Genus is the Cadence-native alternative and has been smoke-tested locally, but it is not yet the main full-flow baseline. For the first runner bring-up, prefer DC and add Genus later as a selectable backend.

## Concrete Example: alu4
The checked-in `alu4` example already proves these handoffs:

- RTL: `examples/alu4/alu4.v`
- SDC: `examples/alu4/alu4.sdc`
- DC mapped netlist: `<run_dir>/dc/out/alu4_mapped.v`
- DC output SDC: `<run_dir>/dc/out/alu4.sdc`
- Innovus post-route netlist: `<run_dir>/innovus/out/alu4_postroute.v`
- Innovus GDS: `<run_dir>/innovus/out/alu4.gds`

What the current repo does not yet prove:

- saved SPEF handoff
- PrimeTime report outputs checked into the flow
- Pegasus run outputs checked into the flow
- timing-annotated gate-level simulation

## Pre-Tapeout Checklist

1. RTL simulation passes with a self-checking testbench.
2. Synthesis emits a mapped netlist with no unresolved references.
3. The backend uses the intended SDC and GPDK045 library corner.
4. Innovus emits DEF, post-route netlist, reports, and GDS.
5. Quantus emits SPEF, or the lack of extraction is explicitly recorded.
6. PrimeTime meets setup and hold at the target corner/frequency.
7. Gate-level or post-route simulation preserves functionality.
8. Pegasus DRC is clean or every remaining violation is intentionally waived.
9. LVS is clean, or the reason it is deferred is explicitly recorded.
10. The final package preserves the exact reports, logs, GDS, and tool versions used.

This pattern is the contract that `flows/run_digital_flow.sh` should implement.
