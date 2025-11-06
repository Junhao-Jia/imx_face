`define TEMPLATE_3X3
// `define TEMPLATE_5X5

module image_template #(
    parameter  PARALLEL_NUM = 4,         // 并行像素数（固定4，与上游对齐）
    parameter  H_ACTIVE     = 1920,     // 图像宽度（可配置）
    parameter  V_ACTIVE     = 1080,    // 图像高度（可配置）
    parameter  DATA_WIDTH   = 8          // 单像素数据位宽
)
(
	input   wire				i_clk,
	input   wire				i_rst_n,

	input	wire				i_en,
    input   wire [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]     i_data,  // 4像素并行输入

	output	reg 				o_en,
	`ifdef TEMPLATE_3X3
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]	 o_temp_11,  // 4像素并行输出（3×3模板）
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]	 o_temp_12,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]	 o_temp_13,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]	 o_temp_21,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]	 o_temp_22,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]	 o_temp_23,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]	 o_temp_31,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]	 o_temp_32,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]	 o_temp_33
	`endif
	`ifdef TEMPLATE_5X5
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_11,  // 4像素并行输出（5×5模板）
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_12,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_13,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_14,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_15,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_21,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_22,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_23,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_24,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_25,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_31,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_32,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_33,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_34,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_35,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_41,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_42,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_43,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_44,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_45,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_51,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_52,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_53,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_54,
    output  reg [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]   o_temp_55
	`endif
);
//arameter  H_ACTIVE = 640; //图像宽度                              
//arameter  V_ACTIVE = 480;  //图像高度

reg  [10:0]	h_cnt;
reg  [10:0]	v_cnt;

// ------------------------ 并行FIFO信号定义（3×3模板需2个FIFO，5×5需4个） ------------------------
// FIFO 1：缓存第1行延迟数据（4个并行像素，每个像素1个FIFO）
wire [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]	fifo_1_in   ;
wire [PARALLEL_NUM-1:0]	                fifo_1_wr_en;
wire [PARALLEL_NUM-1:0]	                fifo_1_rd_en;
wire [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]	fifo_1_out  ;

// FIFO 2：缓存第2行延迟数据
wire [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]	fifo_2_in   ;
wire [PARALLEL_NUM-1:0]	                fifo_2_wr_en;
wire [PARALLEL_NUM-1:0]	                fifo_2_rd_en;
wire [PARALLEL_NUM-1:0][DATA_WIDTH-1:0]	fifo_2_out  ;




`ifdef TEMPLATE_5X5
wire [7:0]	fifo_3_in;
wire 		fifo_3_wr_en;
wire 		fifo_3_rd_en;
wire [7:0]	fifo_3_out;

wire [7:0]	fifo_4_in;
wire 		fifo_4_wr_en;
wire 		fifo_4_rd_en;
wire [7:0]	fifo_4_out;
`endif


//显示区域行计�?
always@(posedge i_clk or negedge i_rst_n) 
begin
    if(!i_rst_n)
	begin
        h_cnt <= 11'd0;
    end
    else if(i_en)
	begin
		if(h_cnt == H_ACTIVE - 1'b1)
			h_cnt <= 11'd0;
		else 
			h_cnt <= h_cnt + 11'd1;
    end
end

//显示区域场计�?
always@(posedge i_clk or negedge i_rst_n) 
begin
    if(!i_rst_n)
	begin
        v_cnt <= 11'd0;
    end
    else if(h_cnt == H_ACTIVE - 1'b1)
	begin
		if(v_cnt == V_ACTIVE - 1'b1)
			v_cnt <= 11'd0;
		else 
			v_cnt <= v_cnt + 11'd1;
    end
end

// ------------------------ 并行FIFO控制信号（每个像素独立控制，时序与原模块一致） ------------------------
generate
    genvar i;
    for (i = 0; i < PARALLEL_NUM; i = i + 1) begin : fifo_ctrl
        // FIFO 1：输入=当前像素数据，写使能=非最后一行，读使能=非第一行
        assign fifo_1_in[i]    = i_data[i];
        assign fifo_1_wr_en[i] = (v_cnt < V_ACTIVE - 1) ? i_en : 1'b0;
        assign fifo_1_rd_en[i] = (v_cnt > 0) ? i_en : 1'b0;

        // FIFO 2：输入=FIFO1输出，写使能=非倒数2行，读使能=非前2行
        assign fifo_2_in[i]    = fifo_1_out[i];
        assign fifo_2_wr_en[i] = fifo_1_rd_en[i] && (v_cnt < V_ACTIVE - 2);
        assign fifo_2_rd_en[i] = (v_cnt > 1) ? i_en : 1'b0;

        // FIFO 3~4：仅5×5模板需要（时序逻辑与原模块一致）
        `ifdef TEMPLATE_5X5
        assign fifo_3_in[i]    = fifo_2_out[i];
        assign fifo_3_wr_en[i] = fifo_2_rd_en[i] && (v_cnt < V_ACTIVE - 3);
        assign fifo_3_rd_en[i] = (v_cnt > 2) ? i_en : 1'b0;

        assign fifo_4_in[i]    = fifo_3_out[i];
        assign fifo_4_wr_en[i] = fifo_3_rd_en[i] && (v_cnt < V_ACTIVE - 4);
        assign fifo_4_rd_en[i] = (v_cnt > 3) ? i_en : 1'b0;
        `endif
    end
endgenerate

// ------------------------ 并行FIFO实例化（每个像素独立一个FIFO，避免数据冲突） ------------------------
generate
    genvar j;
    for (j = 0; j < PARALLEL_NUM; j = j + 1) begin : fifo_inst
        // FIFO 1实例化
    wire empty_flag_1,empty_flag_2;
  Soft_FIFO_0  Soft_FIFO_0_inst_1
  (
      .srst(!i_rst_n),
      .di(fifo_1_in[j]),
      .clk(i_clk),
      .re(fifo_1_rd_en[j]),
      .we(fifo_1_wr_en[j]),
      .dout(fifo_1_out[j]),
      .empty_flag(empty_flag_1),
      .aempty(),
      .full_flag(),
      .afull(),
      .valid(),
      .overflow(),
      .underflow(),
      .wr_success(),
      .rdusedw(),
      .wrusedw(),
      .wr_rst_done(),
      .rd_rst_done()
  );

Soft_FIFO_0  Soft_FIFO_0_inst_2
  (
      .srst(!i_rst_n),
      .di(fifo_2_in[j]),
      .clk(i_clk),
      .re(fifo_2_rd_en[j]),
      .we(fifo_2_wr_en[j]),
      .dout(fifo_2_out[j]),
      .empty_flag(empty_flag_2),
      .aempty(),
      .full_flag(),
      .afull(),
      .valid(),
      .overflow(),
      .underflow(),
      .wr_success(),
      .rdusedw(),
      .wrusedw(),
      .wr_rst_done(),
      .rd_rst_done()
  );



/*
        fifo_generator_0 u_fifo_1(
            .clk        (i_clk), 
            .srst       (!i_rst_n), 
            .din        (fifo_1_in[j]),
            .wr_en      (fifo_1_wr_en[j]),
            .rd_en      (fifo_1_rd_en[j]),
            .dout       (fifo_1_out[j]),
            .full       (),
            .empty      (), 
            .data_count ()
        );

        // FIFO 2实例化
        fifo_generator_0 u_fifo_2(
            .clk        (i_clk), 
            .srst       (!i_rst_n), 
            .din        (fifo_2_in[j]),
            .wr_en      (fifo_2_wr_en[j]),
            .rd_en      (fifo_2_rd_en[j]),
            .dout       (fifo_2_out[j]),  
            .full       (),
            .empty      (), 
            .data_count ()
        );
*/
        // FIFO 3~4实例化（仅5×5模板）
        `ifdef TEMPLATE_5X5
        fifo_generator_0 u_fifo_3(
            .clk        (i_clk), 
            .srst       (!i_rst_n), 
            .din        (fifo_3_in[j]),
            .wr_en      (fifo_3_wr_en[j]),
            .rd_en      (fifo_3_rd_en[j]),
            .dout       (fifo_3_out[j]),  
            .full       (),
            .empty      (), 
            .data_count ()
        );

        fifo_generator_0 u_fifo_4(
            .clk        (i_clk), 
            .srst       (!i_rst_n), 
            .din        (fifo_4_in[j]),
            .wr_en      (fifo_4_wr_en[j]),
            .rd_en      (fifo_4_rd_en[j]),
            .dout       (fifo_4_out[j]),  
            .full       (),
            .empty      (), 
            .data_count ()
        );
        `endif
    end
endgenerate


// ------------------------ 3×3模板并行输出逻辑（每个像素独立移位，与原模块时序一致） ------------------------
`ifdef TEMPLATE_3X3
generate
    genvar k;
    for (k = 0; k < PARALLEL_NUM; k = k + 1) begin : template_3x3_logic
        always@(posedge i_clk or negedge i_rst_n) 
        begin
            if(!i_rst_n) begin
                o_temp_11[k] <= {DATA_WIDTH{1'b0}};
                o_temp_12[k] <= {DATA_WIDTH{1'b0}};
                o_temp_13[k] <= {DATA_WIDTH{1'b0}};
                o_temp_21[k] <= {DATA_WIDTH{1'b0}};
                o_temp_22[k] <= {DATA_WIDTH{1'b0}};
                o_temp_23[k] <= {DATA_WIDTH{1'b0}};
                o_temp_31[k] <= {DATA_WIDTH{1'b0}};
                o_temp_32[k] <= {DATA_WIDTH{1'b0}};
                o_temp_33[k] <= {DATA_WIDTH{1'b0}};
            end else if(v_cnt == 0) begin  // 第1行：仅用当前输入数据
                if(h_cnt == 0) begin
                    o_temp_11[k] <= i_data[k];
                    o_temp_12[k] <= i_data[k];
                    o_temp_13[k] <= i_data[k];
                    o_temp_21[k] <= i_data[k];
                    o_temp_22[k] <= i_data[k];
                    o_temp_23[k] <= i_data[k];
                    o_temp_31[k] <= i_data[k];
                    o_temp_32[k] <= i_data[k];
                    o_temp_33[k] <= i_data[k];
                end else begin  // 行内移位：右移1位，新数据补入
                    o_temp_11[k] <= o_temp_12[k];
                    o_temp_12[k] <= o_temp_13[k];
                    o_temp_13[k] <= i_data[k];
                    o_temp_21[k] <= o_temp_22[k];
                    o_temp_22[k] <= o_temp_23[k];
                    o_temp_23[k] <= i_data[k];
                    o_temp_31[k] <= o_temp_32[k];
                    o_temp_32[k] <= o_temp_33[k];
                    o_temp_33[k] <= i_data[k];
                end
            end else if(v_cnt == 1) begin  // 第2行：用FIFO1（第1行延迟）+ 当前输入
                if(h_cnt == 0) begin
                    o_temp_11[k] <= fifo_1_out[k];
                    o_temp_12[k] <= fifo_1_out[k];
                    o_temp_13[k] <= fifo_1_out[k];
                    o_temp_21[k] <= fifo_1_out[k];
                    o_temp_22[k] <= fifo_1_out[k];
                    o_temp_23[k] <= fifo_1_out[k];
                    o_temp_31[k] <= i_data[k];
                    o_temp_32[k] <= i_data[k];
                    o_temp_33[k] <= i_data[k];
                end else begin
                    o_temp_11[k] <= o_temp_12[k];
                    o_temp_12[k] <= o_temp_13[k];
                    o_temp_13[k] <= fifo_1_out[k];
                    o_temp_21[k] <= o_temp_22[k];
                    o_temp_22[k] <= o_temp_23[k];
                    o_temp_23[k] <= fifo_1_out[k];
                    o_temp_31[k] <= o_temp_32[k];
                    o_temp_32[k] <= o_temp_33[k];
                    o_temp_33[k] <= i_data[k];
                end
            end else begin  // 第3行及以后：FIFO2（第2行延迟）+ FIFO1（第1行延迟）+ 当前输入
                if(h_cnt == 0) begin
                    o_temp_11[k] <= fifo_2_out[k];
                    o_temp_12[k] <= fifo_2_out[k];
                    o_temp_13[k] <= fifo_2_out[k];
                    o_temp_21[k] <= fifo_1_out[k];
                    o_temp_22[k] <= fifo_1_out[k];
                    o_temp_23[k] <= fifo_1_out[k];
                    o_temp_31[k] <= i_data[k];
                    o_temp_32[k] <= i_data[k];
                    o_temp_33[k] <= i_data[k];
                end else begin
                    o_temp_11[k] <= o_temp_12[k];
                    o_temp_12[k] <= o_temp_13[k];
                    o_temp_13[k] <= fifo_2_out[k];
                    o_temp_21[k] <= o_temp_22[k];
                    o_temp_22[k] <= o_temp_23[k];
                    o_temp_23[k] <= fifo_1_out[k];
                    o_temp_31[k] <= o_temp_32[k];
                    o_temp_32[k] <= o_temp_33[k];
                    o_temp_33[k] <= i_data[k];
                end
            end
        end
    end
endgenerate
`endif


// ------------------------ 5×5模板并行输出逻辑（每个像素独立移位，与原模块时序一致） ------------------------
`ifdef TEMPLATE_5X5
generate
    genvar m;
    for (m = 0; m < PARALLEL_NUM; m = m + 1) begin : template_5x5_logic
        always@(posedge i_clk or negedge i_rst_n) 
        begin
            if(!i_rst_n) begin
                o_temp_11[m] <= {DATA_WIDTH{1'b0}};
                o_temp_12[m] <= {DATA_WIDTH{1'b0}};
                o_temp_13[m] <= {DATA_WIDTH{1'b0}};
                o_temp_14[m] <= {DATA_WIDTH{1'b0}};
                o_temp_15[m] <= {DATA_WIDTH{1'b0}};
                o_temp_21[m] <= {DATA_WIDTH{1'b0}};
                o_temp_22[m] <= {DATA_WIDTH{1'b0}};
                o_temp_23[m] <= {DATA_WIDTH{1'b0}};
                o_temp_24[m] <= {DATA_WIDTH{1'b0}};
                o_temp_25[m] <= {DATA_WIDTH{1'b0}};
                o_temp_31[m] <= {DATA_WIDTH{1'b0}};
                o_temp_32[m] <= {DATA_WIDTH{1'b0}};
                o_temp_33[m] <= {DATA_WIDTH{1'b0}};
                o_temp_34[m] <= {DATA_WIDTH{1'b0}};
                o_temp_35[m] <= {DATA_WIDTH{1'b0}};
                o_temp_41[m] <= {DATA_WIDTH{1'b0}};
                o_temp_42[m] <= {DATA_WIDTH{1'b0}};
                o_temp_43[m] <= {DATA_WIDTH{1'b0}};
                o_temp_44[m] <= {DATA_WIDTH{1'b0}};
                o_temp_45[m] <= {DATA_WIDTH{1'b0}};
                o_temp_51[m] <= {DATA_WIDTH{1'b0}};
                o_temp_52[m] <= {DATA_WIDTH{1'b0}};
                o_temp_53[m] <= {DATA_WIDTH{1'b0}};
                o_temp_54[m] <= {DATA_WIDTH{1'b0}};
                o_temp_55[m] <= {DATA_WIDTH{1'b0}};
            end else begin  // 5×5模板：固定行内右移，数据来自FIFO4~1+当前输入
                o_temp_11[m] <= o_temp_12[m];
                o_temp_12[m] <= o_temp_13[m];
                o_temp_13[m] <= o_temp_14[m];
                o_temp_14[m] <= o_temp_15[m];
                o_temp_15[m] <= fifo_4_out[m];

                o_temp_21[m] <= o_temp_22[m];
                o_temp_22[m] <= o_temp_23[m];
                o_temp_23[m] <= o_temp_24[m];
                o_temp_24[m] <= o_temp_25[m];
                o_temp_25[m] <= fifo_3_out[m];

                o_temp_31[m] <= o_temp_32[m];
                o_temp_32[m] <= o_temp_33[m];
                o_temp_33[m] <= o_temp_34[m];
                o_temp_34[m] <= o_temp_35[m];
                o_temp_35[m] <= fifo_2_out[m];

                o_temp_41[m] <= o_temp_42[m];
                o_temp_42[m] <= o_temp_43[m];
                o_temp_43[m] <= o_temp_44[m];
                o_temp_44[m] <= o_temp_45[m];
                o_temp_45[m] <= fifo_1_out[m];

                o_temp_51[m] <= o_temp_52[m];
                o_temp_52[m] <= o_temp_53[m];
                o_temp_53[m] <= o_temp_54[m];
                o_temp_54[m] <= o_temp_55[m];
                o_temp_55[m] <= i_data[m];
            end
        end
    end
endgenerate
`endif

// ------------------------ 并行输出使能（与原模块逻辑一致，仅在模板有效区域输出） ------------------------
always@(posedge i_clk or negedge i_rst_n) 
begin
    if(!i_rst_n) 
        o_en <= 1'b0;
    else begin
        `ifdef TEMPLATE_3X3
        // 3×3模板：第3行及以后、第3列及以后才有效
        o_en <= (v_cnt > 1 && h_cnt > 1) ? i_en : 1'b0;
        `endif
        `ifdef TEMPLATE_5X5
        // 5×5模板：第5行及以后、第5列及以后才有效
        o_en <= (v_cnt > 3 && h_cnt > 3) ? i_en : 1'b0;
        `endif
    end
end



endmodule


