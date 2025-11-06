source "D:/TD/cw/atpl/templa.tcl"
set fd [open "D:/TD/cw/atpl/cwc.atpl" r]
set tmpl [read $fd]
close $fd
set parser [::tmpl_parser::tmpl_parser $tmpl]

set ComponentName        auto_created_cwc1
set bus_num              68
set cwc_ctrl_len         1702
set cwc_bus_ctrl_len     1682
set bus_din_num          489
set ram_len              489
set input_pipe_num       0
set output_pipe_num      0
set depth                1024
set capture_ctrl_exist   0
set bus_width            { 16,16,11,11,11,11,11,11,11,11,11,16,11,11,11,11,11,11,11,11,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,11,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 };
set bus_din_pos          { 0,16,32,43,54,65,76,87,98,109,120,131,147,158,169,180,191,202,213,224,235,243,251,259,267,275,283,291,299,307,315,323,331,339,347,355,363,371,379,387,395,403,411,419,427,435,443,451,459,470,471,472,473,474,475,476,477,478,479,480,481,482,483,484,485,486,487,488 };
set bus_ctrl_pos         { 0,52,104,141,178,215,252,289,326,363,400,437,489,526,563,600,637,674,711,748,785,813,841,869,897,925,953,981,1009,1037,1065,1093,1121,1149,1177,1205,1233,1261,1289,1317,1345,1373,1401,1429,1457,1485,1513,1541,1569,1606,1610,1614,1618,1622,1626,1630,1634,1638,1642,1646,1650,1654,1658,1662,1666,1670,1674,1678 };
set fp [open "cw/auto_created_cwc1/auto_created_cwc1_watcherInst.sv" w+]
puts $fp [eval $parser]
close $fp
