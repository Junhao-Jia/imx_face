source "D:/TD/cw/atpl/templa.tcl"
set fd [open "D:/TD/cw/atpl/cwc.atpl" r]
set tmpl [read $fd]
close $fd
set parser [::tmpl_parser::tmpl_parser $tmpl]

set ComponentName        auto_created_cwc2
set bus_num              13
set cwc_ctrl_len         264
set cwc_bus_ctrl_len     244
set bus_din_num          69
set ram_len              69
set input_pipe_num       0
set output_pipe_num      0
set depth                1024
set capture_ctrl_exist   0
set bus_width            { 6,11,16,2,2,9,16,2,1,1,1,1,1 };
set bus_din_pos          { 0,6,17,33,35,37,46,62,64,65,66,67,68 };
set bus_ctrl_pos         { 0,22,59,111,121,131,162,214,224,228,232,236,240 };
set fp [open "cw/auto_created_cwc2/auto_created_cwc2_watcherInst.sv" w+]
puts $fp [eval $parser]
close $fp
