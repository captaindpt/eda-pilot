# Examples

This folder holds minimal smoke-test inputs for the repo.

- `alu4/` is the first-run example for the digital flow.
- `counter8/` is the clocked sequential example for setup/hold and stateful logic.
- Run it with `./flows/run_digital_flow.sh alu4`.
- Run the sequential example with `./flows/run_digital_flow.sh counter8`.
- The flow script automatically falls back to `examples/<top>/<top>.v` and `examples/<top>/<top>.sdc` when repo-level `rtl/` and `constraints/` files are absent.
- Testbenches can live at either `tb/tb_<top>.v` or `examples/<top>/tb_<top>.v`.
