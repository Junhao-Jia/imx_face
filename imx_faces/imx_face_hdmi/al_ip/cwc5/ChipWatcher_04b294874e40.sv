     
module ChipWatcher_04b294874e40 ( 
    input [0:0] probe0, 
    input [0:0] probe1, 
    input [0:0] probe2, 
    input [8:0] probe3, 
    input [8:0] probe4, 
    input [15:0] probe5, 
    input [0:0] probe6, 
    input [15:0] probe7, 
    input [0:0] probe8, 
    input [0:0] probe9, 
    input [0:0] probe10, 
    input [0:0] probe11, 
    input [15:0] probe12, 
    input [0:0] probe13, 
    input [0:0] probe14, 
    input [7:0] probe15, 
    input [8:0] probe16, 
    input [15:0] probe17, 
    input [15:0] probe18, 
    input [0:0] probe19, 
    input [0:0] probe20, 
    input [0:0] probe21, 
    input [3:0] probe22, 
    input [15:0] probe23, 
    input [0:0] probe24, 
    input [3:0] probe25, 
    input [0:0] probe26, 
    input [8:0] probe27, 
    input [15:0] probe28, 
    input [30:0] probe29, 
    input [0:0] probe30, 
    input [15:0] probe31, 
    input [0:0] probe32, 
    input [255:0] probe33, 
    input [0:0] probe34, 
    input [0:0] probe35, 
    input [30:0] probe36, 
    input [0:0] probe37, 
    input [15:0] probe38, 
    input [0:0] probe39, 
    input [255:0] probe40, 
    input [0:0] probe41, 
    input [0:0] probe42, 
    input       clk  
); 
    localparam CWC_BUS_NUM = 43;
    localparam CWC_BUS_DIN_NUM = 793;
    localparam INPUT_PIPE_NUM = 0;
    localparam OUTPUT_PIPE_NUM = 0;
    localparam RAM_LEN = 793;
    localparam RAM_DATA_DEPTH = 4096;

    
    localparam integer CWC_BUS_WIDTH[0:CWC_BUS_NUM-1] = {1,1,256,1,16,1,31,1,1,256,1,16,1,31,16,9,1,4,1,16,4,1,1,1,16,16,9,8,1,1,16,1,1,1,1,16,1,16,9,9,1,1,1};
    localparam integer CWC_BUS_DIN_POS[0:CWC_BUS_NUM-1] = {0,1,2,258,259,275,276,307,308,309,565,566,582,583,614,630,639,640,644,645,661,665,666,667,668,684,700,709,717,718,719,735,736,737,738,739,755,756,772,781,790,791,792};    
    localparam integer CWC_BUS_CTRL_POS[0:CWC_BUS_NUM-1] = {0,6,12,528,534,570,576,642,648,654,1170,1176,1212,1218,1284,1320,1342,1348,1360,1366,1402,1414,1420,1426,1432,1468,1504,1526,1546,1552,1558,1594,1600,1606,1612,1618,1654,1660,1696,1718,1740,1746,1752};    

    parameter STAT_REG_LEN = 24;
    parameter BUS_CTRL_NUM = CWC_BUS_NUM*4 + CWC_BUS_DIN_NUM*2 + 36;

    wire                     cwc_rst;
    wire [BUS_CTRL_NUM-1:0]  cwc_control;
    wire [STAT_REG_LEN-1:0]  cwc_status;  

	top_cwc_hub #(
		.CWC_BUS_NUM(CWC_BUS_NUM),
		.CWC_BUS_DIN_NUM(CWC_BUS_DIN_NUM),
		.CWC_BUS_WIDTH(CWC_BUS_WIDTH),
		.CWC_BUS_DIN_POS(CWC_BUS_DIN_POS),
		.CWC_BUS_CTRL_POS(CWC_BUS_CTRL_POS),
		.RAM_DATA_DEPTH(RAM_DATA_DEPTH),
		.RAM_LEN(RAM_LEN),
		.INPUT_PIPE_NUM(INPUT_PIPE_NUM),
		.OUTPUT_PIPE_NUM(OUTPUT_PIPE_NUM)
	)

	 wrapper_cwc_top(
		.cwc_trig_clk(clk),
		.cwc_control(cwc_control),
		.cwc_status(cwc_status),
		.cwc_rst(cwc_rst),
		.cwc_bus_din({probe0,probe1,probe2,probe3,probe4,probe5,probe6,probe7,probe8,probe9,probe10,probe11,probe12,probe13,probe14,probe15,probe16,probe17,probe18,probe19,probe20,probe21,probe22,probe23,probe24,probe25,probe26,probe27,probe28,probe29,probe30,probe31,probe32,probe33,probe34,probe35,probe36,probe37,probe38,probe39,probe40,probe41,probe42}),
		.ram_data_din({probe0,probe1,probe2,probe3,probe4,probe5,probe6,probe7,probe8,probe9,probe10,probe11,probe12,probe13,probe14,probe15,probe16,probe17,probe18,probe19,probe20,probe21,probe22,probe23,probe24,probe25,probe26,probe27,probe28,probe29,probe30,probe31,probe32,probe33,probe34,probe35,probe36,probe37,probe38,probe39,probe40,probe41,probe42})
	);

    AL_LOGIC_DEBUGHUB #(
		.CTRL_LEN(BUS_CTRL_NUM),
		.STAT_LEN(STAT_REG_LEN)
	) wrapper_debughub(
		.clk(clk),
		.control(cwc_control),
		.status(cwc_status),
		.rst(cwc_rst)
	);

endmodule


