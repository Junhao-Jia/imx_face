import_device ph1_180.db -package PH1A180SFG676
set_param flow ooc_flow on
read_verilog -file "ChipWatcher_8ea1df140bd0_watcherInst.sv"
optimize_rtl
map_macro
map
pack
report_area -file ChipWatcher_8ea1df140bd0_gate.area
export_db -mode ooc "ChipWatcher_8ea1df140bd0_ooc.db"
