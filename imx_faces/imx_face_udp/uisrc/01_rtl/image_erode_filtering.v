`timescale 1ns / 1ps
module image_erode_filtering #(
    parameter  PARALLEL_NUM = 4,         // 并行像素数（与膨胀模块一致）
    parameter  PIXEL_WIDTH_R  = 8,         // 单像素位宽（8bit）
    parameter  TOTAL_BIN_WIDTH = PARALLEL_NUM * PIXEL_WIDTH_R  // 输入/输出总位宽=32bit

)
(
	input   wire				i_clk,
	input   wire				i_rst_n,

    input   wire [TOTAL_BIN_WIDTH-1:0] i_binary,  // 32bit并行二值化输入（膨胀模块的o_r_data）
    input  wire           i_last                  ,
    input  wire           i_user                  ,
    input  wire           i_valid                 ,	
	
    output wire           o_last                  ,
    output wire           o_user                  ,
    output wire           o_valid                 ,

    output   [TOTAL_BIN_WIDTH-1:0] o_binary   ,  // 32bit并行输出：[bin3, bin2, bin1, bin0]
    output reg [PARALLEL_NUM-1:0]   o_bin_flag  // 4像素腐蚀标记（1=保留，0=腐蚀，可选）
);

// 第一步：拆分32bit并行输入为4组独立的8bit二值化数据
// 对应膨胀模块输出的o_r_data：[31:24]→第3像素，[23:16]→第2像素，[15:8]→第1像素，[7:0]→第0像素
wire [7:0] bin_data [PARALLEL_NUM-1:0];  // 4组独立二值化数据

assign bin_data[0] = i_binary[7:0];     // 第0像素：膨胀模块输出的最低8bit
assign bin_data[1] = i_binary[15:8];    // 第1像素：中间低8bit
assign bin_data[2] = i_binary[23:16];   // 第2像素：中间高8bit
assign bin_data[3] = i_binary[31:24];   // 第3像素：膨胀模块输出的最高8bit

// 第二步：generate循环生成4组3×3模板提取逻辑（每组对应1个并行像素）
wire [PARALLEL_NUM-1:0][7:0] r_temp_11 ;
wire [PARALLEL_NUM-1:0][7:0] r_temp_12 ;
wire [PARALLEL_NUM-1:0][7:0] r_temp_13 ;
wire [PARALLEL_NUM-1:0][7:0] r_temp_21 ;
wire [PARALLEL_NUM-1:0][7:0] r_temp_22 ;
wire [PARALLEL_NUM-1:0][7:0] r_temp_23 ;
wire [PARALLEL_NUM-1:0][7:0] r_temp_31 ;
wire [PARALLEL_NUM-1:0][7:0] r_temp_32 ;
wire [PARALLEL_NUM-1:0][7:0] r_temp_33 ;


reg [3:0]  erode_and;
generate
    genvar i;
    for (i = 0; i < PARALLEL_NUM; i = i + 1) begin : template_core
        
        image_template u_r_template (
            .i_clk      (i_clk),
            .i_rst_n    (i_rst_n),
            .i_en       (i_valid),                  // 共享数据有效信号（与膨胀模块同步）
            .i_data     (bin_data[i]),           // 输入拆分后的第i个像素二值化数据
            .o_en       ()           ,
            // 3×3窗口模板输出（对应当前像素的局部窗口）
            .o_temp_11  (r_temp_11[i]),
            .o_temp_12  (r_temp_12[i]),
            .o_temp_13  (r_temp_13[i]),
            .o_temp_21  (r_temp_21[i]),
            .o_temp_22  (r_temp_22[i]),
            .o_temp_23  (r_temp_23[i]),
            .o_temp_31  (r_temp_31[i]),
            .o_temp_32  (r_temp_32[i]),
            .o_temp_33  (r_temp_33[i])
        );

        wire [7:0] temp_inmed_11;//中间变量
        wire [7:0] temp_inmed_12;//中间变量
        wire [7:0] temp_inmed_13;//中间变量
        wire [7:0] temp_inmed_21;//中间变量
        wire [7:0] temp_inmed_22;//中间变量
        wire [7:0] temp_inmed_23;//中间变量
        wire [7:0] temp_inmed_31;//中间变量
        wire [7:0] temp_inmed_32;//中间变量
        wire [7:0] temp_inmed_33;//中间变量
            

        assign temp_inmed_11 = r_temp_11[i]  ;
        assign temp_inmed_12 = r_temp_12[i]  ;
        assign temp_inmed_13 = r_temp_13[i]  ;
        assign temp_inmed_21 = r_temp_21[i]  ;
        assign temp_inmed_22 = r_temp_22[i]  ;
        assign temp_inmed_23 = r_temp_23[i]  ;
        assign temp_inmed_31 = r_temp_31[i]  ;
        assign temp_inmed_32 = r_temp_32[i]  ;
        assign temp_inmed_33 = r_temp_33[i]  ;        

        always @(posedge i_clk or negedge i_rst_n) begin
            if (!i_rst_n) 
                erode_and[i] <= 1'b0;
            else begin
                erode_and[i] <= (temp_inmed_11[0] && temp_inmed_12[0] && temp_inmed_13[0]&&
                                temp_inmed_21[0] && temp_inmed_22[0] && temp_inmed_23[0] &&
                                temp_inmed_31[0] && temp_inmed_32[0] && temp_inmed_33[0]);
            end

        end

    end


endgenerate





     reg [TOTAL_BIN_WIDTH-1:0]      binary_reg ; //[bin3, bin2, bin1, bin0]

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        binary_reg <= {TOTAL_BIN_WIDTH{1'b0}};
        o_bin_flag <= {PARALLEL_NUM{1'b0}};
    end else begin
        binary_reg[7:0]     <= erode_and[0] ? 8'd255 : 8'd0;  // 第0像素（最低8bit）
        binary_reg[15:8]    <= erode_and[1] ? 8'd255 : 8'd0;  // 第1像素（中间低8bit）
        binary_reg[23:16]   <= erode_and[2] ? 8'd255 : 8'd0;  // 第2像素（中间高8bit）
        binary_reg[31:24]   <= erode_and[3] ? 8'd255 : 8'd0;  // 第3像素（最高8bit）
        
        // 腐蚀标记
        o_bin_flag <= erode_and;
    end
end


reg	[2:0]	last_r ;
reg	[2:0]	user_r ;
reg	[2:0]	valid_r;

always@(posedge i_clk ) 
begin
    last_r      <= {last_r[1:0],i_last};           
    user_r      <= {user_r[1:0],i_user};
    valid_r     <= {valid_r[1:0],i_valid};
end

assign  o_last = last_r[2];
assign  o_user = user_r[2];
assign  o_valid = valid_r[2];

assign o_binary	= binary_reg;

endmodule


/*

*/