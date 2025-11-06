module auto_created_cwc1 (  
    cwc_rst, cwc_control, cwc_status, cwc_trig_clk, cwc_bus_din, ram_data_din
);

    localparam CWC_BUS_NUM = 61;
    localparam CWC_BUS_DIN_NUM = 452;
	localparam CWC_CTRL_LEN = 1578;
	localparam CWC_BUS_CTRL_LEN = 1558;
    localparam RAM_LEN = 452;
    localparam INPUT_PIPE_NUM = 0;
    localparam OUTPUT_PIPE_NUM = 0;
    localparam RAM_DATA_DEPTH = 1024;
	localparam CWC_CAPTURE_CTRL_EXIST = 0;
    localparam integer CWC_BUS_WIDTH[0:60] = {11,11,11,11,11,11,11,11,11,16,11,11,11,11,11,11,11,11,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,11,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
    localparam integer CWC_BUS_DIN_POS[0:60] = {0,11,22,33,44,55,66,77,88,99,115,126,137,148,159,170,181,192,203,211,219,227,235,243,251,259,267,275,283,291,299,307,315,323,331,339,347,355,363,371,379,387,395,403,411,419,427,438,439,440,441,442,443,444,445,446,447,448,449,450,451};    
    localparam integer CWC_BUS_CTRL_POS[0:60] = {0,37,74,111,148,185,222,259,296,333,385,422,459,496,533,570,607,644,681,709,737,765,793,821,849,877,905,933,961,989,1017,1045,1073,1101,1129,1157,1185,1213,1241,1269,1297,1325,1353,1381,1409,1437,1465,1502,1506,1510,1514,1518,1522,1526,1530,1534,1538,1542,1546,1550,1554};    

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


