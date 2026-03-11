# Xcelium

Cadence Xcelium is the digital simulation tool for RTL and gate-level Verilog/SystemVerilog/VHDL. For this repo, it is the Cadence-native path to verify RTL before synthesis and to re-simulate mapped netlists later in the GPU flow.

## Setup

CMC provides a matching Xcelium 25.09 setup script:

```bash
tcsh -c 'source /CMC/scripts/cadence.xceliummain25.09.001.csh && which xrun'
```

Machine-specific paths:

- setup script: `/CMC/scripts/cadence.xceliummain25.09.001.csh`
- binary: `/CMC/tools/cadence/XCELIUMMAIN25.09.001_lnx86/tools.lnx86/bin/xrun`

License behavior:

- the Xcelium wrapper sources Cadence's common setup script
- on this machine that resolves `CDS_LIC_FILE=6055@licaccess.cmc.ca`
- if Cadence licensing is not already present in your shell, export `CDS_LIC_FILE=6055@licaccess.cmc.ca`

Cross-reference: `environment/cadence-tools.md`

## Basic Invocation

Minimal batch form:

```bash
tcsh -c 'source /CMC/scripts/cadence.xceliummain25.09.001.csh && \
  xrun -64bit -access +rwc -timescale 1ns/1ps -l xrun.log rtl.v tb.v'
```

Observed on this machine:

- `xrun` is the unified compile + elaborate + simulate command
- the logfile flag is `-l <file>` in the installed help text
- `-timescale` matters in mixed-source cases; the tool failed elaboration when one module had no timescale and no default was supplied

Useful flags from the installed 25.09 help:

- `-64bit` - force the 64-bit executable
- `-access +rwc` - enable read/write/connectivity access for debug and waveform capture
- `-timescale 1ns/1ps` - set a default timescale on Verilog modules
- `-input <file>` - feed simulator TCL commands
- `-l <file>` - write the main xrun log
- `-clean` - delete a previous `xcelium.d/` work area before running

## Minimal Headless Testbench

Small Verilog example:

```verilog
`timescale 1ns/1ps

module tb;
  reg a, b;
  wire y;

  dut u_dut (.a(a), .b(b), .y(y));

  initial begin
    a = 0; b = 0; #5;
    a = 1; b = 0; #5;
    a = 0; b = 1; #5;
    a = 1; b = 1; #5;
    $finish;
  end
endmodule
```

For first success:

- give every Verilog source a timescale directive, or pass `-timescale`
- make the testbench self-terminating with `$finish`
- start with plain Verilog before adding UVM or mixed-language features

## Waveform Capture

Default batch runs create logs and `xcelium.d/`, but not a waveform database by themselves.

To generate an SHM database headlessly, pass a TCL file with `-input`:

```tcl
database -open waves -into waves.shm -default
probe -create -all -depth all
run
exit
```

Example:

```bash
tcsh -c 'source /CMC/scripts/cadence.xceliummain25.09.001.csh && \
  xrun -64bit -access +rwc -timescale 1ns/1ps \
    -input sim.tcl -l xrun.log rtl.v tb.v'
```

Observed output from a successful smoke run:

- `xrun.log`
- `xrun.history`
- `xcelium.d/`
- `waves.shm/` with `waves.dsn` and `waves.trn` when `-input` opens a database

## GPU-Flow Use

Use Xcelium in two places:

- RTL verification before synthesis
- gate-level simulation after DC or Genus emits a mapped netlist

Archive RTL to start from:

- `examples/alu4/alu4.v`

Later flow handoffs:

- synthesis inputs: RTL + testbench expectations
- synthesis outputs to re-simulate: mapped netlists from DC or Genus

## Gotchas

- Missing timescales can stop elaboration. In a verified smoke run, Xcelium raised `xmelab: *F,CUMSTS` until `-timescale 1ns/1ps` was added.
- The Xcelium setup wrapper does not itself print license status. If `xrun` fails immediately on licensing, check `CDS_LIC_FILE`.
- `-access +rwc` is useful for debug and probes, but it is not a substitute for opening a waveform database; use `-input` with `database` / `probe` commands when you need waves.
- Batch runs leave a persistent `xcelium.d/` work area. Use `-clean` when you want a fresh run.

There is no `recipes/vcs.md` yet. When it exists, treat VCS as the Synopsys alternative to the same simulation stage.
