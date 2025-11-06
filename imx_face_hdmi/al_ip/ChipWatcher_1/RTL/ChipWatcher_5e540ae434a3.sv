// synthesis syn_black_box 
module ChipWatcher_5e540ae434a3 ( 
    input [0:0] probe0, 
    input [7:0] probe1, 
    input [7:0] probe2, 
    input       clk  
);
    localparam string IP_TYPE  = "ChipWatcher";
    localparam CWC_BUS_NUM     = 3;
    localparam INPUT_PIPE_NUM  = 0;
    localparam OUTPUT_PIPE_NUM = 0;
    localparam RAM_DATA_DEPTH  = 1024;
    localparam CAPTURE_CONTROL = 1;

    localparam integer CWC_BUS_WIDTH   [CWC_BUS_NUM-1:0] = {1,8,8};
    localparam integer CWC_DATA_ENABLE [CWC_BUS_NUM-1:0] = {1,1,1};    
    localparam integer CWC_TRIG_ENABLE [CWC_BUS_NUM-1:0] = {1,1,1};    
endmodule



