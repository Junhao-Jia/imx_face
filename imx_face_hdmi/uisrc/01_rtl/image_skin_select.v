module image_skin_select #(
    parameter  PARALLEL_NUM = 4,         // 并行像素数（固定4）
    parameter  H_ACTIVE     = 1920,      // 图像有效宽度
    parameter  V_ACTIVE     = 1080,       // 图像有效高度
    parameter  R_VALUE      = 8'd255,  // 边框颜色R（默认红色）
    parameter  G_VALUE      = 8'd0,      // 边框颜色G
    parameter  B_VALUE      = 8'd0       // 边框颜色B
)
(
	input   wire				i_clk,
	input   wire				i_rst_n,
// 输入：复用腐蚀模块的4像素并行二值化数据
(* MARK_DEBUG="true" *)    input   wire [PARALLEL_NUM-1:0][7:0]    i_r,    // 腐蚀输出o_binary[3:0]
    input   wire [PARALLEL_NUM-1:0][7:0]    i_g,    // 复用i_r
    input   wire [PARALLEL_NUM-1:0][7:0]    i_b,    // 复用i_r

(* MARK_DEBUG="true" *)   input  wire           i_last                  ,
(* MARK_DEBUG="true" *)   input  wire           i_user                  ,
(* MARK_DEBUG="true" *)   input  wire           i_valid                 ,	
	
   (* MARK_DEBUG="true" *)output wire           o_last                  ,
   (* MARK_DEBUG="true" *)output wire           o_user                  ,
   (* MARK_DEBUG="true" *)output wire           o_valid                 ,
   (* MARK_DEBUG="true" *)// 输入：4像素并行原始图像数据
   (* MARK_DEBUG="true" *)input   wire [PARALLEL_NUM-1:0][7:0]    i_r_original,
   (* MARK_DEBUG="true" *)input   wire [PARALLEL_NUM-1:0][7:0]    i_g_original,
   (* MARK_DEBUG="true" *)input   wire [PARALLEL_NUM-1:0][7:0]    i_b_original,

   (* MARK_DEBUG="true" *)// 输出：4像素并行带边框图像数据
   (* MARK_DEBUG="true" *)output  reg [PARALLEL_NUM-1:0][7:0]     o_r,
   (* MARK_DEBUG="true" *)output  reg [PARALLEL_NUM-1:0][7:0]     o_g,
   (* MARK_DEBUG="true" *)output  reg [PARALLEL_NUM-1:0][7:0]     o_b
);
  parameter SKIN_AREA_THRESH_MIN = 16'd50;  // 最小面积阈值（适应远距离）
  parameter SKIN_AREA_THRESH_MAX = 16'd2000; // 最大面积阈值（防止过大区域）
  parameter BORDER_WIDTH = 11'd1;            // 边框宽度
  parameter MAX_BORDER_STEP = 11'd5;         // 步长限制（更小步长更精确）
  parameter FACE_ASPECT_RATIO_MIN = 11'd5;   // 人脸宽高比最小 (1:1.4)
  parameter FACE_ASPECT_RATIO_MAX = 11'd20;  // 人脸宽高比最大 (1.4:1)
                    
(* MARK_DEBUG="true" *)reg  [10:0] 	    h_cnt;
(* MARK_DEBUG="true" *)reg  [10:0] 	    v_cnt;

reg [2:0] last_r;
reg [2:0] user_r;
reg [2:0] valid_r;

(* MARK_DEBUG="true" *)reg  [10:0]  skin_h_min_d;   // 延迟锁存的最小列坐标
(* MARK_DEBUG="true" *)reg  [10:0]  skin_h_max_d;   // 延迟锁存的最大列坐标
(* MARK_DEBUG="true" *)reg  [10:0]  skin_v_min_d;   // 延迟锁存的最小行坐标
(* MARK_DEBUG="true" *)reg  [10:0]  skin_v_max_d;   // 延迟锁存的最大行坐标
// 全局边界寄存器
(* MARK_DEBUG="true" *)reg [10:0] skin_h_min;  // 全局最小x坐标
(* MARK_DEBUG="true" *)reg [10:0] skin_h_max;  // 全局最大x坐标
(* MARK_DEBUG="true" *)reg [10:0] skin_v_min;  // 全局最小y坐标
(* MARK_DEBUG="true" *)reg [10:0] skin_v_max;  // 全局最大y坐标

  // 定义移位寄存器，打两拍
    reg [PARALLEL_NUM - 1:0][7:0] r_original_r1;
    reg [PARALLEL_NUM - 1:0][7:0] r_original_r2;
    reg [PARALLEL_NUM - 1:0][7:0] g_original_r1;
    reg [PARALLEL_NUM - 1:0][7:0] g_original_r2;
    reg [PARALLEL_NUM - 1:0][7:0] b_original_r1;
    reg [PARALLEL_NUM - 1:0][7:0] b_original_r2;

always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_original_r1 <= {PARALLEL_NUM{8'd0}};
            r_original_r2 <= {PARALLEL_NUM{8'd0}};
            g_original_r1 <= {PARALLEL_NUM{8'd0}};
            g_original_r2 <= {PARALLEL_NUM{8'd0}};
            b_original_r1 <= {PARALLEL_NUM{8'd0}};
            b_original_r2 <= {PARALLEL_NUM{8'd0}};
        end else begin
            // 第一拍
            r_original_r1 <= i_r_original;
            g_original_r1 <= i_g_original;
            b_original_r1 <= i_b_original;
            // 第二拍
            r_original_r2 <= r_original_r1;
            g_original_r2 <= g_original_r1;
            b_original_r2 <= b_original_r1;
        end
    end





always@(posedge i_clk ) 
begin
    last_r      <= {last_r[1:0],i_last};           
    user_r      <= {user_r[1:0],i_user};
    valid_r     <= {valid_r[1:0],i_valid};
end

assign  o_last  = last_r [2];
assign  o_user  = user_r [2];
assign  o_valid = valid_r[2];

// 全局行计数器：每4像素递增1次（对应4并行像素）
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        h_cnt <= 11'd0;
    end else if (i_user && i_valid) begin  // 新帧开始，复位列计数
        h_cnt <= 11'd0;
    end else if (i_valid) begin  // 数据有效时，每拍+4（对应1组4像素）
        if (i_last) begin  // 最后一组4像素，下一拍清零
            h_cnt <= 11'd0;
        end else begin
            h_cnt <= h_cnt + PARALLEL_NUM;  // 关键：按并行数递增，确保组内x坐标连续
        end
    end
end

// 全局列计数器：一行结束后递增（和单像素逻辑一致）
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        v_cnt <= 11'd0;
    end else if (i_user && i_valid) begin  // 新帧开始，复位行计数
        v_cnt <= 11'd0;
    end else if (i_valid && i_last) begin  // 处理完一行最后一组4像素，行计数+1
        if(v_cnt == V_ACTIVE - 2)
            v_cnt <= V_ACTIVE - 1;
            else if (v_cnt == V_ACTIVE - 1'b1) begin
                v_cnt <= 11'd0;
                end else begin
                v_cnt <= v_cnt + 11'd1;
        end
    end
end

// ------------------------ 2. 并行坐标生成（内部自动生成，无需外部输入） ------------------------
(* MARK_DEBUG="true" *)wire  [PARALLEL_NUM-1:0][10:0]  pixel_x;  // 4个像素的x坐标（列位置）
(* MARK_DEBUG="true" *)wire  [PARALLEL_NUM-1:0][10:0]  pixel_y;  // 4个像素的y坐标（行位置）
generate
    genvar j;
    for (j = 0; j < PARALLEL_NUM; j = j + 1) begin : gen_parallel_coord
        assign pixel_x[j] = i_valid ? (h_cnt + j) : 11'd0;
        assign pixel_y[j] = i_valid ? v_cnt : 11'd0;
    end
endgenerate


(* MARK_DEBUG="true" *)wire frame_end; 
reg frame_end_d1, frame_end_d2;
(* MARK_DEBUG="true" *)wire frame_end_pulse;

assign frame_end = (v_cnt == V_ACTIVE - 1'b1) && i_valid && i_last;
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        frame_end_d1 <= 1'b0;
        frame_end_d2 <= 1'b0;
    end else begin
        frame_end_d1 <= frame_end;
        frame_end_d2 <= frame_end_d1;
    end
end
assign frame_end_pulse = frame_end_d1 & ~frame_end_d2;  // 帧结束脉冲（单周期）

// 单像素肤色标记
wire [PARALLEL_NUM-1:0] skin_pixel = {
    (i_r[3] == 8'hff),
    (i_r[2] == 8'hff),
    (i_r[1] == 8'hff),
    (i_r[0] == 8'hff)};
//wire has_continuous_skin = (skin_pixel[3:2] == 2'b11) ||  // 像素3和2连续
//                           (skin_pixel[2:1] == 2'b11) ||  // 像素2和1连续
//                           (skin_pixel[1:0] == 2'b11);     // 像素1和0连续
    wire has_continuous_skin = (skin_pixel == 4'b1111);
// 新增：缓存上一行的连续肤色标记（检测纵向连续性）
reg [1:0] prev_row_continuous;  // 缓存上1~2行的has_continuous_skin
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) prev_row_continuous <= 2'b00;
    else if (i_valid && i_last) begin  // 行结束时更新缓存
        prev_row_continuous <= {prev_row_continuous[0], has_continuous_skin};
    end
end
// 纵向连续判断：当前行和上一行均有连续肤色像素
wire has_vertical_continuous = has_continuous_skin || prev_row_continuous[0];
// 新增：检测当前像素与左侧像素的梯度（是否突兀变化）
wire [PARALLEL_NUM-1:0] skin_edge = {
    skin_pixel[3] & ~skin_pixel[2],  // 像素3是肤色，像素2不是→可能是边缘/噪声
    skin_pixel[2] & ~skin_pixel[1],
    skin_pixel[1] & ~skin_pixel[0],
    1'b0  // 像素0左侧无数据，默认为0
};
wire has_abnormal_edge = &skin_edge; 



// 进一步强化use_for_boundary：增加像素密度要求
reg [15:0] local_skin_density; // 局部皮肤密度计数器

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        local_skin_density <= 16'd0;
    end else if (i_user && i_valid) begin
        local_skin_density <= 16'd0;
    end else if (i_valid && i_last) begin
        local_skin_density <= {14'd0, has_continuous_skin, has_vertical_continuous};
    end else if (i_valid) begin
        local_skin_density <= has_continuous_skin ? 
                             (local_skin_density + 1) :  // 连续时增加
                             (local_skin_density > 0 ? local_skin_density - 1'd1 : 0);  // 非连续时缓慢减少（每次减1）
    end
end
// 更严格的边界使用条件：要求局部密度足够高
wire high_density_area = local_skin_density > 16'd3;
(* MARK_DEBUG="true" *)wire use_for_boundary = i_valid && has_continuous_skin && has_vertical_continuous && !has_abnormal_edge /*&& high_density_area*/;


wire [10:0] min_x_candidate  = (skin_pixel[0] && use_for_boundary && pixel_x[0] > 11'd10) ? pixel_x[0] : H_ACTIVE;
wire [10:0] min_x_candidate1 = (skin_pixel[1] && use_for_boundary && pixel_x[1] > 11'd10) ? pixel_x[1] : H_ACTIVE;
wire [10:0] min_x_candidate2 = (skin_pixel[2] && use_for_boundary && pixel_x[2] > 11'd10) ? pixel_x[2] : H_ACTIVE;
wire [10:0] min_x_candidate3 = (skin_pixel[3] && use_for_boundary && pixel_x[3] > 11'd10) ? pixel_x[3] : H_ACTIVE;
wire [10:0] current_min_x = min_x_candidate < min_x_candidate1 ? min_x_candidate : min_x_candidate1;
wire [10:0] current_min_x2 = min_x_candidate2 < min_x_candidate3 ? min_x_candidate2 : min_x_candidate3;
wire [10:0] final_min_x = current_min_x < current_min_x2 ? current_min_x : current_min_x2;

// 更新最大x：同时比较4个像素，取最大值（排除边缘）
wire [10:0] max_x_candidate  = (skin_pixel[0] && use_for_boundary && pixel_x[0] < (H_ACTIVE - 11'd10)) ? pixel_x[0] : 11'd0;
wire [10:0] max_x_candidate1 = (skin_pixel[1] && use_for_boundary && pixel_x[1] < (H_ACTIVE - 11'd10)) ? pixel_x[1] : 11'd0;
wire [10:0] max_x_candidate2 = (skin_pixel[2] && use_for_boundary && pixel_x[2] < (H_ACTIVE - 11'd10)) ? pixel_x[2] : 11'd0;
wire [10:0] max_x_candidate3 = (skin_pixel[3] && use_for_boundary && pixel_x[3] < (H_ACTIVE - 11'd10)) ? pixel_x[3] : 11'd0;
wire [10:0] current_max_x = max_x_candidate > max_x_candidate1 ? max_x_candidate : max_x_candidate1;
wire [10:0] current_max_x2 = max_x_candidate2 > max_x_candidate3 ? max_x_candidate2 : max_x_candidate3;
wire [10:0] final_max_x = current_max_x > current_max_x2 ? current_max_x : current_max_x2;

wire has_skin_pixel = (i_r[0]==8'hff && i_g[0]==8'hff && i_b[0]==8'hff)
                    || (i_r[1]==8'hff && i_g[1]==8'hff && i_b[1]==8'hff) 
                    || (i_r[2]==8'hff && i_g[2]==8'hff && i_b[2]==8'hff)
                    || (i_r[3]==8'hff && i_g[3]==8'hff && i_b[3]==8'hff);
wire [10:0] curr_min_y = (use_for_boundary && v_cnt > 11'd10) ? v_cnt : V_ACTIVE;
wire [10:0] curr_max_y = (use_for_boundary && v_cnt < (V_ACTIVE - 11'd10)) ? v_cnt : 11'd0;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        skin_h_min <= H_ACTIVE;  // 初始值设为最大有效宽度
        skin_h_max <= 11'd0;
        skin_v_min <= V_ACTIVE;
        skin_v_max <= 11'd0;
    end else if (i_user && i_valid) begin
        skin_h_min <= H_ACTIVE;
        skin_h_max <= 11'd0;
        skin_v_min <= V_ACTIVE;
        skin_v_max <= 11'd0;
    end else if (use_for_boundary) begin
        skin_h_min <= (final_min_x < skin_h_min - MAX_BORDER_STEP) ? 
                      (skin_h_min - MAX_BORDER_STEP) :  // 步长限制
                      (final_min_x < skin_h_min) ? final_min_x : skin_h_min;
        skin_h_max <= (final_max_x > skin_h_max + MAX_BORDER_STEP) ? 
                      (skin_h_max + MAX_BORDER_STEP) :  
                      (final_max_x > skin_h_max) ? final_max_x : skin_h_max;
        skin_v_min <= (curr_min_y < skin_v_min - MAX_BORDER_STEP) ? 
                      (skin_v_min - MAX_BORDER_STEP) : 
                      (curr_min_y < skin_v_min) ? curr_min_y : skin_v_min;
        skin_v_max <= (curr_max_y > skin_v_max + MAX_BORDER_STEP) ? 
                      (skin_v_max + MAX_BORDER_STEP) : 
                      (curr_max_y > skin_v_max) ? curr_max_y : skin_v_max;
    end
end


// 边界宽高及合理性判断
wire [10:0] skin_width  = skin_h_max - skin_h_min;
wire [10:0] skin_height = skin_v_max - skin_v_min;

// 人脸比例约束：正常人脸宽高比约为1:1.2~1:1.6，这里简化为1:0.7~1:1.4
/*wire is_valid_aspect_ratio = (skin_height != 0) && 
                            (skin_width * FACE_ASPECT_RATIO_MIN < skin_height * 11'd10) && 
                            (skin_width * FACE_ASPECT_RATIO_MAX > skin_height * 11'd10);*/
(* MARK_DEBUG="true" *)wire is_valid_aspect_ratio = (skin_height == 0) ? 1'b0 : 
                            (skin_width * FACE_ASPECT_RATIO_MIN < skin_height * 11'd10) && 
                            (skin_width * FACE_ASPECT_RATIO_MAX > skin_height * 11'd10);
// 更合理的尺寸判断：最小尺寸更小以适应远距离，最大尺寸合理限制
wire is_valid_size = (skin_width > 11'd10) && (skin_height > 11'd15)  // 更小的最小尺寸
                  && (skin_width < H_ACTIVE - 11'd20)                 // 宽度远小于屏幕
                  && (skin_height < V_ACTIVE - 11'd20);               // 高度远小于屏幕

(* MARK_DEBUG="true" *)reg [15:0] skin_area_cnt;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        skin_area_cnt <= 16'd0;
    end else if (i_user && i_valid) begin
        skin_area_cnt <= 16'd0;
    end else if (use_for_boundary) begin
        // 统计当前4个像素中的肤色数量（i_r==8'hff）
        skin_area_cnt <= skin_area_cnt + skin_pixel[0] + skin_pixel[1] + skin_pixel[2] + skin_pixel[3];
    end
end

// 更智能的皮肤区域判断：面积在合理范围内 + 尺寸合理 + 比例合理
wire is_real_skin = (skin_area_cnt >= SKIN_AREA_THRESH_MIN) && 
                    (skin_area_cnt <= SKIN_AREA_THRESH_MAX) && 
                    is_valid_size /* && is_valid_aspect_ratio*/;


always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        skin_h_min_d <= 11'd0;
        skin_h_max_d <= 11'd0;
        skin_v_min_d <= 11'd0;
        skin_v_max_d <= 11'd0;
    end else if (frame_end_pulse) begin
        // 有效肤色区域：锁存新边界
        if (skin_h_min < skin_h_max && skin_v_min < skin_v_max /* && is_real_skin*/) begin
            skin_h_min_d <= skin_h_min;
            skin_h_max_d <= skin_h_max;
            skin_v_min_d <= skin_v_min;
            skin_v_max_d <= skin_v_max;
        end 
        else begin
            skin_h_min_d <= 11'd0;  
            skin_h_max_d <= 11'd0;
            skin_v_min_d <= 11'd0 ;  
            skin_v_max_d <= 11'd0;
        end
    end
end

// ------------------------ 4. 并行输出逻辑（坐标改为内部生成的pixel_x/pixel_y） ------------------------
generate
    genvar k;
    for (k = 0; k< PARALLEL_NUM; k = k + 1) begin : parallel_output

        wire in_top_border =   // 上边框：y在[y_min_r-BORDER_WIDTH, y_min_r+BORDER_WIDTH]，x在[x_min_r, x_max_r]
            (pixel_y[k] >= (skin_v_min_d - BORDER_WIDTH)) && 
            (pixel_y[k] <= (skin_v_min_d + BORDER_WIDTH)) && 
            (pixel_x[k] >= skin_h_min_d) && 
            (pixel_x[k] <= skin_h_max_d);

        wire in_bottom_border =  // 下边框：y在[y_max_r-BORDER_WIDTH, y_max_r+BORDER_WIDTH]，x在[x_min_r, x_max_r]
            (pixel_y[k] >= (skin_v_max_d - BORDER_WIDTH)) && 
            (pixel_y[k] <= (skin_v_max_d + BORDER_WIDTH)) && 
            (pixel_x[k] >= skin_h_min_d) && 
            (pixel_x[k] <= skin_h_max_d);   
            
        wire in_left_border =   // 左边框：x在[x_min_r-BORDER_WIDTH, x_min_r+BORDER_WIDTH]，y在[y_min_r, y_max_r]
            (pixel_x[k] >= (skin_h_min_d - BORDER_WIDTH)) && 
            (pixel_x[k] <= (skin_h_min_d + BORDER_WIDTH)) && 
            (pixel_y[k] >= skin_v_min_d) && 
            (pixel_y[k] <= skin_v_max_d);
            
        wire in_right_border =  // 右边框：x在[x_max_r-BORDER_WIDTH, x_max_r+BORDER_WIDTH]，y在[y_min_r, y_max_r]
            (pixel_x[k] >= (skin_h_max_d - BORDER_WIDTH)) && 
            (pixel_x[k] <= (skin_h_max_d + BORDER_WIDTH)) && 
            (pixel_y[k] >= skin_v_min_d) && 
            (pixel_y[k] <= skin_v_max_d);          
            
        wire border_valid = (skin_h_min_d < skin_h_max_d) && (skin_v_min_d < skin_v_max_d);    
        (* MARK_DEBUG="true" *)wire pixel_in_border = border_valid && (in_top_border ||
                                                     in_bottom_border || in_left_border || in_right_border);   
 
        always @(posedge i_clk or negedge i_rst_n) begin
            if (!i_rst_n) begin
                o_r[k] <= 8'd0;
                o_g[k] <= 8'd0;
                o_b[k] <= 8'd0;
            end else if (i_valid) begin
                o_r[k] <= pixel_in_border ? R_VALUE : r_original_r2[k];
                o_g[k] <= pixel_in_border ? G_VALUE : g_original_r2[k];
                o_b[k] <= pixel_in_border ? B_VALUE : b_original_r2[k];
            end
        end                                             
    end
endgenerate

endmodule
