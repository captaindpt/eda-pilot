# alu4

Minimal digital smoke test for `eda-pilot`.

## Files

- `alu4.v`: small RTL block
- `alu4.sdc`: 10 ns virtual-clock constraints

## Run

```bash
source setup/cadence.sh
source setup/synopsys.sh
./flows/run_digital_flow.sh alu4
```

Outputs land under `runs/digital-flow/<timestamp>_alu4/` unless `FLOW_RUN_ROOT` overrides the location.
