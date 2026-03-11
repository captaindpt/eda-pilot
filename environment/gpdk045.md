# GPDK045

GPDK045 is the 45nm generic Cadence PDK used by the digital flow in this repo. On this machine it lives under `/CMC/kits/cadence/GPDK045/` and is split into three practical branches:

- standard cells: `gsclib045_all_v4.4`
- IO cells: `giolib045_v3.3`
- technology kit / device models / rule decks: `gpdk045_v_6_0`

This is an academic/demo kit, not a foundry production PDK.

## Top-Level Structure

- `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/`
- `/CMC/kits/cadence/GPDK045/giolib045_v3.3/`
- `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/`

Inside `gsclib045_all_v4.4` the standard-cell family is further split into:

- `gsclib045` - base library used by the current digital flow
- `gsclib045_hvt` - high-Vt variant
- `gsclib045_lvt` - low-Vt variant
- `gsclib045_backbias` - back-bias variant
- `gsclib045_tech` - technology support collateral

## Standard Cells: `gsclib045`

Primary working path: `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/`

Important subdirectories:

- `timing/`
- `lef/`
- `gds/`
- `verilog/`
- `cdl/`
- `qrc/`
- `spectre/`
- `spef/`
- `techfile/`
- `oa22/`

## Tool Map

### Synthesis

- slow:
  - `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib`
  - `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v2_basicCells.lib`
- fast:
  - `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/timing/fast_vdd1v0_basicCells.lib`
  - `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/timing/fast_vdd1v2_basicCells.lib`
- typical:
  - no obvious standard-cell `typical` / `tt` Liberty file was found under `gsclib045_all_v4.4` on this machine

Archive digital flow currently uses `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib`.

Related Liberty groups also exist for:

- `extvdd1v0`
- `extvdd1v2`
- `multibitsDFF`

### Place And Route

LEF files:

- tech LEF:
  `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/lef/gsclib045_tech.lef`
- macro LEF:
  `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/lef/gsclib045_macro.lef`
- multibit DFF LEF:
  `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/lef/gsclib045_multibitsDFF.lef`

GDS merge file: `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/gds/gsclib045.gds`

### Digital Simulation

Functional Verilog models:

- `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v`
- `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/verilog/fast_vdd1v0_basicCells.v`

The directory also contains matching files for:

- `vdd1v2`
- `extvdd1v0`
- `extvdd1v2`
- `multibitsDFF`

### Parasitic Extraction

Standard-cell RC tech file used by the Innovus flow:

- `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/qrc/qx/gpdk045.tch`

Templates in the same area:

- `qrc/template.rsf`
- `qrc/rcx.template.rsf`
- `qrc/template.vlr`

### Analog Simulation

Standard-cell Spectre views:

- `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/spectre/gsclib045/`
- `/CMC/kits/cadence/GPDK045/gsclib045_all_v4.4/gsclib045/spectre/gsclib045_extracted/`

This branch contains one `.scs` file per cell, for example `ADDFX1.scs`, `INVXL.scs`, and `DFFX1.scs`.

## IO Library: `giolib045_v3.3`

Path: `/CMC/kits/cadence/GPDK045/giolib045_v3.3/`

Useful contents:

- LEF:
  `/CMC/kits/cadence/GPDK045/giolib045_v3.3/lef/giolib045.lef`
- CDL:
  `/CMC/kits/cadence/GPDK045/giolib045_v3.3/cdl/giolib045.cdl`
- Spectre:
  - `/CMC/kits/cadence/GPDK045/giolib045_v3.3/spectre/giolib045_schematic.scs`
  - `/CMC/kits/cadence/GPDK045/giolib045_v3.3/spectre/giolib045_extracted.scs`
- digital models:
  - `/CMC/kits/cadence/GPDK045/giolib045_v3.3/vlog/pads_FF_s1vg.v`
  - `/CMC/kits/cadence/GPDK045/giolib045_v3.3/vlog/pads_SS_s1vg.v`
  - `/CMC/kits/cadence/GPDK045/giolib045_v3.3/vlog/pads_TT_s1vg.v`

Representative pad cells: `PADDI`, `PADDO`, `PADDOZ`, `PADVDD`, `PADVSS`

## Technology Kit: `gpdk045_v_6_0`

Path: `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/`

- OA technology library:
  `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/gpdk045/`
- technology file:
  `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/gpdk045/tech_gpdk045.tf`
- display/resource files:
  - `display.drf`
  - `gpdk045.layermap`
  - `pdk.dat`
- setup snippets:
  - `cmcsetup/cdsenv`
  - `cmcsetup/cdsinit`
  - `cmcsetup/simrc`
- reference manuals:
  - `docs/gpdk045_pdk_referenceManual.pdf`
  - `docs/gpdk045_drc.pdf`
  - `docs/gpdk045_PDK_Model_Report.pdf`

Device models:

- `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/models/spectre/gpdk045.scs`
- `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/models/spectre/gpdk045_mos.scs`
- `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/models/spectre/gpdk045_resistor.scs`
- `/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/models/spectre/gpdk045_mimcap.scs`

Extraction / RC collateral:

- ICT corners:
  - `ict/GPDK045_rcbest.ict`
  - `ict/GPDK045_rcworst.ict`
  - `ict/GPDK045_typical.ict`
- QRC corners:
  - `qrc/rcbest/qrcTechFile`
  - `qrc/rcworst/qrcTechFile`
  - `qrc/typical/qrcTechFile`

Physical verification collateral:

- PVS/Pegasus-era rule area:
  - `pvs/pvlDRC.rul`
  - `pvs/pvlLVS.rul`
  - `pvs/pvlFILL.rul`
  - `pvs/pvlAnt.rul`
- older Assura/Diva rule areas:
  - `assura/assuraDRC.rul`
  - `assura/extract.rul`
  - `diva/divaDRC.rul`
  - `diva/divaLVS.rul`

## Practical Notes

- For the current digital flow, agents usually only need five paths:
  - synthesis Liberty: `timing/slow_vdd1v0_basicCells.lib`
  - tech LEF: `lef/gsclib045_tech.lef`
  - macro LEF: `lef/gsclib045_macro.lef`
  - QRC tech file: `qrc/qx/gpdk045.tch`
  - standard-cell GDS: `gds/gsclib045.gds`
- The technology kit contains typical RC data, but the base standard-cell library did not expose a matching typical Liberty file in the scanned directories.
- IO cells live in a separate library tree; do not expect them inside `gsclib045/`.

## Known Limitations

Pegasus DRC with the base `gsclib045` library produces a large standing baseline of violations. Treat that as a kit limitation, not automatic proof of a design bug.

Observed scale:

- `alu4`: about `978` violations
- larger sequential designs: around `19k` violations

Main causes:

- no dedicated well-tap cells in the base library
- no dedicated endcap cells in the base library
- routing-rule fallout from the academic kit and default auto-router behavior
- LVT geometry and substrate-connection issues that cannot be fixed at the RTL level

Practical implication:

- use GPDK045 for flow bring-up, functional proof, timing, and GDS generation
- do not promise DRC-clean signoff with the base library
- if DRC reduction matters, investigate the `gsclib045_backbias` variant and re-run the full backend flow
