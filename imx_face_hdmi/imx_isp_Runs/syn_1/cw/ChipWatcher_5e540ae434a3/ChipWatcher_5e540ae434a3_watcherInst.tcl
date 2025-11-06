source "D:/TD/cw/atpl/templa.tcl"
set fd [open "D:/TD/cw/atpl/cwc_ip.atpl" r]
set tmpl [read $fd]
close $fd
set parser [::tmpl_parser::tmpl_parser $tmpl]

set ComponentName        ChipWatcher_5e540ae434a3
set bus_num              3
set depth                1024
set ram_len              17
set input_pipe_num       0
set output_pipe_num      0
set capture_ctrl_exist   1
set trig_bus_num         3
set trig_bus_din_num     17
set trig_bus_ctrl_len    60
set trig_ctrl_len        142
set trig_bus_width       { 8,8,1 };
set trig_bus_din_pos     { 0,8,16 };
set trig_bus_ctrl_pos    { 0,28,56 };
set bus_size             {  1 8 8 }
set data_enable          { probe0 probe1 probe2 }
set trig_enable          { probe0 probe1 probe2 }
set fp [open "cw/ChipWatcher_5e540ae434a3/ChipWatcher_5e540ae434a3_watcherInst.sv" w+]
puts $fp [eval $parser]
close $fp
