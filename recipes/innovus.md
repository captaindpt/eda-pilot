# Innovus

Cadence Innovus is the place-and-route tool in the digital flow. This repo uses it after synthesis to turn a mapped gate-level netlist into routed layout artifacts and signoff-style reports.

## Setup

Start from the Cadence bash wrapper:

```bash
source setup/cadence.sh
```

The validated batch flow calls the Innovus binary by absolute path:

```bash
INNOVUS_BIN=/CMC/tools/cadence/INNOVUS21.17.000_lnx86/tools.lnx86/bin/innovus
```

Do not assume `innovus` is on `PATH` after sourcing `setup/cadence.sh`; the wrapper exposes IC23 and Spectre, but not Innovus.

Cross-reference: `environment/cadence-tools.md`

## Required Inputs

Environment variables used by the flow:

- `REPO_DIR` - repo root, used by the TCL script to locate all inputs/outputs
- `DC_TARGET_LIB` - timing library, default: `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib`
- `GPDK045_TECH_LEF` - technology LEF
- `GPDK045_MACRO_LEF` - standard-cell macro LEF
- `GPDK045_QRC` - QRC tech file for RC corner creation
- `GPDK045_STD_GDS` - reference GDS merged during `streamOut`

The default GPDK045 settings are:

```bash
export DC_TARGET_LIB=/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib
export GPDK045_TECH_LEF=/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/lef/gsclib045_tech.lef
export GPDK045_MACRO_LEF=/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/lef/gsclib045_macro.lef
export GPDK045_QRC=/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/qrc/qx/gpdk045.tch
export GPDK045_STD_GDS=/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/gds/gsclib045.gds
```

Netlist dependency:

- Innovus expects a synthesized mapped netlist first.
- In a typical run that file is `<run_dir>/dc/out/<top>_mapped.v`.
- It is produced by the synthesis stage or by `flows/run_digital_flow.sh`.

Other required inputs:

- constraints: `examples/alu4/alu4.sdc`
- top-level RTL source for synthesis provenance: `examples/alu4/alu4.v`

## Invocation

Example command:

```bash
export REPO_DIR=$PWD
source setup/cadence.sh
/CMC/tools/cadence/INNOVUS21.17.000_lnx86/tools.lnx86/bin/innovus \
  -no_gui -overwrite \
  -files innovus_pnr.tcl
```

Flags used by the batch flow:

- `-no_gui` - headless batch execution
- `-overwrite` - reuse the working directory without interactive prompts
- `-files <script.tcl>` - load the PnR TCL script

The wrapper should save `innovus.log` and assert that the routed DEF exists before continuing.

## TCL Flow Structure

The smoke script is small but complete:

1. Define `TOP`, `REPO_DIR`, `WORK_DIR`, netlist path, and SDC path.
2. Resolve library, LEF, QRC, and GDS inputs from environment variables or GPDK045 defaults.
3. Generate `mmmc.tcl` with `create_library_set`, `create_rc_corner`, `create_delay_corner`, `create_constraint_mode`, and `create_analysis_view`.
4. Set `init_verilog`, `init_lef_file`, `init_mmmc_file`, top cell, and power/ground nets.
5. Run `init_design`.
6. Apply global power/ground connections with `globalNetConnect`.
7. Floorplan with `floorPlan -site CoreSite -r 1.0 0.70 10 10 10 10`.
8. Place and route with `placeDesign` then `routeDesign`.
9. Emit reports with `report_area`, `report_timing`, and `report_power`.
10. Export layout/netlist with `defOut`, `saveNetlist`, and `streamOut`.

Note on command naming:

- This smoke script loads design data through `init_verilog`, `init_lef_file`, and `init_mmmc_file` before `init_design`.
- Some Innovus flows use explicit `read_verilog` / `read_libs` commands instead; conceptually it is the same stage.
- The minimal batch flow does not run CTS explicitly.

## Outputs

Expected outputs under `<run_dir>/innovus/`:

- `innovus.log`
- `mmmc.tcl`
- `reports/<top>_area.rpt`
- `reports/<top>_timing.rpt`
- `reports/<top>_power.rpt`
- `out/<top>.def`
- `out/<top>_postroute.v`
- `out/<top>.gds`

The runner treats the DEF as mandatory. GDS is best-effort: the script catches `streamOut` failure and writes a warning file instead of hard-failing.

## Gotchas

- Run synthesis first. Without `work/dc/out/<top>_mapped.v`, Innovus exits before initialization.
- `REPO_DIR` must be exported in the shell; the TCL script exits immediately if it is missing.
- Keep the GPDK045 LEF, timing lib, QRC, and GDS files aligned. Mixing kits will produce invalid tech setup.
- `streamOut` can warn on GDS unit mismatches. Review the log and keep the merge GDS settings aligned.
- This is a smoke flow, not a full production backend flow. It demonstrates initialization, floorplan, place, route, reports, DEF, and GDS export, but omits explicit CTS and signoff closure work.
