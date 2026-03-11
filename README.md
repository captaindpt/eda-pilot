# eda-pilot

**An AI-agent-first toolkit for running Cadence and Synopsys EDA flows on CMC Cloud.**

Most EDA knowledge lives in tribal wikis, vendor PDFs, and years of muscle memory. This repo packages that knowledge as machine-readable recipes, bash-sourceable environment configs, and a single-command RTL-to-GDS flow runner — so an AI coding agent (or a human in a headless terminal) can go from `git clone` to placed-and-routed silicon in one session.

Built on CMC Cloud infrastructure with GPDK045 (Cadence Generic 45nm PDK).

## What's In the Box

### 10 Tool Recipes

Operational, headless-first recipes for every major tool in the Cadence and Synopsys digital/analog stacks:

| Stage | Tool | Vendor | Recipe |
|-------|------|--------|--------|
| RTL Simulation | **Xcelium** | Cadence | [`recipes/xcelium.md`](recipes/xcelium.md) |
| Synthesis | **Design Compiler** | Synopsys | [`recipes/design-compiler.md`](recipes/design-compiler.md) |
| Synthesis | **Genus** | Cadence | [`recipes/genus.md`](recipes/genus.md) |
| Place & Route | **Innovus** | Cadence | [`recipes/innovus.md`](recipes/innovus.md) |
| Parasitic Extraction | **Quantus** | Cadence | [`recipes/quantus.md`](recipes/quantus.md) |
| Static Timing Analysis | **PrimeTime** | Synopsys | [`recipes/primetime.md`](recipes/primetime.md) |
| DRC / LVS | **Pegasus** | Cadence | [`recipes/pegasus.md`](recipes/pegasus.md) |
| Analog Simulation | **Spectre** | Cadence | [`recipes/spectre.md`](recipes/spectre.md) |
| Waveform Scripting | **OCEAN** | Cadence | [`recipes/ocean.md`](recipes/ocean.md) |
| TCAD | **Sentaurus** | Synopsys | [`recipes/sentaurus.md`](recipes/sentaurus.md) |

Each recipe includes: setup commands, exact binary paths, minimal TCL/command examples, expected outputs, and documented gotchas specific to the CMC environment.

### RTL-to-GDS Flow Runner

`flows/run_digital_flow.sh` — a single bash script that chains the full digital implementation pipeline:

```
RTL + SDC
    → Xcelium (simulation)
        → Design Compiler or Genus (synthesis)
            → Innovus (place & route → DEF, GDS)
                → PrimeTime (static timing signoff)
                    → Pegasus (DRC)
```

The runner auto-selects the synthesis backend (DC when given `.db` libraries, Genus when given `.lib`), handles PrimeTime library compilation/fallback, sanitizes SDC for cross-tool compatibility, and produces a structured `summary.txt` with pass/fail per stage.

### Environment Configuration

- **`setup/cadence.sh`** — sources Cadence IC23 (Virtuoso 23.10.140), Spectre 23.10.802, and license config
- **`setup/synopsys.sh`** — sources Synopsys Design Compiler W-2024.09-SP2, PrimeTime W-2024.09-SP2, Library Compiler, and Sentaurus X-2025.09
- **`environment/`** — machine specs, full tool inventories for both vendors, license server details, and GPDK045 PDK documentation (library corners, LEF/GDS/QRC paths, known DRC baselines)

### Smoke-Test Examples

- `examples/alu4/` — a 4-bit ALU (add, subtract, AND, XOR) with Verilog RTL, SDC, and self-checking testbench
- `examples/counter8/` — an 8-bit synchronous counter with real clock constraints and rollover coverage

## Quickstart

```bash
git clone https://github.com/captaindpt/eda-pilot.git
cd eda-pilot
source setup/cadence.sh
source setup/synopsys.sh
./flows/run_digital_flow.sh alu4
```

Outputs land in `runs/digital-flow/<timestamp>_alu4/` with per-stage logs, reports, the mapped netlist, routed DEF, GDS, and timing signoff reports.

## Sample Output

- `alu4`: Genus area `66.690`, PT setup slack `4.93 ns`, PT hold slack `2.24 ns`
- `counter8`: Genus area `98.838`, PT setup slack `3.40 ns`, PT hold slack `0.27 ns`
- Sample reports are checked in under `examples/alu4/sample-reports/` and `examples/counter8/sample-reports/`
- Both examples reached `rtl_sim`, synthesis, Innovus, and PrimeTime on `2026-03-11`
- Pegasus still fails with the expected GPDK045 DRC baseline

## Repo Structure

```
eda-pilot/
├── CLAUDE.md              # AI agent bootstrap (read-first for Claude Code, Codex, etc.)
├── README.md              # This file
├── setup/
│   ├── cadence.sh         # Cadence IC23 + Spectre environment
│   └── synopsys.sh        # Synopsys DC + PT + LC + Sentaurus environment
├── recipes/
│   ├── genus.md           # Cadence synthesis
│   ├── design-compiler.md # Synopsys synthesis
│   ├── innovus.md         # Cadence place & route
│   ├── xcelium.md         # Cadence digital simulation
│   ├── primetime.md       # Synopsys static timing
│   ├── pegasus.md         # Cadence DRC/LVS
│   ├── quantus.md         # Cadence parasitic extraction
│   ├── spectre.md         # Cadence analog simulation
│   ├── ocean.md           # Cadence waveform scripting
│   └── sentaurus.md       # Synopsys TCAD
├── flows/
│   ├── run_digital_flow.sh  # Single-command RTL→GDS runner
│   └── rtl-to-gds.md        # Stage contract documentation
├── environment/
│   ├── machine.md         # Host specs (Rocky Linux 8.10, Xeon Gold 6248R)
│   ├── cadence-tools.md   # Cadence tool inventory with paths
│   ├── synopsys-tools.md  # Synopsys tool inventory with paths
│   ├── licenses.md        # License server configuration
│   └── gpdk045.md         # PDK documentation (cells, LEF, Liberty, QRC, GDS)
└── examples/
    └── alu4/              # 4-bit ALU smoke test (RTL + SDC)
```

## Flow Runner Details

The flow runner (`flows/run_digital_flow.sh`) is configurable via environment variables:

| Variable | Default | Purpose |
|----------|---------|---------|
| `FLOW_RTL` | `rtl/<module>.v` or `examples/<module>/<module>.v` | RTL source |
| `FLOW_SDC` | `constraints/<module>.sdc` or `examples/<module>/<module>.sdc` | Timing constraints |
| `FLOW_TB` | `tb/tb_<module>.v` or `examples/<module>/tb_<module>.v` | Testbench (skipped if missing) |
| `FLOW_SYNTH_TOOL` | `auto` | Force `dc` or `genus` (auto-detects from library format) |
| `FLOW_SPEF` | — | Pre-extracted parasitics for PrimeTime |
| `FLOW_ENABLE_POWER_GRID` | `0` | Enable `addRing` + `sroute` in Innovus |
| `FLOW_ENABLE_FILLERS` | `0` | Enable filler cell insertion + eco routing |

Run your own design:

```bash
FLOW_RTL=/path/to/my_design.v \
FLOW_SDC=/path/to/my_design.sdc \
./flows/run_digital_flow.sh my_design
```

## Target Environment

- **Platform**: CMC Cloud (Canadian Microelectronics Corporation) — headless Rocky Linux 8.10 VMs
- **PDK**: Cadence GPDK045 (Generic 45nm) with `gsclib045` standard cells
- **Cadence tools**: IC23, Spectre 23, Genus 21.17, Innovus 21.17, Xcelium 25.09, Pegasus 23.26, Quantus 23.10
- **Synopsys tools**: Design Compiler W-2024.09-SP2, PrimeTime W-2024.09-SP2, Library Compiler W-2024.09-SP2, Sentaurus X-2025.09
- **Licenses**: CMC license server at `licaccess.cmc.ca` (ports 6055 for Cadence, 6053 for Synopsys)

## Known Limitations

- **GPDK045 is an academic PDK.** It's suitable for flow bring-up, benchmarking, and learning — not production tapeout. The base `gsclib045` library lacks dedicated well-tap and endcap cells, which means Pegasus DRC will always report a standing baseline of violations (~1k for small designs, ~19k for larger ones). This is a kit limitation, not a design bug.
- **No CTS in the smoke flow.** The Innovus script runs `placeDesign` → `routeDesign` without explicit clock tree synthesis. Fine for combinational logic and small sequential designs; real clock-heavy designs would need CTS added.
- **PrimeTime library fallback.** If `lc_shell` is unlicensed, the runner builds a PT-safe Liberty file by stripping problematic TLAT cells. Timing results are still valid for the standard cell set.
- **Headless only.** Everything is designed for batch/shell execution. No GUI flows, no Virtuoso schematic entry, no waveform viewers.

## For AI Agents

This repo includes a `CLAUDE.md` file designed as an agent bootstrap. Point Claude Code, Codex, or any LLM-based coding agent at this repo and it will know:

- Where every tool recipe lives
- How to activate the Cadence and Synopsys environments
- How to run the smoke test before attempting anything larger
- The stage contract for the full RTL-to-GDS flow

## Built With eda-pilot

[`torch2rtl`](https://github.com/captaindpt/torch2rtl) is a 4-lane SIMD GPU that compiles and runs PyTorch models, then synthesizes, places, routes, and times the design with this toolkit.
Benchmark highlights: area `26494.056`, max frequency `118.34 MHz`, energy per inference `32.45 nJ`, SIMD speedup `3.93x`.

## License

MIT. See [LICENSE](LICENSE).
