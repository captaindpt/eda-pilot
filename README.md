# eda-pilot

**An AI-agent-first bootstrap for running Cadence and Synopsys EDA flows on CMC Cloud.**

Most EDA knowledge lives in tribal wikis, vendor PDFs, and years of muscle memory. This repo packages that knowledge as machine-readable recipes, bash-sourceable environment configs, and a reusable RTL-to-GDS flow runner so an AI coding agent (or a human in a headless terminal) can get from `git clone` to real simulation, synthesis, place-and-route, and timing artifacts in one session.

Built on CMC Cloud infrastructure with GPDK045 (Cadence Generic 45nm PDK).

## What It Looks Like

<p align="center">
  <img src="docs/images/post2_layout_bright4.png" alt="gpu_top layout produced by this flow" width="500">
</p>

<sub>A 4-lane SIMD GPU placed and routed on GPDK045 45nm using this flow runner — 27k um², ~10,800 cells. From <a href="https://github.com/captaindpt/torch2rtl">torch2rtl</a>.</sub>

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

<p align="center">
  <img src="docs/images/post2_pipeline.svg" alt="RTL-to-GDS pipeline" width="100%">
</p>

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

Outputs land in `runs/digital-flow/<timestamp>_alu4/` with per-stage logs, reports, the mapped netlist, routed DEF, GDS, and timing reports.

## Sample Output

- `alu4`: Genus area `66.690`, PT setup slack `4.93 ns`, PT hold slack `2.24 ns`
- `counter8`: Genus area `98.838`, PT setup slack `3.40 ns`, PT hold slack `0.27 ns`
- Sample reports are checked in under `examples/alu4/sample-reports/` and `examples/counter8/sample-reports/`
- Both examples reached `rtl_sim`, synthesis, Innovus, and PrimeTime on `2026-03-11`
- Pegasus still fails with the expected GPDK045 DRC baseline

## What This Proves

- An agent can bootstrap from zero to a working CMC EDA environment in one session.
- The included runner can drive real simulation, synthesis, place-and-route, CTS, routed-SPEF timing analysis, and DRC on GPDK045.
- The repo packages enough operational knowledge for an agent to act as the interface between humans and the installed tool stack.
- The checked-in examples produce real reports from commercial EDA tools, not mocked output.

## What This Does Not Prove

- Production readiness.
- Timing closure.
- DRC closure on GPDK045.
- LVS coverage in the default example flow.
- A production tapeout flow.

## Reproducibility

Regenerate the checked-in example source artifacts with:

```bash
source setup/cadence.sh
source setup/synopsys.sh
./flows/run_digital_flow.sh alu4
./flows/run_digital_flow.sh counter8
```

Those commands recreate the source run directories from which the checked-in sample-report bundles under `examples/alu4/sample-reports/` and `examples/counter8/sample-reports/` were copied.

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
| `FLOW_ENABLE_ACTIVITY_POWER` | `0` | Dump VCD during RTL sim and annotate Genus power from workload activity |
| `FLOW_ACTIVITY_VCD_SCOPE` | `<tb_name>.dut` | Hierarchical scope passed to `read_vcd` in Genus |
| `FLOW_ACTIVITY_HINST` | — | Optional Genus `read_vcd -hinst` target when scope alone is insufficient |
| `FLOW_ENABLE_QUANTUS` | `1` | Attempt standalone Quantus extraction before PrimeTime |
| `FLOW_QUANTUS_CORNER` | `typical` | Corner name for the standalone Quantus extraction config |
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
- **PrimeTime library fallback.** If `lc_shell` is unlicensed, the runner builds a PT-safe Liberty file by stripping problematic TLAT cells. Timing results are still valid for the standard cell set.
- **Standalone Quantus extraction is not fully robust yet.** The runner now attempts Quantus automatically, but on some designs it falls back to the routed SPEF emitted by Innovus `rcOut`. The run `summary.txt` records which path was used.
- **CTS and extracted timing are included, not closed.** The flow now runs explicit CTS and propagated-clock PrimeTime with SPEF, but that does not imply the design meets timing.
- **Headless only.** Everything is designed for batch/shell execution. No GUI flows, no Virtuoso schematic entry, no waveform viewers.

## For AI Agents

This repo includes a `CLAUDE.md` file designed as an agent bootstrap. Point Claude Code, Codex, or any LLM-based coding agent at this repo and it will know:

- Where every tool recipe lives
- How to activate the Cadence and Synopsys environments
- How to run the smoke test before attempting anything larger
- The stage contract for the full RTL-to-GDS flow

## Built With eda-pilot

[`torch2rtl`](https://github.com/captaindpt/torch2rtl) uses this toolkit to implement both a 4-lane SIMD GPU and a 1-lane scalar baseline for the same quantized MLP demo.
Current checked-in highlights:

- 4-lane SIMD: `27,124 um²` area, `86 MHz` extracted, `0.71 mW` VCD power, `15.9 nJ/inference`
- 1-lane scalar: `7,431 um²` area, `91 MHz` extracted, `0.18 mW` VCD power, `8.2 nJ/inference`
- SIMD wins on latency (`2x`); scalar wins on area (`3.7x`) and energy (`1.9x`)

## License

MIT. See [LICENSE](LICENSE).
