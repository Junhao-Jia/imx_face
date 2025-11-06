source "D:/TD/cw/atpl/templa.tcl"
set fd [open "D:/TD/cw/atpl/cwc_ip.atpl" r]
set tmpl [read $fd]
close $fd
set parser [::tmpl_parser::tmpl_parser $tmpl]

set ComponentName        ChipWatcher_8ea1df140bd0
set bus_num              7
set depth                2048
set ram_len              64
set input_pipe_num       0
set output_pipe_num      0
set capture_ctrl_exist   1
set trig_bus_num         7
set trig_bus_din_num     64
set trig_bus_ctrl_len    220
set trig_ctrl_len        462
set trig_bus_width       { 10,10,10,10,10,10,4 };
set trig_bus_din_pos     { 0,10,20,30,40,50,60 };
set trig_bus_ctrl_pos    { 0,34,68,102,136,170,204 };
set bus_size             {  4 10 10 10 10 10 10 }
set data_enable          { probe0 probe1 probe2 probe3 probe4 probe5 probe6 }
set trig_enable          { probe0 probe1 probe2 probe3 probe4 probe5 probe6 }
set fp [open "cw/ChipWatcher_8ea1df140bd0/ChipWatcher_8ea1df140bd0_watcherInst.sv" w+]
puts $fp [eval $parser]
close $fp
