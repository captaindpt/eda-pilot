set_units -time ns

# Constrain the combinational alu4 block against a virtual 100 MHz boundary.
create_clock -name virt_clk -period 10.0

set_input_transition 0.05 [all_inputs]
set_load 0.01 [all_outputs]

set_input_delay 1.0 -clock virt_clk [all_inputs]
set_output_delay 1.0 -clock virt_clk [all_outputs]
set_max_delay 8.0 -from [all_inputs] -to [all_outputs]
set_min_delay 0.0 -from [all_inputs] -to [all_outputs]
