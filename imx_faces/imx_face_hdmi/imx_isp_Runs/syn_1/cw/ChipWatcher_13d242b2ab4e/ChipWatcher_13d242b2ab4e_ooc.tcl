import_device ph1_180.db -package PH1A180SFG676
set_param flow ooc_flow on
read_verilog -file "ChipWatcher_13d242b2ab4e_watcherInst.sv"
optimize_rtl
map_macro
map
pack
report_area -file ChipWatcher_13d242b2ab4e_gate.area
export_db -mode ooc "ChipWatcher_13d242b2ab4e_ooc.db"
