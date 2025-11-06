module face_recognition #(
	parameter  PARALLEL_NUM = 4 ,       // 并行像素数（固定4，适配96bit）
	parameter  PIXEL_WIDTH  = 32 ,       // 单像素位宽（RGB888=24bit）+a=32)
  parameter  PIXEL_WIDTH_R = 8  ,
  parameter  R_VALUE      = 8'd255,    // 边框颜色R（默认红色）
  parameter  G_VALUE      = 8'd0,      // 边框颜色G
  parameter  B_VALUE      = 8'd0 ,      // 边框颜色B
  parameter H_ActiveSize  =   1980,              
  parameter H_FrameSize   =   1920+88+44+148,   
  parameter H_SyncStart   =   1920+88,          
  parameter H_SyncEnd     =   1920+88+44,        
  parameter  H_FRONT_PORCH 	= 88,  
  parameter  H_SYNC_TIME 		= 44,  
  parameter  H_BACK_PORCH 	= 148, 
  parameter V_ActiveSize  =   1080,     
  parameter V_FrameSize   =   1080+4+5+36,       
  parameter V_SyncStart   =   1080+4,            
  parameter V_SyncEnd     =   1080+4+5,           
  parameter  V_FRONT_PORCH 	= 4,  
  parameter  V_SYNC_TIME  	= 5,  
  parameter  V_BACK_PORCH 	= 36  


)
(
	input   wire				i_clk,
	input   wire				i_rst_n,
  input   wire  [127:0]       i_isp_data,
  input             I_tlast,
  input             I_tuser,
	input             I_tvalid,

  output              o_last,  
  output              o_user,
  output              o_valid,
  output  wire  [127:0] o_data

);
parameter  TOTAL_R_WIDTH = PARALLEL_NUM * PIXEL_WIDTH_R;

wire [PARALLEL_NUM-1:0][7:0]  o_rgb_a;
wire [PARALLEL_NUM-1:0][7:0]  o_rgb_r;
wire [PARALLEL_NUM-1:0][7:0]  o_rgb_g;
wire [PARALLEL_NUM-1:0][7:0]  o_rgb_b;

wire o_sk_selet_last;
wire o_sk_selet_user;
wire o_sk_selet_valid;

assign o_last = o_sk_selet_last     ; 
assign o_user = o_sk_selet_user     ;      
assign o_valid = o_sk_selet_valid   ;

u128_to_24_to_888 # (
    .PARALLEL_NUM(PARALLEL_NUM),
    .PIXEL_WIDTH(PIXEL_WIDTH)
  )
u128_to_24_to_888_inst (
    .i_tdata(i_isp_data),
    .o_rgb_a(o_rgb_a),
    .o_rgb_r(o_rgb_r),
    .o_rgb_g(o_rgb_g),
    .o_rgb_b(o_rgb_b)
  );

wire [PARALLEL_NUM-1:0][7:0]	skin_color_o_r ;
wire [PARALLEL_NUM-1:0][7:0]	skin_color_o_g ;
wire [PARALLEL_NUM-1:0][7:0]	skin_color_o_b ;

wire o_skin_last;
wire o_skin_user;
wire o_skin_valid;

skin_color_algorithm # (
    .PARALLEL_NUM(PARALLEL_NUM)
  )
  skin_color_algorithm_inst (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_rgb_r(o_rgb_r),
    .i_rgb_g(o_rgb_g),
    .i_rgb_b(o_rgb_b),
    .i_last(I_tlast),
    .i_user(I_tuser),
    .i_valid(I_tvalid),
    .o_last(o_skin_last),
    .o_user(o_skin_user),
    .o_valid(o_skin_valid),
    .o_r(skin_color_o_r),
    .o_g(skin_color_o_g),
    .o_b(skin_color_o_b)
  );


wire [TOTAL_R_WIDTH-1:0]  o_dialate_data;

wire o_dilate_last;
wire o_dilate_user;
wire o_dilate_valid;


image_dilate_filtering # (
    .PARALLEL_NUM(PARALLEL_NUM),
    .PIXEL_WIDTH_R(PIXEL_WIDTH_R),
    .TOTAL_R_WIDTH(TOTAL_R_WIDTH)
  )
  image_dilate_filtering_inst (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_last  (o_skin_last) ,
    .i_user  (o_skin_user) ,
    .i_valid (o_skin_valid) ,	
    .o_last  (o_dilate_last) ,
    .o_user  (o_dilate_user) ,
    .o_valid (o_dilate_valid),
    .i_r(skin_color_o_r),
    .o_r_data(o_dialate_data),
    .o_binary()     // 4像素二值化标记
  );

wire [TOTAL_R_WIDTH-1:0]  o_erode_data;
wire  o_erode_last;
wire  o_erode_user;
wire  o_erode_valid;

image_erode_filtering # (
    .PARALLEL_NUM(PARALLEL_NUM),
    .PIXEL_WIDTH_R(PIXEL_WIDTH_R),
    .TOTAL_BIN_WIDTH(TOTAL_R_WIDTH)
  )
  image_erode_filtering_inst (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_binary(o_dialate_data),
    .i_last      (o_dilate_last) ,
    .i_user      (o_dilate_user) ,
    .i_valid     (o_dilate_valid) ,	
    .o_last      (o_erode_last) ,
    .o_user      (o_erode_user) ,
    .o_valid     (o_erode_valid),
    .o_binary(o_erode_data),
    .o_bin_flag() // 4像素腐蚀标记
  );

wire [PARALLEL_NUM-1:0][7:0] o_sk_rgb_r;
wire [PARALLEL_NUM-1:0][7:0] o_sk_rgb_g;
wire [PARALLEL_NUM-1:0][7:0] o_sk_rgb_b;


image_skin_select # (
    .PARALLEL_NUM(PARALLEL_NUM),
    .H_ACTIVE(H_ActiveSize),
    .V_ACTIVE(V_ActiveSize),
    .R_VALUE(R_VALUE),
    .G_VALUE(G_VALUE),
    .B_VALUE(B_VALUE)
  )
  image_skin_select_inst (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_last   (o_erode_last) ,
    .i_user   (o_erode_user) ,
    .i_valid  (o_erode_valid) ,	
    .o_last   (o_sk_selet_last) ,
    .o_user   (o_sk_selet_user) ,
    .o_valid  (o_sk_selet_valid) ,
    .i_r(o_erode_data),
    .i_g(o_erode_data),
    .i_b(o_erode_data),
    .i_r_original(o_rgb_r),
    .i_g_original(o_rgb_g),
    .i_b_original(o_rgb_b),
    .o_r(o_sk_rgb_r),
    .o_g(o_sk_rgb_g),
    .o_b(o_sk_rgb_b)
  );


u888to_24_to_128 # (
    .PARALLEL_NUM(PARALLEL_NUM),
    .PIXEL_WIDTH(PIXEL_WIDTH)
  )
  u888to_24_to_128_inst (
   // .i_rgb_a(i_rgb_a),
    .i_rgb_r(o_sk_rgb_r),
    .i_rgb_g(o_sk_rgb_g),
    .i_rgb_b(o_sk_rgb_b),
    .o_tdata(o_data)
  );



endmodule
