source "D:/TD/cw/atpl/templa.tcl"
set fd [open "D:/TD/cw/atpl/cwc.atpl" r]
set tmpl [read $fd]
close $fd
set parser [::tmpl_parser::tmpl_parser $tmpl]

set ComponentName        auto_created_cwc1
set bus_num              61
set cwc_ctrl_len         1578
set cwc_bus_ctrl_len     1558
set bus_din_num          452
set ram_len              452
set input_pipe_num       0
set output_pipe_num      0
set depth                1024
set capture_ctrl_exist   0
set bus_width            { 11,11,11,11,11,11,11,11,11,16,11,11,11,11,11,11,11,11,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,11,1,1,1,1,1,1,1,1,1,1,1,1,1,1 };
set bus_din_pos          { 0,11,22,33,44,55,66,77,88,99,115,126,137,148,159,170,181,192,203,211,219,227,235,243,251,259,267,275,283,291,299,307,315,323,331,339,347,355,363,371,379,387,395,403,411,419,427,438,439,440,441,442,443,444,445,446,447,448,449,450,451 };
set bus_ctrl_pos         { 0,37,74,111,148,185,222,259,296,333,385,422,459,496,533,570,607,644,681,709,737,765,793,821,849,877,905,933,961,989,1017,1045,1073,1101,1129,1157,1185,1213,1241,1269,1297,1325,1353,1381,1409,1437,1465,1502,1506,1510,1514,1518,1522,1526,1530,1534,1538,1542,1546,1550,1554 };
set fp [open "cw/auto_created_cwc1/auto_created_cwc1_watcherInst.sv" w+]
puts $fp [eval $parser]
close $fp
