set_units -time ns

create_clock -name counter_clk -period 5.0 [get_ports clk]
set_clock_uncertainty 0.05 [get_clocks counter_clk]
set_clock_transition 0.05 [get_clocks counter_clk]

set_input_transition 0.05 [remove_from_collection [all_inputs] [get_ports clk]]
set_driving_cell -lib_cell BUFX2 [remove_from_collection [all_inputs] [get_ports clk]]
set_load 0.02 [all_outputs]

set_input_delay 0.30 -clock counter_clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 0.30 -clock counter_clk [all_outputs]
