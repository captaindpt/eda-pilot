# eda-pilot

## What This Repo Is

Agent-first toolkit for running Cadence and Synopsys EDA flows on CMC Cloud.

It packages:

- bash-friendly setup wrappers for the pinned tool versions
- concise per-tool recipes
- a reusable RTL-to-GDS flow runner
- environment notes for the CMC machine and GPDK045
- a tiny `alu4` smoke test

## Start Here

1. Read this file.
2. Source the setup wrappers in `setup/`.
3. Open the recipe for the tool or stage you need.
4. Use `examples/alu4/` to prove the environment before scaling up.

## Repo Layout

```text
eda-pilot/
├── CLAUDE.md
├── README.md
├── LICENSE
├── setup/
│   ├── cadence.sh
│   └── synopsys.sh
├── recipes/
│   ├── README.md
│   ├── genus.md
│   ├── innovus.md
│   ├── xcelium.md
│   ├── pegasus.md
│   ├── quantus.md
│   ├── spectre.md
│   ├── ocean.md
│   ├── design-compiler.md
│   ├── primetime.md
│   └── sentaurus.md
├── flows/
│   ├── run_digital_flow.sh
│   └── rtl-to-gds.md
├── environment/
│   ├── machine.md
│   ├── cadence-tools.md
│   ├── synopsys-tools.md
│   ├── licenses.md
│   └── gpdk045.md
└── examples/
    ├── README.md
    └── alu4/
```

## Quickstart

Source both vendor wrappers when doing digital implementation:

```bash
source setup/cadence.sh
source setup/synopsys.sh
```

Smoke-test the included example:

```bash
./flows/run_digital_flow.sh alu4
```

Default outputs land under `runs/digital-flow/<timestamp>_alu4/`.

## How To Work

- For RTL simulation, start with `recipes/xcelium.md`.
- For synthesis, choose `recipes/design-compiler.md` or `recipes/genus.md`.
- For place and route, continue with `recipes/innovus.md`.
- For extraction and post-route STA / DRC, use `recipes/quantus.md`, `recipes/primetime.md`, and `recipes/pegasus.md`.
- For analog work, use `recipes/spectre.md` and `recipes/ocean.md`.
- For TCAD, use `recipes/sentaurus.md`.
- For stage contracts across the full digital flow, use `flows/rtl-to-gds.md`.

## Constraints

- CMC Cloud only. Paths and tool versions assume `/CMC/...`.
- Headless-first. Everything in this repo should run without a GUI.
- Digital examples target GPDK045.
- GPDK045 is suitable for bring-up and benchmarking, not production closure.

## Tool Activation

`setup/cadence.sh` exposes:

- `virtuoso`
- `ocean`
- `spectre`

`setup/synopsys.sh` exposes:

- `dc_shell`
- `pt_shell`
- `lc_shell`
- `sdevice` and the rest of the Sentaurus bin tree

Some Cadence digital tools such as Genus, Innovus, Xcelium, Pegasus, and Quantus are typically launched by absolute path or by their `/CMC/scripts/*.csh` wrappers. The recipes document the exact command lines.

## Example Contract

The `alu4` example is the first validation target:

- RTL: `examples/alu4/alu4.v`
- constraints: `examples/alu4/alu4.sdc`
- runner: `flows/run_digital_flow.sh`

Do not start larger bring-up until `alu4` completes cleanly through the stages you need.
