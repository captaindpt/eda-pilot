# Spectre

Cadence Spectre is the batch analog simulator used for transistor-level and mixed-signal netlists on CMC Cloud.

## Setup

```bash
source setup/cadence.sh
```

The wrapper exposes `spectre`, `ocean`, and the IC23 binaries from bash.

## Invocation

Minimal headless form:

```bash
spectre input.scs \
  +log spectre.log \
  -format psfxl
```

Useful flags:

- `+log <file>` writes a deterministic text log.
- `-format psfxl` emits PSF-XL results for OCEAN or custom parsers.
- `+escchars` helps when net names contain escaped characters.

## Input Shape

A practical batch deck usually contains:

1. `simulator lang=spectre`
2. PDK model includes from `environment/gpdk045.md`
3. DUT subckt or extracted view include
4. sources and loads
5. one or more analyses such as `dc`, `tran`, or `ac`
6. `save` statements for the nodes and currents you need

Minimal transient example:

```spectre
simulator lang=spectre
include "/CMC/kits/cadence/GPDK045/gpdk045_v_6_0/models/spectre/gpdk045.scs"
parameters vdd=1.0
VDD (vdd 0) vsource dc=vdd
VIN (in 0) vsource type=pulse val0=0 val1=vdd period=10n rise=100p fall=100p width=5n
tran tran stop=40n
save V(in) V(out)
```

## Outputs

Typical run outputs:

- `spectre.log`
- `psf/` or `psfXL/`
- optional assertion summary files if the deck uses checks

Use OCEAN when you need scripted pass/fail extraction from those waveforms.

## Gotchas

- Spectre itself is headless, but missing Cadence licensing will fail before parsing the deck.
- Always save only the signals you need on large runs; default save behavior can explode disk usage.
- GPDK045 model includes are sensitive to corner and section names. Reuse known-good include paths from `environment/gpdk045.md`.
- Treat warnings as review items; convergence or model warnings often mean the measurement is not trustworthy.
