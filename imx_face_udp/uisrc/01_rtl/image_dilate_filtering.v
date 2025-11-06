module image_dilate_filtering #
(   parameter  PARALLEL_NUM = 4,         // 并行像素数（与肤色模块一致）
    parameter  PIXEL_WIDTH_R  = 8,         // 单分量位宽（8bit）
    parameter  TOTAL_R_WIDTH = PARALLEL_NUM * PIXEL_WIDTH_R
)     
(
	input   wire				i_clk,
	input   wire				i_rst_n,
    input  	wire [PARALLEL_NUM-1:0][7:0]  i_r,  // 4组R分量（仅用此做膨胀）
    input  wire           i_last                  ,
    input  wire           i_user                  ,
    input  wire           i_valid                 ,	
	
    output wire           o_last                  ,
    output wire           o_user                  ,
    output wire           o_valid                 ,

    output reg [TOTAL_R_WIDTH-1:0]  o_r_data,    // 32bit并行R分量：[R3, R2, R1, R0]
	output reg [PARALLEL_NUM-1:0]   o_binary    // 4像素二值化标记（1=肤色，0=非肤色，可选）
);



reg [PARALLEL_NUM-1:0] dilate_or;  
reg  [7:0]	binary_reg;

// 第二步：generate循环生成4组3×3模板提取逻辑（每组处理1个像素的R分量）
wire [PARALLEL_NUM-1:0][7:0] temp_11 ;
wire [PARALLEL_NUM-1:0][7:0] temp_12 ;
wire [PARALLEL_NUM-1:0][7:0] temp_13 ;
wire [PARALLEL_NUM-1:0][7:0] temp_21 ;
wire [PARALLEL_NUM-1:0][7:0] temp_22 ;
wire [PARALLEL_NUM-1:0][7:0] temp_23 ;
wire [PARALLEL_NUM-1:0][7:0] temp_31 ;  
wire [PARALLEL_NUM-1:0][7:0] temp_32 ;
wire [PARALLEL_NUM-1:0][7:0] temp_33 ;
wire [PARALLEL_NUM-1:0][7:0] r_data ;

generate
    genvar j ;// 循环变量，对应4个并行像素
    for (j= 0; j< PARALLEL_NUM; j= j+ 1) begin : array_assign
        // 逐个索引赋值：将输入i_r的第i个元素赋值给r_data的第i个元素
        assign r_data[j]= i_r[j];
    end
endgenerate



generate
    genvar i;
    for (i = 0; i < PARALLEL_NUM; i = i + 1) begin : template_core
       
        image_template u_image_template (
            .i_clk      (i_clk),
            .i_rst_n    (i_rst_n),
            .i_en       (i_valid),    
            .i_data     (r_data[i]),  
            .o_en       ()         , 
            .o_temp_11  (temp_11[i]),
            .o_temp_12  (temp_12[i]),
            .o_temp_13  (temp_13[i]),
            .o_temp_21  (temp_21[i]),
            .o_temp_22  (temp_22[i]),
            .o_temp_23  (temp_23[i]),
            .o_temp_31  (temp_31[i]),
            .o_temp_32  (temp_32[i]),
            .o_temp_33  (temp_33[i])
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

        assign temp_inmed_11 = temp_11[i]  ;
        assign temp_inmed_12 = temp_12[i]  ;
        assign temp_inmed_13 = temp_13[i]  ;
        assign temp_inmed_21 = temp_21[i]  ;
        assign temp_inmed_22 = temp_22[i]  ;
        assign temp_inmed_23 = temp_23[i]  ;
        assign temp_inmed_31 = temp_31[i]  ;
        assign temp_inmed_32 = temp_32[i]  ;
        assign temp_inmed_33 = temp_33[i]  ;

        always @(posedge i_clk or negedge i_rst_n) begin
            if (!i_rst_n) 
                // dilate_or <= {PARALLEL_NUM{1'b0}}; 
                dilate_or[i] <= 1'b0;
         else begin
                dilate_or[i] <= (temp_inmed_11[0] || temp_inmed_12[0] || temp_inmed_13[0] ||
                                temp_inmed_21[0] || temp_inmed_22[0] || temp_inmed_23[0] ||
                                temp_inmed_31[0] || temp_inmed_32[0] || temp_inmed_33[0]);           
        end  
     end



end
endgenerate

// 并行膨胀运算（3×3窗口或逻辑，基于R分量判断肤色）
// 4像素膨胀结果（1=含肤色，0=不含）

// 输出32bit并行R分量（膨胀结果映射为255/0）
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_r_data <= {TOTAL_R_WIDTH{1'b0}};
        o_binary <= {PARALLEL_NUM{1'b0}};
    end else  begin
        // 拼接4组R分量为32bit并行数据（高位对应第3个像素，低位对应第0个像素）
        o_r_data[7:0]     <= dilate_or[0] ? 8'd255 : 8'd0;  // 第0个像素R输出
        o_r_data[15:8]    <= dilate_or[1] ? 8'd255 : 8'd0;  // 第1个像素R输出
        o_r_data[23:16]   <= dilate_or[2] ? 8'd255 : 8'd0;  // 第2个像素R输出
        o_r_data[31:24]   <= dilate_or[3] ? 8'd255 : 8'd0;  // 第3个像素R输出    
  // 二值化标记
        o_binary <= dilate_or;
    end
end



reg [2:0] last_r;
reg [2:0] user_r;
reg [2:0] valid_r;


always@(posedge i_clk ) 
begin
    last_r      <= {last_r[1:0],i_last};           
    user_r      <= {user_r[1:0],i_user};
    valid_r     <= {valid_r[1:0],i_valid};
end

assign  o_last = last_r[2];
assign  o_user = user_r[2];
assign  o_valid = valid_r[2];


endmodule

