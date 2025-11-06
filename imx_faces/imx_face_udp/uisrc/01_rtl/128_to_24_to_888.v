module u128_to_24_to_888 #(   
        parameter  PARALLEL_NUM = 4 ,       // 并行像素数（固定4，适配96bit）
        parameter  PIXEL_WIDTH  = 32        // 单像素位宽（RGB888=24bit）+a=32
)
(   input   wire  [127:0]       i_tdata             ,
    output  wire [PARALLEL_NUM-1:0][7:0] o_rgb_a      ,
    output  wire [PARALLEL_NUM-1:0][7:0] o_rgb_r      ,
    output  wire [PARALLEL_NUM-1:0][7:0] o_rgb_g      ,
    output  wire [PARALLEL_NUM-1:0][7:0] o_rgb_b 
 );
generate
    genvar i;  // 循环变量（i=0~3，对应4个并行像素）
    for (i = 0; i < PARALLEL_NUM; i = i + 1) begin : pixel_split
        assign o_rgb_a[i] = i_tdata[(i * PIXEL_WIDTH) + 31 : (i * PIXEL_WIDTH) + 24];
        assign o_rgb_r[i] = i_tdata[(i * PIXEL_WIDTH) + 23 : (i * PIXEL_WIDTH) + 16];  // 第i个像素的R分量：对应i_tdata的 [i*24 + 23 : i*24 + 16] 
        assign o_rgb_g[i] = i_tdata[(i * PIXEL_WIDTH) + 15 : (i * PIXEL_WIDTH) + 8];   // 第i个像素的G分量：对应i_tdata的 [i*24 + 15 : i*24 + 8]
        assign o_rgb_b[i] = i_tdata[(i * PIXEL_WIDTH) + 7 : (i * PIXEL_WIDTH) + 0];    // 第i个像素的B分量：对应i_tdata的 [i*24 + 7 : i*24 + 0]
    end
endgenerate


endmodule
