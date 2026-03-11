# Sentaurus

Sentaurus is Synopsys's TCAD toolchain for process, structure, mesh, and device simulation.

## Setup

```bash
source setup/synopsys.sh
```

The wrapper exposes the currently pinned Sentaurus tree together with Design Compiler, PrimeTime, and Library Compiler.

## Tool Chain

Typical batch stages:

1. `sde` for geometry and doping definition
2. `snmesh` for meshing
3. `sdevice` for electrical simulation
4. optional post-processing with `svisual` or custom parsers

## Invocation

Headless examples:

```bash
sde -e structure.scm
snmesh mesh.cmd
sdevice device.cmd
```

Use per-run working directories. Sentaurus writes many side files and expects writable local storage.

## Inputs

Core file types:

- `.scm` for SDE geometry scripts
- `.cmd` for device simulation decks
- `.par` for parameter files
- optional `.tdr` structure and mesh outputs between stages

Practical guidance:

- keep templates under version control
- materialize run-specific decks into a scratch directory
- log every generated input because debugging TCAD without exact decks is slow

## Outputs

Common outputs:

- `.tdr` structure or solution databases
- text logs from each stage
- `.plt` plot files
- extracted CSV or markdown summaries from a parser step

## Worked Pattern

1. create a run directory under local scratch
2. copy or render `structure.scm`, `mesh.cmd`, `device.cmd`, and any `.par` file
3. run `sde`, `snmesh`, and `sdevice` in order
4. parse the resulting `.plt` or `.tdr` outputs into agent-friendly summaries

## Gotchas

- Sentaurus setup on CMC Cloud is shell-sensitive; use the repo wrapper rather than trying to source tcsh scripts from bash.
- TCAD runs can consume significant runtime and disk. Use scratch storage and clean intermediate artifacts intentionally.
- Treat `.plt` as a machine format. Convert it before using the data in downstream automation.
