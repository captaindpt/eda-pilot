# Recipes

These are task-focused operating notes for the tools validated on CMC Cloud.

## Cadence

| File | Tool | Primary use |
|------|------|-------------|
| `genus.md` | Genus | RTL synthesis |
| `innovus.md` | Innovus | Place and route |
| `xcelium.md` | Xcelium | RTL and gate simulation |
| `pegasus.md` | Pegasus | DRC and LVS |
| `quantus.md` | Quantus | Parasitic extraction |
| `spectre.md` | Spectre | Analog and mixed-signal simulation |
| `ocean.md` | OCEAN | Headless waveform checks and measurement scripts |

## Synopsys

| File | Tool | Primary use |
|------|------|-------------|
| `design-compiler.md` | Design Compiler | RTL synthesis |
| `primetime.md` | PrimeTime | Static timing analysis |
| `sentaurus.md` | Sentaurus | TCAD structure, mesh, and device simulation |

## How To Use This Folder

1. Activate the shell wrappers in `setup/`.
2. Open the recipe for the tool you need.
3. Start from the minimal headless invocation.
4. For digital implementation, use `../flows/rtl-to-gds.md` and `../flows/run_digital_flow.sh` as the stage contract.
