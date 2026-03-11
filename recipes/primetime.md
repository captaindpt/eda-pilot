# PrimeTime

PrimeTime is Synopsys's static timing analysis tool for signoff. In this repo's digital flow, it fits after place-and-route: read the post-route gate netlist, load the same Liberty timing views used for implementation, apply the design constraints, optionally load extracted parasitics, and emit setup/hold violation reports.

## Setup

CMC provides a tcsh launcher:

```bash
tcsh -c 'source /CMC/scripts/synopsys.prime.2024.09-SP2.csh && which pt_shell'
```

Machine-specific paths:

- setup script: `/CMC/scripts/synopsys.prime.2024.09-SP2.csh`
- install root: `/CMC/tools/synopsys/prime_vW-2024.09-SP2/prime/W-2024.09-SP2`
- binary: `/CMC/tools/synopsys/prime_vW-2024.09-SP2/prime/W-2024.09-SP2/bin/pt_shell`
- license server: `SNPSLMD_LICENSE_FILE=6053@licaccess.cmc.ca`

The PrimeTime wrapper sources the shared Synopsys environment and adds both PrimeTime `bin/` directories to `PATH`.

## Invocation

Headless batch form accepted on this machine:

```bash
tcsh -c 'source /CMC/scripts/synopsys.prime.2024.09-SP2.csh && \
  pt_shell -f script.tcl -no_init'
```

Observed from the installed W-2024.09-SP2 help:

- the wrapper help advertises `-file script.tcl`
- `-f script.tcl` also worked in a verified smoke run
- `-no_init` skips local startup files for more reproducible batch runs
- `-output_log_file run.log` is available if you want a named tool log

## TCL Flow

Minimal signoff structure:

1. Set `TOP`, `NETLIST`, `SDC`, `LIB`, and optional `SPEF`.
2. Set timing library variables:
   - `search_path`
   - `target_library`
   - `link_path`
3. `read_verilog $NETLIST`
4. `link_design $TOP`
5. `read_sdc $SDC`
6. Optional post-route parasitics:
   - `read_parasitics -format spef $SPEF`
7. Emit reports:
   - `report_timing -delay max -max_paths 20`
   - `report_timing -delay min -max_paths 20`
   - `report_constraint -all_violators`
8. `exit`

Example skeleton:

```tcl
set TOP alu4_flow_demo
set NETLIST /path/to/alu4_flow_demo_postroute.v
set SDC /path/to/alu4_flow_demo.sdc
set LIB /CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib
set SPEF /path/to/alu4_flow_demo.spef

set search_path [list [file dirname $NETLIST] [file dirname $LIB]]
set target_library [list $LIB]
set link_path [concat "*" $target_library]

read_verilog $NETLIST
link_design $TOP
read_sdc $SDC

if {[file exists $SPEF]} {
    read_parasitics -format spef $SPEF
}

report_timing -delay max -max_paths 20 > timing_setup.rpt
report_timing -delay min -max_paths 20 > timing_hold.rpt
report_constraint -all_violators > constraints.rpt
exit
```

## Inputs

PrimeTime expects:

- gate-level netlist from synthesis or P&R
- Liberty timing library for the same standard-cell family/corner
- SDC constraints
- optional SPEF parasitics for post-route signoff

Concrete repo paths for the fullflow demo:

- post-route netlist:
  `<run_dir>/innovus/out/alu4_postroute.v`
- constraints handoff from synthesis:
  `<run_dir>/dc/out/alu4.sdc`
- Liberty:
  `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib`

The checked-in flow does not include a SPEF export. Innovus did run `extractRC`, but the demo TCL stops after reports, DEF, post-route netlist, and GDS.

## Outputs

Typical batch outputs:

- setup timing report
- hold timing report
- constraint/violation report
- optional named tool log via `-output_log_file`

These are the main signoff artifacts to preserve or feed into later review automation.

## Flow Position

PrimeTime runs after backend implementation:

1. synthesis emits mapped netlist plus constraints
2. Innovus places and routes that design
3. PrimeTime reads the backend netlist and, when available, backend parasitics
4. timing reports determine whether the routed design is actually signoff-clean

For this repo's demo handoff, the natural input is the Innovus post-route netlist plus the DC-produced SDC.

Cross-reference: `recipes/design-compiler.md`, `recipes/innovus.md`

## Gotchas

- Source the CMC setup with `csh` or `tcsh`. Sourcing the `.csh` wrapper from `bash` does not set the environment correctly.
- The installed help shows `-file`, but `-f` also worked in a live smoke run on this machine.
- `read_parasitics` is optional in syntax but important for real post-route signoff. Without SPEF, you are timing the gate netlist with library delays only.
- Keep Liberty corner selection aligned with the MMMC or signoff corner you care about. The repo examples currently use the GPDK045 slow 1.0 V library view.
