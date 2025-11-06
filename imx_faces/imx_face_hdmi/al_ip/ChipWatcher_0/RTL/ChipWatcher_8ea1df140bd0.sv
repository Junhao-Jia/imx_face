// synthesis syn_black_box 
module ChipWatcher_8ea1df140bd0 ( 
    input [3:0] probe0, 
    input [9:0] probe1, 
    input [9:0] probe2, 
    input [9:0] probe3, 
    input [9:0] probe4, 
    input [9:0] probe5, 
    input [9:0] probe6, 
    input       clk  
);
    localparam string IP_TYPE  = "ChipWatcher";
    localparam CWC_BUS_NUM     = 7;
    localparam INPUT_PIPE_NUM  = 0;
    localparam OUTPUT_PIPE_NUM = 0;
    localparam RAM_DATA_DEPTH  = 2048;
    localparam CAPTURE_CONTROL = 1;

    localparam integer CWC_BUS_WIDTH   [CWC_BUS_NUM-1:0] = {4,10,10,10,10,10,10};
    localparam integer CWC_DATA_ENABLE [CWC_BUS_NUM-1:0] = {1,1,1,1,1,1,1};    
    localparam integer CWC_TRIG_ENABLE [CWC_BUS_NUM-1:0] = {1,1,1,1,1,1,1};    
endmodule



