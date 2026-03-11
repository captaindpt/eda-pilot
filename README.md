# eda-pilot

Agent-first toolkit for Cadence and Synopsys EDA on CMC Cloud.

## What's Included

- `setup/`: bash wrappers for the pinned Cadence and Synopsys tool stacks
- `recipes/`: concise operating notes for 10 tools
- `flows/`: a reusable RTL-to-GDS runner plus the stage contract
- `environment/`: machine, licensing, tool inventory, and GPDK045 notes
- `examples/alu4/`: minimal smoke-test design

## Quickstart

```bash
git clone <repo-url>
cd eda-pilot
source setup/cadence.sh
source setup/synopsys.sh
./flows/run_digital_flow.sh alu4
```

The `alu4` example is the recommended first run. Outputs default to `runs/digital-flow/`.

## Tool Coverage

| Tool | Recipe |
|------|--------|
| Genus | `recipes/genus.md` |
| Innovus | `recipes/innovus.md` |
| Xcelium | `recipes/xcelium.md` |
| Pegasus | `recipes/pegasus.md` |
| Quantus | `recipes/quantus.md` |
| Spectre | `recipes/spectre.md` |
| OCEAN | `recipes/ocean.md` |
| Design Compiler | `recipes/design-compiler.md` |
| PrimeTime | `recipes/primetime.md` |
| Sentaurus | `recipes/sentaurus.md` |

## Requirements

- CMC Cloud account or equivalent access to `/CMC/tools` and `/CMC/kits`
- GPDK045 for the included digital flow
- headless Linux shell environment

## For AI Agents

`CLAUDE.md` is the repo bootstrap. It tells an agent where the recipes live, how to activate tools, and how to run the included smoke test.

## Notes

- This repo focuses on operational bring-up, not product-grade signoff automation.
- GPDK045 DRC is a known limitation of the academic kit; see `environment/gpdk045.md`.

## License

MIT. See `LICENSE`.
