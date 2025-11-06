source "D:/TD/cw/atpl/templa.tcl"
set fd [open "D:/TD/cw/atpl/cwc.atpl" r]
set tmpl [read $fd]
close $fd
set parser [::tmpl_parser::tmpl_parser $tmpl]

set ComponentName        auto_created_cwc3
set bus_num              4
set cwc_ctrl_len         132
set cwc_bus_ctrl_len     112
set bus_din_num          34
set ram_len              34
set input_pipe_num       0
set output_pipe_num      0
set depth                1024
set capture_ctrl_exist   0
set bus_width            { 16,16,1,1 };
set bus_din_pos          { 0,16,32,33 };
set bus_ctrl_pos         { 0,52,104,108 };
set fp [open "cw/auto_created_cwc3/auto_created_cwc3_watcherInst.sv" w+]
puts $fp [eval $parser]
close $fp
