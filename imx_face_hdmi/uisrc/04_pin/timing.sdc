create_clock -name {ddr_clk} -period 10.000 -waveform {0.000 5.000} [get_ports {I_ddr_clk}]
create_clock -name {clk_25m} -period 40.000 -waveform {0.000 20.000} [get_ports {I_sys_clk_25m}]
create_clock -name {S_hs_rx_clk} -period 6.000 -waveform {0.000 3.000} [get_pins {u_mipi_dphy_rx_ph1a_mipiio_wrapper/u_ph1a_mipiio_wrapper/u_PH1_PHY_MIPIIO.hsrx_byteclk_to_fabric}]

derive_clocks

rename_clock -name {pclkx1} [get_clocks {u_pll/pll_inst.clkc[0]}]
rename_clock -name {pclkx5} [get_clocks {u_pll/pll_inst.clkc[1]}]
rename_clock -name {cpu_clk_70m} [get_clocks {u_pll/pll_inst.clkc[2]}]
rename_clock -name {cam_clk_24m} [get_clocks {u_pll/pll_inst.clkc[3]}]

set_clock_groups -asynchronous -group [get_clocks {cam_clk_24m}] -group [get_clocks {cpu_clk_70m}] -group [get_clocks {pclkx1}] -group [get_clocks {pclkx5}] -group [get_clocks {S_hs_rx_clk}] -group [get_clocks {u_ddr_phy/dfi_clk}]
