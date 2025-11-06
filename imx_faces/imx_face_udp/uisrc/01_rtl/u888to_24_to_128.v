module u888to_24_to_128#(   
        parameter  PARALLEL_NUM = 4 ,       // 并行像素数（固定4，适配96bit）
        parameter  PIXEL_WIDTH  = 32        // 单像素位宽（RGB888=24bit）+a=32
)
(  // input  wire [PARALLEL_NUM-1:0][7:0] i_rgb_a      ,
    input  wire [PARALLEL_NUM-1:0][7:0] i_rgb_r      ,
    input  wire [PARALLEL_NUM-1:0][7:0] i_rgb_g      ,
    input  wire [PARALLEL_NUM-1:0][7:0] i_rgb_b      ,

    output wire [127:0]       o_tdata              
 );

wire [95:0]  data_rgb;

assign data_rgb[95:72] =   {i_rgb_r[3],i_rgb_g[3],i_rgb_b[3]};
assign data_rgb[71:48] =   {i_rgb_r[2],i_rgb_g[2],i_rgb_b[2]};
assign data_rgb[47:24] =   {i_rgb_r[1],i_rgb_g[1],i_rgb_b[1]};
assign data_rgb[23:0]  =   {i_rgb_r[0],i_rgb_g[0],i_rgb_b[0]};


assign o_tdata ={
                    {8'd0},data_rgb[95:72],{8'd0},data_rgb[71:48],{8'd0},data_rgb[47:24],
                    {8'd0},data_rgb[23:0]
} ;





endmodule
