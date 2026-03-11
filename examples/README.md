# Examples

This folder holds minimal smoke-test inputs for the repo.

- `alu4/` is the first-run example for the digital flow.
- Run it with `./flows/run_digital_flow.sh alu4`.
- The flow script automatically falls back to `examples/<top>/<top>.v` and `examples/<top>/<top>.sdc` when repo-level `rtl/` and `constraints/` files are absent.
