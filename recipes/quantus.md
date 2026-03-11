# Quantus

Cadence Quantus is the parasitic extraction tool in the digital flow. It reads routed layout data, models resistance and capacitance from the physical interconnect, and emits a parasitic netlist such as SPEF for signoff timing in PrimeTime.

## Setup

CMC provides a tcsh launcher:

```bash
tcsh -c 'source /CMC/scripts/cadence.quantus24.10.000.csh && which quantus'
```

Machine-specific paths:

- setup script: `/CMC/scripts/cadence.quantus24.10.000.csh`
- binary: `/CMC/tools/cadence/QUANTUS24.10.000_lnx86/tools.lnx86/bin/quantus`
- helper binary: `/CMC/tools/cadence/QUANTUS24.10.000_lnx86/tools.lnx86/bin/capgen`
- license server: `CDS_LIC_FILE=6055@licaccess.cmc.ca`

The wrapper sources Cadence's common environment and adds both Quantus `bin/` directories to `PATH`.

## Invocation

Installed 24.10 help shows that Quantus expects a command file:

```bash
tcsh -c 'source /CMC/scripts/cadence.quantus24.10.000.csh && \
  quantus -cmd quantus.ccl -log_file quantus.log /path/to/top.def'
```

Observed from the installed help:

- `-cmd <file>` is required
- the positional `design_input_file` is the input DEF for LEF/DEF flow
- `-log_file <file>` names the main log
- `-check_cmd <file>` validates command-file syntax without running extraction
- `-multi_cpu <N>` is available for local parallelism

## Command File Shape

The installed Cadence examples and command reference expose the core commands needed for digital extraction:

1. `input_db -type def`
2. `process_technology`
3. `extract -selection all -type rc_coupled`
4. `output_db -type spef`
5. `output_setup`
6. optional `distributed_processing`
7. optional `log_file`

Minimal single-corner example:

```tcl
input_db \
  -type def \
  -design_file /path/to/top.def \
  -lef_file_list_file /path/to/lef.list

process_technology \
  -technology_library_file /path/to/techlib.defs \
  -technology_name gpdk045_qrc \
  -technology_corner typical \
  -temperature 25

extract \
  -selection all \
  -type rc_coupled

output_db \
  -type spef \
  -subtype standard

output_setup \
  -directory_name /path/to/out \
  -file_name top.spef \
  -compressed false

distributed_processing \
  -multi_cpu 4

log_file \
  -file_name quantus.log
```

Useful optional input-db detail from the installed command list:

- `input_db -type def` accepts `-lef_file_list_file`
- it can also accept explicit `-design_file`
- GDS/OASIS library lists are optional for flows that need them, but plain LEF/DEF is the normal digital starting point

## Inputs

Digital extraction needs three practical inputs:

- routed DEF from Innovus
- LEF files for the technology and macros
- Quantus technology data for the target RC corner

Concrete repo/PDK paths:

- DEF:
  `<run_dir>/innovus/out/alu4.def`
- tech LEF:
  `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/lef/gsclib045_tech.lef`
- macro LEF:
  `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/lef/gsclib045_macro.lef`
- QRC tech file used by Innovus:
  `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/qrc/qx/gpdk045.tch`
- Quantus corner directories in the technology kit:
  `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/qrc/typical/`
  `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/qrc/rcbest/`
  `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/qrc/rcworst/`

Practical note:

- the GPDK045 technology kit exposes actual `qrcTechFile` files under the `gpdk045_v_6_0/qrc/<corner>/` directories
- for this DEF-based flow, `quantus -check_cmd` accepted `process_technology -technology_library_file ... -technology_name ... -technology_corner ...`
- a practical wrapper is:
  - `techlib.defs`: `DEFINE gpdk045_qrc /path/to/local_defs_dir`
  - `corner.defs` in that local defs dir:
    - `DEFINE typical /CMC/kits/cadence/GPDK045/gpdk045_v_6_0/qrc/typical`
    - `DEFINE rcbest /CMC/kits/cadence/GPDK045/gpdk045_v_6_0/qrc/rcbest`
    - `DEFINE rcworst /CMC/kits/cadence/GPDK045/gpdk045_v_6_0/qrc/rcworst`
- `process_technology -technology_directory <dir>` was rejected by Quantus for this DEF flow as "not applicable in cell level flow"

The exact `techlib.defs` / `corner.defs` pattern above was validated with `quantus -check_cmd` against an `alu4` DEF. This repo still does not include a checked-in full Quantus extraction run.

## Outputs

Expected outputs from a batch extraction run:

- SPEF file
- Quantus log
- temporary extraction work directory under the chosen output path

Suggested naming:

- SPEF: `work/quantus/out/<top>.spef`
- log: `work/quantus/quantus.log`

## Flow Position

Quantus is the bridge between Innovus and PrimeTime:

1. Innovus emits routed DEF
2. Quantus extracts RC parasitics and writes SPEF
3. PrimeTime loads the SPEF with `read_parasitics`

Without this stage, PrimeTime can still time the post-route netlist, but it is missing extracted interconnect parasitics.

Cross-reference: `recipes/innovus.md`, `recipes/primetime.md`, `environment/gpdk045.md`

## Gotchas

- Quantus is command-file driven. Do not expect a single flag-only invocation like `xrun` or `pt_shell`.
- The help text treats the DEF as a positional input file, but `input_db -type def -design_file ...` is also exposed in the command language. Either pattern is defensible; a self-contained command file is easier to preserve with the run.
- The PDK exposes multiple RC corner directories. Keep the extracted corner aligned with the timing corner you plan to analyze in PrimeTime.
- The checked-in flow stops at Innovus DEF/GDS and does not prove a working Quantus run yet. Treat this recipe as the documented next step, not as a reproduced end-to-end run.
- For this LEF/DEF flow, do not assume `process_technology -technology_directory` is sufficient. The installed checker rejected that form; use `techlib.defs` plus `corner.defs`.
