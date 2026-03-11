# counter8

Clocked 8-bit counter smoke test for `eda-pilot`.

## Files

- `counter8.v`: synchronous up-counter with enable and synchronous reset
- `counter8.sdc`: 200 MHz timing constraints
- `tb_counter8.v`: self-checking rollover and enable/hold testbench

## Run

```bash
source setup/cadence.sh
source setup/synopsys.sh
./flows/run_digital_flow.sh counter8
```
