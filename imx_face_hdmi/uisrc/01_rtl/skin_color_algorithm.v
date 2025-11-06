module skin_color_algorithm #(
	parameter  PARALLEL_NUM = 4        // 并行像素数（固定4，适配96bit）
)
(
	input   wire			i_clk,
	input   wire			i_rst_n,
	input	wire [PARALLEL_NUM-1:0][7:0]	i_rgb_r     ,
	input	wire [PARALLEL_NUM-1:0][7:0]  i_rgb_g     ,
	input	wire [PARALLEL_NUM-1:0][7:0]  i_rgb_b     ,
    input wire            i_last                           ,
    input wire            i_user                           ,
    input wire            i_valid                          ,
    
    output wire           o_last                           ,
    output wire           o_user                           ,
    output wire           o_valid                          ,
	output  wire [PARALLEL_NUM-1:0][7:0]    o_r     ,
	output  wire [PARALLEL_NUM-1:0][7:0]    o_g     ,
	output  wire [PARALLEL_NUM-1:0][7:0]    o_b      
);

// ycbcr0(:,:,1)  =  0.2568*image_in_r + 0.5041*image_in_g + 0.0979*image_in_b + 16; 
// ycbcr0(:,:,2)  = -0.1482*image_in_r - 0.2910*image_in_g + 0.4392*image_in_b + 128;
// ycbcr0(:,:,3)  =  0.4392*image_in_r - 0.3678*image_in_g - 0.0714*image_in_b + 128;

// ycbcr0(:,:,1)  = 256*( 0.2568*image_in_r + 0.5041*image_in_g + 0.0979*image_in_b + 16 )>>8; 
// ycbcr0(:,:,2)  = 256*(-0.1482*image_in_r - 0.2910*image_in_g + 0.4392*image_in_b + 128)>>8;
// ycbcr0(:,:,3)  = 256*( 0.4392*image_in_r - 0.3678*image_in_g - 0.0714*image_in_b + 128)>>8;

// ycbcr0(:,:,1)  = (66*image_in_r + 129*image_in_g + 25*image_in_b + 4096  )>>8; 
// ycbcr0(:,:,2)  = (-38*image_in_r - 74*image_in_g + 112*image_in_b + 32768)>>8;
// ycbcr0(:,:,3)  = (112*image_in_r - 94*image_in_g - 18*image_in_b + 32768 )>>8;
    parameter  CB_LOW       = 8'd77;     // Cb分量下限
    parameter  CB_HIGH      = 8'd127;    // Cb分量上限
    parameter  CR_LOW       = 8'd133;    // Cr分量下限
    parameter  CR_HIGH      = 8'd173;    // Cr分量上限


reg [PARALLEL_NUM-1:0][15:0] r_d0  ; 
reg [PARALLEL_NUM-1:0][15:0] g_d0  ; 
reg [PARALLEL_NUM-1:0][15:0] b_d0  ; 
 
reg [PARALLEL_NUM-1:0][15:0] r_d1  ; 
reg [PARALLEL_NUM-1:0][15:0] g_d1  ; 
reg [PARALLEL_NUM-1:0][15:0] b_d1  ; 
 
reg [PARALLEL_NUM-1:0][15:0] r_d2  ; 
reg [PARALLEL_NUM-1:0][15:0] g_d2  ; 
reg [PARALLEL_NUM-1:0][15:0] b_d2  ; 
 
reg [PARALLEL_NUM-1:0][15:0] y_d0  ; 
reg [PARALLEL_NUM-1:0][15:0] cb_d0 ; 
reg [PARALLEL_NUM-1:0][15:0] cr_d0 ; 

reg [PARALLEL_NUM-1:0][7:0] y_d1   ; 
reg [PARALLEL_NUM-1:0][7:0] cb_d1  ; 
reg [PARALLEL_NUM-1:0][7:0] cr_d1  ; 



reg [PARALLEL_NUM-1:0][7:0] skin_r ; 
reg [PARALLEL_NUM-1:0][7:0] skin_g ;
reg [PARALLEL_NUM-1:0][7:0] skin_b ;

// 生成循环，为每个并行像素创建处理逻辑
generate
    genvar i;
    for (i = 0; i < PARALLEL_NUM; i = i + 1) begin : skin_detect_core
        // 计算乘法项
        always @(posedge i_clk or negedge i_rst_n) begin
            if (!i_rst_n) begin
                r_d0[i] <= 16'd0;
                g_d0[i] <= 16'd0;
                b_d0[i] <= 16'd0;
                r_d1[i] <= 16'd0;
                g_d1[i] <= 16'd0;
                b_d1[i] <= 16'd0;
                r_d2[i] <= 16'd0;
                g_d2[i] <= 16'd0;
                b_d2[i] <= 16'd0;
            end else begin
                // 保留原模块的系数
                r_d0[i] <= 16'd66  * i_rgb_r[i];
                g_d0[i] <= 16'd129 * i_rgb_g[i];
                b_d0[i] <= 16'd25  * i_rgb_b[i];
                r_d1[i] <= 16'd38  * i_rgb_r[i];
                g_d1[i] <= 16'd74  * i_rgb_g[i];
                b_d1[i] <= 16'd112 * i_rgb_b[i];
                r_d2[i] <= 16'd112 * i_rgb_r[i];
                g_d2[i] <= 16'd94  * i_rgb_g[i];
                b_d2[i] <= 16'd18  * i_rgb_b[i];
            end
        end
        
        // 计算YCbCr中间值
        always @(posedge i_clk or negedge i_rst_n) begin
            if (!i_rst_n) begin
                y_d0[i]  <= 16'd0;
                cb_d0[i] <= 16'd0;
                cr_d0[i] <= 16'd0;
            end else begin
                // 保留原模块的加法项
                y_d0[i]  <= r_d0[i] + g_d0[i] + b_d0[i] + 16'd4096;
                cb_d0[i] <= (b_d1[i] - r_d1[i] - g_d1[i]) + 16'd32768;
                cr_d0[i] <= (r_d2[i] - g_d2[i] - b_d2[i]) + 16'd32768;
            end
        end

        // 获取最终YCbCr分量
        reg [15:0] y_mid;
        reg [15:0] cb_mid;
        reg [15:0] cr_mid;
        
        always @(posedge i_clk or negedge i_rst_n) begin
            if (!i_rst_n) begin
                y_mid <= 16'd0;
                cb_mid <= 16'd0;
                cr_mid <= 16'd0;
                y_d1[i]  <= 8'd0;
                cb_d1[i] <= 8'd0;
                cr_d1[i] <= 8'd0;
            end else begin
                // 中间变量处理
                y_mid <= y_d0[i];
                cb_mid <= cb_d0[i];
                cr_mid <= cr_d0[i];
                
                // 右移8位（取高8bit）
                y_d1[i]  <= y_mid[15:8];
                cb_d1[i] <= cb_mid[15:8];
                cr_d1[i] <= cr_mid[15:8];
            end
        end
        
        // 肤色判断
        always @(posedge i_clk or negedge i_rst_n) begin
            if (!i_rst_n) begin
                skin_r[i] <= 8'd0;
                skin_g[i] <= 8'd0;
                skin_b[i] <= 8'd0;
            end else if (cb_d1[i] > CB_LOW && cb_d1[i] < CB_HIGH && cr_d1[i] > CR_LOW && cr_d1[i] < CR_HIGH) begin
                // 肤色：输出白色
                skin_r[i] <= 8'd255;
                skin_g[i] <= 8'd255;
                skin_b[i] <= 8'd255;
            end else begin
                // 非肤色：输出黑色
                skin_r[i] <= 8'd0;
                skin_g[i] <= 8'd0;
                skin_b[i] <= 8'd0;
            end
        end
    end
endgenerate

// 时序信号延迟
reg [3:0] last_r;
reg [3:0] user_r;
reg [3:0] valid_r;

always@(posedge i_clk) 
begin
    last_r      <= {last_r[2:0], i_last};
    user_r      <= {user_r[2:0], i_user};
    valid_r     <= {valid_r[2:0], i_valid};
end

// 输出赋值
assign  o_last = last_r[3];
assign  o_user = user_r[3];
assign  o_valid = valid_r[3];

generate
    genvar j;
    for (j = 0; j < PARALLEL_NUM; j = j + 1) begin : out_rgb
        assign  o_r[j] = skin_r[j];
        assign  o_g[j] = skin_g[j];
        assign  o_b[j] = skin_b[j];
    end
endgenerate

endmodule

