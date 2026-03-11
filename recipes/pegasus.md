# Pegasus

Cadence Pegasus is the physical verification tool for DRC and LVS. In this repo's digital flow, the main use is post-route DRC on the GDS streamed out of Innovus; LVS is available, but this repo does not yet include a working Pegasus-based LVS run.

## Setup

CMC provides a matching tcsh launcher:

```bash
tcsh -c 'source /CMC/scripts/cadence.pegasus23.26.000.csh && which Pegasus'
```

Machine-specific paths:

- setup script: `/CMC/scripts/cadence.pegasus23.26.000.csh`
- binary: `/CMC/tools/cadence/PEGASUS23.26.000_lnx86/tools.lnx86/bin/Pegasus`
- license server: `CDS_LIC_FILE=6055@licaccess.cmc.ca`

The wrapper sources Cadence's common environment and prepends both Pegasus `bin/` directories to `PATH`.

## Invocation

Installed help shows Pegasus expects a PVL rule deck as the final positional argument.

Typical batch DRC form:

```bash
tcsh -c 'source /CMC/scripts/cadence.pegasus23.26.000.csh && \
  Pegasus -drc \
    -gds /path/to/top.gds \
    -top_cell top \
    -log drc.log \
    -run_dir pegasus_drc \
    /path/to/pvlDRC.rul'
```

Typical batch LVS form:

```bash
tcsh -c 'source /CMC/scripts/cadence.pegasus23.26.000.csh && \
  Pegasus -lvs \
    -gds /path/to/top.gds \
    -top_cell top \
    -source_verilog /path/to/top_postroute.v \
    -source_top_cell top \
    -log lvs.log \
    -run_dir pegasus_lvs \
    /path/to/pvlLVS.rul'
```

Observed from the installed 23.26 help:

- `-drc` selects design-rule checking
- `-lvs` selects layout-vs-schematic
- `-gds` points to the streamed-out layout database
- `-top_cell` names the layout top
- `-source_verilog` or `-source_cdl` provides the LVS source netlist
- `-log` writes the main run log
- `-run_dir` collects generated results

## Inputs

For digital DRC:

- GDS from Innovus `streamOut`
- DRC PVL rule file from the PDK
- top cell name

For LVS:

- layout GDS
- LVS PVL rule file
- source netlist, usually Verilog or CDL
- matching top-cell names and, for more complex cases, hierarchy-cell controls

Concrete repo handoff path:

- GDS:
  `<run_dir>/innovus/out/alu4.gds`

Potential digital LVS source:

- post-route netlist:
  `<run_dir>/innovus/out/alu4_postroute.v`

## GPDK045 Rule Files

There is no obvious dedicated `pegasus/` directory under GPDK045. The useful physical-verification content is under the PDK's `pvs/` directory:

- DRC rule deck:
  `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/pvs/pvlDRC.rul`
- LVS rule deck:
  `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/pvs/pvlLVS.rul`
- fill rule deck:
  `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/pvs/pvlFILL.rul`
- antenna rule deck:
  `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/pvs/pvlAnt.rul`
- control include used by LVS:
  `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/pvs/pvs_control_file`

Why these are the likely Pegasus inputs:

- Pegasus help explicitly says the positional rule-file argument is a PVL rule file
- the GPDK045 decks are named `pvlDRC.rul` and `pvlLVS.rul`
- the headers identify them as "PVS DRC RULE DECK" and "PVS LVS RULE DECK"

That is an inference from the installed tool help plus the PDK contents; this repo does not yet include a verified Pegasus run using these decks.

## Outputs

Expected batch artifacts:

- main run log from `-log`
- run directory with result databases and summary files
- DRC violation database/report for DRC runs
- LVS comparison report for LVS runs
- optional extracted layout netlist when using LVS or extraction modes

## Flow Position

In the digital-only flow, Pegasus belongs after Innovus stream-out:

1. synthesis creates the mapped netlist
2. Innovus routes and writes `*.gds`
3. Pegasus checks that layout against process rules
4. optional LVS compares layout connectivity against the source netlist

For the current repo, DRC is the main immediate concern because the fullflow demo already produces a GDS artifact. LVS is possible, but not yet grounded in a checked-in Pegasus runbook.

Cross-reference: `recipes/innovus.md`, `environment/gpdk045.md`

## Gotchas

- Pegasus prints an OS-support warning on this machine before startup. The help command still worked normally.
- GPDK045 exposes PVL rule decks under `pvs/`, not a clean Pegasus-branded subdirectory.
- The PDK also includes older `assura/` and `diva/` rule files. Those are not the right starting point for Pegasus.
- For LVS, digital flows often need extra hierarchy, black-box, or source-netlist cleanup settings beyond the minimal command line shown here. Treat the DRC flow as the lower-risk first target.
