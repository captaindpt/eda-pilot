# Genus

Cadence Genus is the Cadence-native RTL synthesis tool. It fills the same role as Synopsys Design Compiler: read RTL plus constraints, map to a Liberty standard-cell library, and emit a gate-level netlist for downstream place-and-route.

## Setup

CMC provides a matching Genus setup script:

```bash
tcsh -c 'source /CMC/scripts/cadence.genus21.17.000.csh && which genus'
```

Machine-specific paths:

- setup script: `/CMC/scripts/cadence.genus21.17.000.csh`
- binary: `/CMC/tools/cadence/GENUS21.17.000_lnx86/tools.lnx86/bin/genus`

License behavior:

- the Genus wrapper sources Cadence's common setup script
- on this machine Genus reported `Configured Lic search path ... 6055@licaccess.cmc.ca`
- if Cadence licensing is missing in your shell, export `CDS_LIC_FILE=6055@licaccess.cmc.ca`

## Invocation

Headless batch form:

```bash
tcsh -c 'source /CMC/scripts/cadence.genus21.17.000.csh && \
  genus -files script.tcl -no_gui -batch -log run_name'
```

Observed from the installed 21.17 help:

- `-files <script.tcl>` executes a TCL command file
- `-no_gui` disables the GUI
- `-batch` exits after processing the files
- `-log <prefix>` creates `<prefix>.log` and `<prefix>.cmd`
- `-overwrite` reuses default log names if needed

## TCL Flow

The working command sequence on this machine is:

1. `read_libs <liberty.lib>`
2. `read_hdl -language v2001 <rtl.v>`
3. `elaborate <top>`
4. `read_sdc <constraints.sdc>`
5. `syn_generic`
6. `syn_map`
7. `write_netlist > mapped.v`
8. reports:
   - `report_area > area.rpt`
   - `report_timing -max_paths 20 > timing.rpt`
   - `report_power > power.rpt`

Note on naming:

- The ticket describes the output step as `write_hdl`.
- In the installed Genus 21.17 help, the actual command exposed for Verilog output is `write_netlist`.

## Inputs

Use the same GPDK045 library family as the DC and Innovus flow:

- Liberty timing library:
  `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib`
- RTL example:
  `examples/alu4/alu4.v`
- SDC example:
  `examples/alu4/alu4.sdc`

Important release-specific detail:

- `read_hdl -language verilog` failed on this machine
- Genus 21.17 expects language tokens such as `v1995`, `v2001`, `sv`, `vhdl`, or `mixvlog`

## Minimal Example

```tcl
read_libs /CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib
read_hdl -language v2001 /path/to/top.v
elaborate top
read_sdc /path/to/top.sdc
syn_generic
syn_map
report_area > area.rpt
report_timing -max_paths 20 > timing.rpt
report_power > power.rpt
write_netlist > top_mapped.v
quit
```

## Outputs

Expected outputs from a headless run:

- mapped netlist, typically `*_mapped.v`
- area report
- timing report
- power report
- Genus command log: `<prefix>.log`
- Genus command replay file: `<prefix>.cmd`

Expected smoke-run artifacts from a headless run:

- `mapped.v`
- `area.rpt`
- `timing.rpt`
- `run.log`
- `run.cmd`

## Handoff To Innovus

Like DC, Genus should hand off a mapped gate-level Verilog netlist to Innovus. The interface is the same:

- synthesis emits mapped Verilog
- Innovus consumes that netlist as its design input

Cross-reference: `recipes/innovus.md`

## Gotchas

- The tool prints an OS-support warning on this host before startup. In the verified smoke run, that warning was non-fatal.
- Library load can emit many `LBR-9` warnings for unusable cells such as antenna/decap entries in the GPDK045 library. The smoke run still synthesized successfully.
- Use `v2001` or `sv` with `read_hdl`; plain `verilog` was rejected by the installed command parser.
- `report_power` is available in the tool, but meaningful power numbers require a more complete activity/analysis setup than the minimal smoke flow.

For the broader flow, treat Genus as the Cadence alternative to `recipes/design-compiler.md`.
