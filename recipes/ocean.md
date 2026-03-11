# OCEAN

OCEAN is Cadence's batch measurement language for post-processing Spectre and Virtuoso simulation results.

## Setup

```bash
source setup/cadence.sh
```

## Invocation

Headless batch form:

```bash
ocean -nograph < script.ocn > ocean.log 2>&1
```

Keep the script non-interactive and write explicit pass/fail messages to stdout.

## Script Shape

A reliable OCEAN script usually does four things:

1. open a results database with `openResults(...)`
2. select the analysis with `selectResult(...)`
3. compute measurements with `value`, `cross`, `clip`, `integ`, or custom helpers
4. print or assert the final numbers

Minimal pattern:

```lisp
openResults("./psf")
selectResult('tran)
let( (vout t_cross)
  vout = v("/out")
  t_cross = cross(vout 0.5 1 "rising")
  printf("first_rise=%L\n" t_cross)
)
exit
```

## Common Uses

- logic-level threshold checks on transient waveforms
- delay or first-crossing measurements
- current and energy extraction
- regression-friendly pass/fail summaries for CI or agent loops

## Outputs

Typical outputs:

- `ocean.log`
- printed measurements in a stable text format
- optional CSV or plain-text summaries written by `outfile(...)`

## Gotchas

- OCEAN can exit zero even when the script printed an error message. Inspect `ocean.log`.
- Use `-nograph` on headless machines; GUI startup paths are not available on CMC Cloud.
- Keep file paths relative to repo root or absolute. OCEAN scripts are hard to debug when they depend on shell cwd implicitly.
