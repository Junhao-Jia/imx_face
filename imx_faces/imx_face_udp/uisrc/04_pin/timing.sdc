create_clock -name {ddr_clk} -period 10.000 -waveform {0.000 5.000} [get_ports {I_ddr_clk}]
create_clock -name {clk_25m} -period 40.000 -waveform {0.000 20.000} [get_ports {I_sys_clk_25m}]
create_clock -name {S_hs_rx_clk} -period 6.000 -waveform {0.000 3.000} [get_pins {u_mipi_dphy_rx_ph1a_mipiio_wrapper/u_ph1a_mipiio_wrapper/u_PH1_PHY_MIPIIO.hsrx_byteclk_to_fabric}]

derive_clocks

rename_clock -name {a_tx_clk} [get_clocks {u_pll/pll_inst.clkc[0]}]
rename_clock -name {cpu_clk_70m} [get_clocks {u_pll/pll_inst.clkc[2]}]
rename_clock -name {cam_clk_24m} [get_clocks {u_pll/pll_inst.clkc[3]}]
rename_clock -name {cam_clk_35m} [get_clocks {u_pll/pll_inst.clkc[4]}]

set_clock_groups -asynchronous -group [get_clocks { cam_clk_35m }] -group [get_clocks {cam_clk_24m}] -group [get_clocks {cpu_clk_70m}] -group [get_clocks {S_hs_rx_clk}] -group [get_clocks {u_ddr_phy/dfi_clk}] -group [get_clocks {a_tx_clk}]

create_clock -name rx_clk -period 8.000 -waveform {0.000 4.000} [get_nets {rgmii_interface_inst/gmii_rx_clk}]
create_clock -name {I_rx_clk} -period 8.000 -waveform {0.000 4.000} [get_ports {I_a_rgmii_rxc}]
set_input_delay -clock [get_clocks I_rx_clk] -max 2.800 [get_ports {{I_a_rgmii_rxd[*]} I_a_rgmii_rx_ctl}]
set_input_delay -clock [get_clocks I_rx_clk] -min 1.200 [get_ports {{I_a_rgmii_rxd[*]} I_a_rgmii_rx_ctl}]
set_input_delay -clock [get_clocks I_rx_clk] -max -clock_fall -add_delay 2.800 [get_ports {{I_a_rgmii_rxd[*]} I_a_rgmii_rx_ctl}]
set_input_delay -clock [get_clocks I_rx_clk] -min -clock_fall -add_delay 1.200 [get_ports {{I_a_rgmii_rxd[*]} I_a_rgmii_rx_ctl}]

set_false_path -setup -rise_from [get_clocks I_rx_clk] -fall_to [get_clocks rx_clk]
set_false_path -setup -fall_from [get_clocks I_rx_clk] -rise_to [get_clocks rx_clk]
set_false_path -hold -rise_from [get_clocks I_rx_clk] -rise_to [get_clocks rx_clk]
set_false_path -hold -fall_from [get_clocks I_rx_clk] -fall_to [get_clocks rx_clk]

 
create_generated_clock -name {O_a_tx_clk} -source [get_pins {u_pll/pll_inst.clkc[0]}] -master_clock {a_tx_clk} -multiply_by 1.000 -duty_cycle 50.000 -phase 0.000 [get_ports {O_a_rgmii_txc}]
 
set_output_delay -clock [get_clocks O_a_tx_clk] -max -0.800 [get_ports {O_a_rgmii_tx_ctl {O_a_rgmii_txd[*]}}]
set_output_delay -clock [get_clocks O_a_tx_clk] -min -2.700 [get_ports {O_a_rgmii_tx_ctl {O_a_rgmii_txd[*]}}]
set_output_delay -clock [get_clocks O_a_tx_clk] -max -clock_fall -add_delay -0.800 [get_ports {O_a_rgmii_tx_ctl {O_a_rgmii_txd[*]}}]
set_output_delay -clock [get_clocks O_a_tx_clk] -min -clock_fall -add_delay -2.700 [get_ports {O_a_rgmii_tx_ctl {O_a_rgmii_txd[*]}}]
 
set_false_path -setup -rise_from [get_clocks a_tx_clk] -fall_to [get_clocks O_a_tx_clk]
set_false_path -setup -fall_from [get_clocks a_tx_clk] -rise_to [get_clocks O_a_tx_clk]
set_false_path -hold -rise_from [get_clocks a_tx_clk] -rise_to [get_clocks O_a_tx_clk]
set_false_path -hold -fall_from [get_clocks a_tx_clk] -fall_to [get_clocks O_a_tx_clk]
 
set_clock_groups -exclusive -group [get_clocks {I_rx_clk rx_clk}] -group [get_clocks { a_tx_clk O_a_tx_clk }]
 
