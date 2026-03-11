# Design Compiler

Synopsys Design Compiler (DC) synthesizes RTL into a mapped gate-level netlist. In this repo it is the default Synopsys front end for the `alu4` example and for larger GPDK045 digital designs.

## Setup

CMC provides a tcsh launcher:

```bash
tcsh -c 'source /CMC/scripts/synopsys.syn.2024.09-SP2.csh && which dc_shell'
```

Key environment facts from the machine:

- setup script: `/CMC/scripts/synopsys.syn.2024.09-SP2.csh`
- install root: `/CMC/tools/synopsys/syn_vW-2024.09-SP2/syn/W-2024.09-SP2`
- binaries: `dc_shell`, `dc_shell-t`, `dc_shell-xg-t`
- license server: `SNPSLMD_LICENSE_FILE=6053@licaccess.cmc.ca`

The CMC script adds the DC `bin/` directories to `PATH`. If you need an explicit binary path, use:

```bash
/CMC/tools/synopsys/syn_vW-2024.09-SP2/syn/W-2024.09-SP2/bin/dc_shell
```

## Invocation

Headless batch form:

```bash
tcsh -c 'source /CMC/scripts/synopsys.syn.2024.09-SP2.csh && \
  setenv SNPSLMD_LICENSE_FILE 6053@licaccess.cmc.ca && \
  setenv REPO_DIR /path/to/repo && \
  dc_shell -f flow_dc.tcl'
```

The flow is TCL-driven. `REPO_DIR` is commonly used to resolve RTL, constraints, and output paths from a single repo root.

## TCL Flow

The repo runner writes a DC script automatically when you call `flows/run_digital_flow.sh`.

Flow shape:

1. Set `TOP`, `REPO_DIR`, `WORK_DIR`, RTL path, and SDC path.
2. Resolve the target library from `DC_TARGET_LIB` or fall back to GPDK045.
3. Create work directories:
   - `work/dc/work`
   - `work/dc/reports`
   - `work/dc/out`
4. Set library variables:
   - `search_path`
   - `target_library`
   - `link_library`
   - `synthetic_library`
5. `define_design_lib WORK`
6. `analyze -format verilog`
7. `elaborate`
8. `current_design`
9. `link`
10. `source` the SDC constraints
11. `set_fix_multiple_port_nets -all -buffer_constants`
12. `compile`
13. Emit reports:
   - `report_qor`
   - `report_area -hierarchy`
   - `report_timing -max_paths 20`
14. Write outputs:
   - mapped Verilog
   - DDC
   - output SDC

## Inputs

Example inputs:

- RTL: `examples/alu4/alu4.v`
- constraints: `examples/alu4/alu4.sdc`
- target library:
  `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib`

Important library variables in the script:

- `target_library` points to the mapped standard-cell library
- `link_library` is `*` plus the target library
- `synthetic_library` is `dw_foundation.sldb`

## Outputs

A typical run produces these files under `<run_dir>/dc/`:

- `dc_shell.log`
- `reports/<top>_qor.rpt`
- `reports/<top>_area.rpt`
- `reports/<top>_timing.rpt`
- `out/<top>_mapped.v`
- `out/<top>.ddc`
- `out/<top>.sdc`

Supporting compiler state also appears under:

- `work/`
- `libcache/`

## Handoff To Innovus

The main handoff artifact is:

```text
<run_dir>/dc/out/alu4_mapped.v
```

The Innovus smoke flow consumes that mapped netlist directly as `init_verilog`.

Cross-reference: `recipes/innovus.md`

## Gotchas

- `REPO_DIR` is mandatory. The TCL script exits immediately if it is unset.
- The target library must be compatible with the backend flow. In the validated flow, both DC and Innovus use the same GPDK045 library family.
- DC often logs `dw_foundation.sldb` warnings if the link library is incomplete; check the log before assuming the run is clean.
- A combinational example can show unconstrained timing. Use real clock constraints before trusting QoR numbers.
- DC writes a mapped netlist for backend, but it does not prove functional correctness by itself. Pair synthesis with RTL or gate-level simulation in the digital flow.
