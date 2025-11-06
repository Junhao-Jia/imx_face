module auto_created_cwc1 (  
    cwc_rst, cwc_control, cwc_status, cwc_trig_clk, cwc_bus_din, ram_data_din
);

    localparam CWC_BUS_NUM = 68;
    localparam CWC_BUS_DIN_NUM = 489;
	localparam CWC_CTRL_LEN = 1702;
	localparam CWC_BUS_CTRL_LEN = 1682;
    localparam RAM_LEN = 489;
    localparam INPUT_PIPE_NUM = 0;
    localparam OUTPUT_PIPE_NUM = 0;
    localparam RAM_DATA_DEPTH = 1024;
	localparam CWC_CAPTURE_CTRL_EXIST = 0;
    localparam integer CWC_BUS_WIDTH[0:67] = {16,16,11,11,11,11,11,11,11,11,11,16,11,11,11,11,11,11,11,11,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,11,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
    localparam integer CWC_BUS_DIN_POS[0:67] = {0,16,32,43,54,65,76,87,98,109,120,131,147,158,169,180,191,202,213,224,235,243,251,259,267,275,283,291,299,307,315,323,331,339,347,355,363,371,379,387,395,403,411,419,427,435,443,451,459,470,471,472,473,474,475,476,477,478,479,480,481,482,483,484,485,486,487,488};    
    localparam integer CWC_BUS_CTRL_POS[0:67] = {0,52,104,141,178,215,252,289,326,363,400,437,489,526,563,600,637,674,711,748,785,813,841,869,897,925,953,981,1009,1037,1065,1093,1121,1149,1177,1205,1233,1261,1289,1317,1345,1373,1401,1429,1457,1485,1513,1541,1569,1606,1610,1614,1618,1622,1626,1630,1634,1638,1642,1646,1650,1654,1658,1662,1666,1670,1674,1678};    

    input                                            cwc_rst;       
    input  [CWC_CTRL_LEN-1:0]                        cwc_control;   
    output [23:0]                                    cwc_status;    //cwc status register 
    input                                            cwc_trig_clk;  //cwc trigger clock
    input  [CWC_BUS_DIN_NUM-1:0]                     cwc_bus_din;   //cwc trigger bus input
    input  [RAM_LEN-1:0]                             ram_data_din;

	top_cwc_hub #(
		.CWC_BUS_NUM(CWC_BUS_NUM),
		.CWC_BUS_DIN_NUM(CWC_BUS_DIN_NUM),
		.CWC_CTRL_LEN(CWC_CTRL_LEN),
		.CWC_BUS_CTRL_LEN(CWC_BUS_CTRL_LEN),
		.CWC_BUS_WIDTH(CWC_BUS_WIDTH),
		.CWC_BUS_DIN_POS(CWC_BUS_DIN_POS),
		.CWC_BUS_CTRL_POS(CWC_BUS_CTRL_POS),
		.RAM_DATA_DEPTH(RAM_DATA_DEPTH),
		.CWC_CAPTURE_CTRL_EXIST(CWC_CAPTURE_CTRL_EXIST),
		.RAM_LEN(RAM_LEN),  
        .INPUT_PIPE_NUM(INPUT_PIPE_NUM),
		.OUTPUT_PIPE_NUM(OUTPUT_PIPE_NUM)
	)

	wrapper_cwc_top(
		.cwc_trig_clk(cwc_trig_clk),
		.cwc_control(cwc_control),
		.cwc_status(cwc_status),
		.cwc_rst(cwc_rst),
		.cwc_bus_din(cwc_bus_din),
		.ram_data_din(ram_data_din)
	);

endmodule


