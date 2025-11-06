
/*******************************MILIANKE*******************************
*Company : MiLianKe Electronic Technology Co., Ltd.
*WebSite:https://www.milianke.com
*TechWeb:https://www.uisrc.com
*tmall-shop:https://milianke.tmall.com
*jd-shop:https://milianke.jd.com
*taobao-shop1: https://milianke.taobao.com
*Create Date: 2021/10/15
*File Name: uidbuf.v
*Description: 
*Declaration:
*The reference demo provided by Milianke is only used for learning. 
*We cannot ensure that the demo itself is free of bugs, so users 
*should be responsible for the technical problems and consequences
*caused by the use of their own products.
*Copyright: Copyright (c) MiLianKe
*All rights reserved.
*Revision: 3.1
*Signal description
*1) I_ input
*2) O_ output
*3) IO_ input output
*4) S_ system internal signal
*5) _n activ low
*6) _dg debug signal 
*7) _r delay or register
*8) _s state mechine
*********************************************************************/

/*********uidbuf(fdma data buffer controller)����FDMA�ź�ʱ��Ļ��������***********
--��������������Ƶ�uidbuf(fdma data buffer controller)����FDMA�ź�ʱ��Ļ��������
--1.�����࣬ռ�ü����߼���Դ������ṹ�������߼�����Ͻ�
--2.��дͨ��������FIFO��С������λ������������ã��ʺ����ڻ���RGBʱ�����Ƶ���ݻ�������������
�汾˵����
--3.1 �޸��ź���������
*********************************************************************/

`timescale 1ns / 1ns



module uidbuf #(
    parameter integer VIDEO_ENABLE   = 1,
    parameter integer AXI_DATA_WIDTH = 64,  //AXI��������λ��
    parameter integer AXI_ADDR_WIDTH = 32,  //AXI���ߵ�ַλ��

    parameter integer W_BUFDEPTH = 2048,  //дͨ��AXI����FIFO�����С
    parameter integer W_DATAWIDTH = 32,  //дͨ��AXI��������λ����С
    parameter [AXI_ADDR_WIDTH -1:0] W_BASEADDR = 0,  //дͨ�������ڴ���ʼ��ַ
    parameter  integer                   W_DSIZEBITS    = 24, //дͨ�����û������ݵ�������ַ��С������FDMA DBUF ����֡������ʼ��ַ
    parameter  integer                   W_XSIZE        = 1920, //дͨ������X��������ݴ�С��������ÿ��FDMA ��������ݳ���
    parameter  integer                   W_XSTRIDE      = 1920, //дͨ������X�����Strideֵ����Ҫ����ͼ�λ���Ӧ��
    parameter  integer                   W_YSIZE        = 1080, //дͨ������Y����ֵ�������˽����˶��ٴ�XSIZE����
    parameter  integer                   W_XDIV         = 2, //дͨ����X�������ݲ��ΪXDIV�δ��䣬����FIFO��ʹ��
    parameter  integer                   W_BUFSIZE      = 3, //дͨ������֡�����С��Ŀǰ���֧��128֡�������޸Ĳ���֧�ָ�������

    parameter integer R_BUFDEPTH = 2048,  //��ͨ��AXI����FIFO�����С
    parameter integer R_DATAWIDTH = 32,  //��ͨ��AXI��������λ����С
    parameter [AXI_ADDR_WIDTH -1:0] R_BASEADDR = 0,  //��ͨ�������ڴ���ʼ��ַ
    parameter  integer                   R_DSIZEBITS    = 24, //��ͨ�����û������ݵ�������ַ��С������FDMA DBUF ����֡������ʼ��ַ
    parameter  integer                   R_XSIZE        = 1920, //��ͨ������X��������ݴ�С��������ÿ��FDMA ��������ݳ���
    parameter  integer                   R_XSTRIDE      = 1920, //��ͨ������X�����Strideֵ����Ҫ����ͼ�λ���Ӧ��
    parameter  integer                   R_YSIZE        = 1080, //��ͨ������Y����ֵ�������˽����˶��ٴ�XSIZE����
    parameter  integer                   R_XDIV         = 2, //��ͨ����X�������ݲ��ΪXDIV�δ��䣬����FIFO��ʹ��
    parameter  integer                   R_BUFSIZE      = 3 //��ͨ������֡�����С��Ŀǰ���֧��128֡�������޸Ĳ���֧�ָ�������
) (
    input wire I_ui_clk,  //��FDMA AXI����ʱ��һ��
    input wire I_ui_rstn,  //��FDMA AXI��λһ��
    //sensor input -W_FIFO--------------
    input wire I_W_en,
    input wire I_W_wclk,  //�û�д���ݽӿ�ʱ�� 
    input wire I_W_tuser,  //�û�д���ݽӿ�ͬ���źţ����ڷ���Ƶ֡һ������Ϊ1
    input wire I_W_tvalid,  //�û�д����ʹ��
    input wire [W_DATAWIDTH -1 : 0] I_W_tdata,  //�û�д����
    input wire I_W_tlast,
    output wire O_W_tready,
    output reg [7 : 0] O_W_sync_cnt = 0,  //дͨ��BUF֡ͬ�����
    input wire [7 : 0] I_W_buf,  // дͨ��BUF֡ͬ������

    //----------fdma signals write-------       
    output wire [AXI_ADDR_WIDTH- 1:0] O_fdma_waddr,  //FDMAдͨ����ַ
    output wire O_fdma_wareq,  //FDMAдͨ������
    output wire    [15  :0]                     O_fdma_wsize, //FDMAдͨ��һ��FDMA�Ĵ����С                                     
    input wire I_fdma_wbusy,  //FDMA����BUSY״̬��AXI��������д����   
    output wire [AXI_DATA_WIDTH - 1:0] O_fdma_wdata,  //FDMAд����
    input wire I_fdma_wvalid,  //FDMA д��Ч
    output wire O_fdma_wready,  //FDMAд׼���ã��û�����д����
    output reg [7 : 0] O_fdma_wbuf = 0,  //FDMA��д֡��������
    output wire O_fdma_wirq,  //FDMAһ��д��ɵ����ݴ�����ɺ󣬲����жϡ�   
    //----------fdma signals read-------  
    input wire I_R_en,  //synthesis keep
    input wire I_R_rclk,  //�û������ݽӿ�ʱ��
    input wire I_R_tready,  //synthesis keep//�û�������ʹ��
    output wire O_R_tuser,
    output wire O_R_tvalid,
    output wire [R_DATAWIDTH- 1 : 0] O_R_tdata,  //�û�������
    output wire O_R_tlast,  //synthesis keep
    output reg [7 : 0] O_R_sync_cnt = 0,  //��ͨ��BUF֡ͬ�����
    input wire [7 : 0] I_R_buf,  //дͨ��BUF֡ͬ������


    output wire [AXI_ADDR_WIDTH- 1:0] O_fdma_raddr,  // FDMA��ͨ����ַ
    output wire O_fdma_rareq,  // FDMA��ͨ������
    output wire    [15: 0]                      O_fdma_rsize, // FDMA��ͨ��һ��FDMA�Ĵ����С                                     
    input wire I_fdma_rbusy,  // FDMA����BUSY״̬��AXI�������ڶ�����     
    input wire [AXI_DATA_WIDTH- 1:0] I_fdma_rdata,  // FDMA������
    input wire I_fdma_rvalid,  // FDMA ����Ч
    output wire O_fdma_rready,  // FDMA��׼���ã��û����Զ�����
    output reg [7 : 0] O_fdma_rbuf = 0,  // FDMA�Ķ�֡��������
    output wire O_fdma_rirq  // FDMAһ�ζ���ɵ����ݴ�����ɺ󣬲����ж�
);

  // ����Log2
  function integer clog2;
    input integer value;
    begin
      for (clog2 = 0; value > 0; clog2 = clog2 + 1) value = value >> 1;
    end
  endfunction


  //FDMA��д״̬����״ֵ̬��һ��4��״ֵ̬���� 
  localparam S_IDLE = 2'd0;
  localparam S_RST = 2'd1;
  localparam S_DATA1 = 2'd2;
  localparam S_DATA2 = 2'd3;

  // ͨ������ͨ��ʹ�ܣ������Ż������������

  localparam WFIFO_DEPTH = W_BUFDEPTH;  //дͨ��FIFO���
  localparam W_WR_DATA_COUNT_WIDTH = clog2(WFIFO_DEPTH);  //����FIFO��дͨ��λ��
  localparam W_RD_DATA_COUNT_WIDTH = clog2(
      WFIFO_DEPTH * W_DATAWIDTH / AXI_DATA_WIDTH
  );  //clog2(WFIFO_DEPTH/(AXI_DATA_WIDTH/W_DATAWIDTH))+1;

  localparam WYBUF_SIZE = (W_BUFSIZE - 1'b1);  //дͨ����Ҫ��ɶ��ٴ�XSIZE����
  localparam WY_BURST_TIMES       = (W_YSIZE*W_XDIV); //дͨ����Ҫ��ɵ�FDMA burst ����������XDIV���ڰ�XSIZE�ֽ��δ���
  localparam FDMA_WX_BURST        = (W_XSIZE*W_DATAWIDTH/AXI_DATA_WIDTH)/W_XDIV; //FDMA BURST һ�εĴ�С
  localparam WX_BURST_ADDR_INC    = (W_XSIZE*(W_DATAWIDTH/8))/W_XDIV; //FDMAÿ��burst֮��ĵ�ַ����
  localparam WX_LAST_ADDR_INC     = (W_XSTRIDE-W_XSIZE)*(W_DATAWIDTH/8) + WX_BURST_ADDR_INC; //����strideֵ����������һ�ε�ַ

  (*mark_debug = "true"*) (* KEEP = "TRUE" *) wire W_wren_ri = I_W_tvalid;

  assign O_fdma_wready = 1'b1;
  reg O_fdma_wareq_r = 1'b0;
  reg W_FIFO_Rst = 0;
  (*mark_debug = "true"*) (* KEEP = "TRUE" *) wire W_FS;
  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg [1 : 0] W_MS = 0;
  reg [W_DSIZEBITS-1'b1:0] W_addr = 0;
  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg [15:0] W_bcnt = 0;
  (*mark_debug = "true"*) (* KEEP = "TRUE" *)
  wire [W_RD_DATA_COUNT_WIDTH-1 : 0] W_rcnt;
  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg W_REQ = 0 ;
  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg [5 : 0] wirq_dly_cnt = 0;
  reg [3 : 0] wdiv_cnt = 0;
  reg [8 : 0] wrst_cnt = 0;
  reg [7 : 0] O_fdma_wbufn;

  (*mark_debug = "true"*) (* KEEP = "TRUE" *) wire wirq = O_fdma_wirq;

  assign O_fdma_wsize = FDMA_WX_BURST;
  assign O_fdma_wirq = (wirq_dly_cnt > 0);

  assign O_fdma_waddr = W_BASEADDR + {O_fdma_wbufn,W_addr};//����FPGA�߼����˷��Ƚϸ��ӣ����ͨ�����ø�λ��ַʵ�ֻ�������

  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg [1:0] W_MS_r = 0;
  always @(posedge I_ui_clk) W_MS_r <= W_MS;

  //ÿ��FDMA DBUF ���һ֡���ݴ���󣬲����жϣ�����жϳ���60�����ڵ�uiclk,������ӳٱ����㹻ZYNQ IP��ʶ������ж�
  always @(posedge I_ui_clk) begin
    if (I_ui_rstn == 1'b0) begin
      wirq_dly_cnt <= 6'd0;
      O_fdma_wbuf  <= 0;
    end else if ((W_MS_r == S_DATA2) && (W_MS == S_IDLE)) begin
      wirq_dly_cnt <= 60;
      O_fdma_wbuf  <= O_fdma_wbufn;
    end else if (wirq_dly_cnt > 0) wirq_dly_cnt <= wirq_dly_cnt - 1'b1;
  end

  assign O_fdma_wareq = O_fdma_wareq_r;

  (*mark_debug = "true"*) (* KEEP = "TRUE" *) wire W_empty;

  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg [15:0] w_ycnt = 0;
  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg wfifo_sync_en = 0;
  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg wfifo_rst_done = 0;
  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg wfifo_rst_lock = 0;

  //FDMA д״̬������ͬ�����첽תͬ��
  reg wfifo_resync_r1 = 1'b0, wfifo_resync_r2 = 1'b0, wfifo_resync_r3 = 1'b0;
  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg wfifo_resync;
  always @(posedge I_ui_clk) begin
    wfifo_resync_r1 <= ~wfifo_rst_done;
    wfifo_resync_r2 <= wfifo_resync_r1;
    wfifo_resync_r3 <= wfifo_resync_r2;

    if ({wfifo_resync_r3, wfifo_resync_r2} == 2'b10) wfifo_resync <= 1'b1;
    else if (W_MS == S_IDLE) wfifo_resync <= 1'b0;
  end


  //дͨ��״̬��������4��״ֵ̬����
  always @(posedge I_ui_clk) begin
    if (!I_ui_rstn) begin
      W_MS           <= S_IDLE;
      W_FIFO_Rst     <= 0;
      W_addr         <= 0;
      O_W_sync_cnt   <= 0;
      W_bcnt         <= 0;
      wdiv_cnt       <= 0;
      O_fdma_wbufn   <= 0;
    //  O_fdma_wareq_r <= 1'd0;
    end else begin
      case (W_MS)
        S_IDLE: begin
          W_addr <= 0;
          W_bcnt <= 0;
          wdiv_cnt <= 0;
          
          if(I_W_en & I_W_tuser & W_empty) begin //��FIFO��պ󣬽���֡ͬ��,����ж�֡ͷ��ʼ�����ݴ���
            W_MS <= S_RST;
            if((O_W_sync_cnt == WYBUF_SIZE && O_fdma_rbufn == 0) ||(O_W_sync_cnt + 1 == O_fdma_rbufn))
              O_W_sync_cnt  <=  O_W_sync_cnt;/////////////////////////////////////////////////////////////////////////////////写指针控制
            else  if (O_W_sync_cnt < WYBUF_SIZE)  //输出帧同步计数器
              O_W_sync_cnt <= O_W_sync_cnt + 1'b1;
            else O_W_sync_cnt <= 0;
          end
        end
        S_RST:begin//֡ͬ�������ڷ���Ƶ����ֱ������,������Ƶ���ݣ���ͬ��ÿһ֡�����Ҹ�λ����FIFO  
          O_fdma_wbufn <= I_W_buf;
          W_MS <= S_DATA1;
        end
        S_DATA1: begin  //����дFDMA����
          if (wfifo_resync == 1'b1)  //���������Ҫ����֡ͬ��
            W_MS <= S_IDLE;
         // else if (I_fdma_wbusy == 1'b0 && W_REQ) O_fdma_wareq_r <= 1'b1;
          else if (I_fdma_wbusy == 1'b1) begin
         //   O_fdma_wareq_r <= 1'b0;
            W_MS <= S_DATA2;
          end
        end
        S_DATA2: begin  //д��Ч����
          if (I_fdma_wbusy == 1'b0) begin
            if (W_bcnt == WY_BURST_TIMES - 1'b1)  //�ж��Ƿ������
              W_MS <= S_IDLE;
            else begin
              if(wdiv_cnt < W_XDIV - 1'b1)begin//�����XSIZE���˷ִδ��䣬һ��XSIZEҲ��ҪXDIV��FDMA��ɴ���
                W_addr   <= W_addr + WX_BURST_ADDR_INC;  //�����ַ����
                wdiv_cnt <= wdiv_cnt + 1'b1;
              end else begin
                W_addr <= W_addr + WX_LAST_ADDR_INC; //�������һ�ε�ַ���������һ�ε�ַ����stride ����
                wdiv_cnt <= 0;
              end
              W_bcnt <= W_bcnt + 1'b1;
              W_MS   <= S_DATA1;
            end
          end
        end
        default: W_MS <= S_IDLE;
      endcase
    end
  end


  (*mark_debug = "true"*) (* KEEP = "TRUE" *)wire wfifo_wen;
  reg  W_tlast_r = 1'b0;
  reg  W_tuser_r = 1'b0;
  always @(posedge I_W_wclk) begin
    W_tlast_r <= I_W_tlast;
    W_tuser_r <= I_W_tuser;
  end
  //���ӵ����ź�
  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg [15:0] w_xcnt;
  always @(posedge I_W_wclk or negedge I_ui_rstn) begin
    if (~I_ui_rstn) w_xcnt <= 0;
    else if ({W_tuser_r, I_W_tuser} == 2'b10) w_xcnt <= 1;
    else if (~W_tlast_r & I_W_tlast) w_xcnt <= 0;
    else if (I_W_tvalid) w_xcnt <= w_xcnt + 1'b1;
  end


  always @(posedge I_W_wclk or negedge I_ui_rstn) begin
    if (~I_ui_rstn) begin
      w_ycnt <= 0;
      wfifo_sync_en <= 1'b0;
    end else if (I_W_tuser & (W_empty == 1'b0)) begin
      wfifo_sync_en <= 0;
      w_ycnt <= 0;
    end else if (I_W_tuser & wfifo_rst_done) begin  //�µ�ͬ��
      wfifo_sync_en <= 1'b1;
    end else if (~W_tlast_r & I_W_tlast & wfifo_sync_en) begin  //ͬ��I_W_tlast����ͬ��
      if (w_ycnt == W_YSIZE - 1) begin  //һ֡����
        w_ycnt <= 0;
        wfifo_sync_en <= 1'b0; //ע�⣬һ֡��������������¸�ʱ����Ȼ��Ч���ݣ��ᵼ�¶����ݣ�����дFIFOʹ��wfifo_wen=I_W_en & I_W_tvalid & O_W_tready & wfifo_rst_done & (  I_W_tuser | wfifo_sync_en )
      end else w_ycnt <= w_ycnt + 1'b1;  //֡������
    end
  end

  //FIFO ͬ����λ������
  always @(posedge I_W_wclk or negedge I_ui_rstn) begin
    if (~I_ui_rstn) begin
      wrst_cnt       <= 0;
      wfifo_rst_done <= 0;
      wfifo_rst_lock <= 0;
    end else if (I_W_tuser & (W_empty == 1'b0)) begin  //ͬ����ʧ����λFIFO ����ͬ��
      wfifo_rst_lock <= 1;
      wfifo_rst_done <= 0;
      wrst_cnt       <= 0;
    end else if (wfifo_rst_lock & (wrst_cnt[8] == 0))  //��FIFO��λ
      wrst_cnt <= wrst_cnt + 1'b1;
    else begin  //���FIFO ��λ
      wrst_cnt       <= 0;
      wfifo_rst_done <= 1;
      wfifo_rst_lock <= 0;
    end
  end

  //дͨ��������FIFO��������ԭ�����xpm_fifo_async fifo����FIFO�洢��������ֵ�ﵽһ������һ������һ��FDMA��burst���ɷ�������
  always @(posedge I_ui_clk) W_REQ <= (W_rcnt > FDMA_WX_BURST - 1);
    
    
  wire W_full_pro;
  wire O_W_full;
  assign O_W_tready = 1'b1;

  //дFIFOʹ��
  assign wfifo_wen  = I_W_en & I_W_tvalid & wfifo_rst_done & (I_W_tuser | wfifo_sync_en);
  //FIFO ��λ
  wire wfifo_rst = (wrst_cnt >0) & (wrst_cnt <100) ;//֡ͬ���ڼ䣬��λ40��I_W_wclk������
	wire [10:0]wr_rcnt;
  wfifo #( 
      .DATA_WIDTH_W(W_DATAWIDTH), 
      .DATA_WIDTH_R(AXI_DATA_WIDTH), 
      .ADDR_WIDTH_W(W_WR_DATA_COUNT_WIDTH), 
      .ADDR_WIDTH_R(W_RD_DATA_COUNT_WIDTH), 
      .AL_FULL_NUM(WFIFO_DEPTH-2), 
      .AL_EMPTY_NUM(2), 
      .SHOW_AHEAD_EN(1'b1) , 
      .OUTREG_EN ("NOREG")
  ) wdbuf_fifo (
      .rst       ((I_ui_rstn == 1'b0) | wfifo_rst),
      .clkw      (I_W_wclk),
      .we        (wfifo_wen),
      .di        (I_W_tdata),
      .full_flag (O_W_full),
      .afull     (W_full_pro),
      .clkr      (I_ui_clk),
      .re        (I_fdma_wvalid),
      .dout      (O_fdma_wdata),
      .empty_flag(W_empty),
      .rdusedw   (W_rcnt),
      .wrusedw   (wr_rcnt)
  );

  //generate  if(ENABLE_READ == 1)begin : FDMA_READ// ͨ������ͨ��ʹ�ܣ������Ż������������
  localparam RYBUF_SIZE = (R_BUFSIZE - 1'b1);  //��ͨ����Ҫ��ɶ��ٴ�XSIZE����
  localparam RY_BURST_TIMES       = (R_YSIZE*R_XDIV); //��ͨ����Ҫ��ɵ�FDMA burst ����������XDIV���ڰ�XSIZE�ֽ��δ���
  localparam FDMA_RX_BURST        = (R_XSIZE*R_DATAWIDTH/AXI_DATA_WIDTH)/R_XDIV; //FDMA BURST һ�εĴ�С
  localparam RX_BURST_ADDR_INC    = (R_XSIZE*(R_DATAWIDTH/8))/R_XDIV; //FDMAÿ��burst֮��ĵ�ַ����
  localparam RX_LAST_ADDR_INC     = (R_XSTRIDE-R_XSIZE)*(R_DATAWIDTH/8) + RX_BURST_ADDR_INC; //����strideֵ����������һ�ε�ַ

  localparam RFIFO_DEPTH = R_BUFDEPTH*R_DATAWIDTH/AXI_DATA_WIDTH;//R_BUFDEPTH/(AXI_DATA_WIDTH/R_DATAWIDTH);
  localparam R_WR_DATA_COUNT_WIDTH = clog2(RFIFO_DEPTH);  //��ͨ��FIFO ���벿�����
  localparam R_RD_DATA_COUNT_WIDTH = clog2(R_BUFDEPTH);  //дͨ��FIFO����������


  assign O_fdma_rready = 1'b1;
  reg                                   O_fdma_rareq_r = 1'b0;
  (*mark_debug = "true"*) (* KEEP = "TRUE" *)reg  [                         1 : 0] R_MS = 0;
  reg  [            R_DSIZEBITS-1'b1:0] R_addr = 0;
  (*mark_debug = "true"*) (* KEEP = "TRUE" *)reg  [                          15:0] R_bcnt = 0;
  (*mark_debug = "true"*) (* KEEP = "TRUE" *)wire [R_WR_DATA_COUNT_WIDTH-1'b1 : 0] R_wcnt;
  (*mark_debug = "true"*) (* KEEP = "TRUE" *)reg                                   R_REQ = 0;
  reg  [                         5 : 0] rirq_dly_cnt = 0;
  reg  [                         3 : 0] rdiv_cnt = 0;
  reg  [                         7 : 0] rrst_cnt = 0;
  reg  [                         7 : 0] O_fdma_rbufn;
  assign O_fdma_rsize = FDMA_RX_BURST;
  assign O_fdma_rirq = (rirq_dly_cnt > 0);

  assign O_fdma_raddr = R_BASEADDR + {O_fdma_rbufn,R_addr};//����FPGA�߼����˷��Ƚϸ��ӣ����ͨ�����ø�λ��ַʵ�ֻ�������

  reg [1:0] R_MS_r = 0;
  always @(posedge I_ui_clk) R_MS_r <= R_MS;

  //ÿ��FDMA DBUF ���һ֡���ݴ���󣬲����жϣ�����жϳ���60�����ڵ�uiclk,������ӳٱ����㹻ZYNQ IP��ʶ������ж�
  always @(posedge I_ui_clk) begin
    if (I_ui_rstn == 1'b0) begin
      rirq_dly_cnt <= 6'd0;
      O_fdma_rbuf  <= 0;
    end else if ((R_MS_r == S_DATA2) && (R_MS == S_IDLE)) begin
      rirq_dly_cnt <= 60;
      O_fdma_rbuf  <= O_fdma_rbufn;
    end else if (rirq_dly_cnt > 0) rirq_dly_cnt <= rirq_dly_cnt - 1'b1;
  end


  assign O_fdma_rareq = O_fdma_rareq_r;

  reg rfifo_rst;
  //��ͨ��״̬��������4��״ֵ̬����
  always @(posedge I_ui_clk) begin
    if (!I_ui_rstn) begin
      R_MS           <= S_IDLE;
      R_addr         <= 0;
      O_R_sync_cnt   <= 0;
      R_bcnt         <= 0;
      rrst_cnt       <= 0;
      rdiv_cnt       <= 0;
      O_fdma_rbufn   <= 0;
     // O_fdma_rareq_r <= 1'd0;
    end else begin
      case (R_MS)  //֡ͬ�������ڷ���Ƶ����һ�㳣��Ϊ1
        S_IDLE: begin
          R_addr <= 0;
          R_bcnt <= 0;
          rrst_cnt <= 0;
          rdiv_cnt <= 0;
          R_MS <= S_RST;
         
          if (I_R_en) begin
            if(O_R_sync_cnt < RYBUF_SIZE) //���֡ͬ��������������Ҫ�ö�ͨ����֡ͬ����ʱ��ʹ��
              O_R_sync_cnt <= O_R_sync_cnt + 1'b1;
            else O_R_sync_cnt <= 0;
          end

        end
        S_RST: begin  //������û��֡ͬ�������Ա��뱣֤��ʼ������ͬ��
 		 O_fdma_rbufn <= I_R_buf;
          R_MS <= S_DATA1;

        end
        S_DATA1: begin
         // if (I_fdma_rbusy == 1'b0 && R_REQ) begin
         //   O_fdma_rareq_r <= 1'b1;
         // end 
          if (I_fdma_rbusy == 1'b1) begin
        //    O_fdma_rareq_r <= 1'b0;
            R_MS <= S_DATA2;
          end
        end
        S_DATA2: begin  //д��Ч����
          if (I_fdma_rbusy == 1'b0) begin
            if (R_bcnt == RY_BURST_TIMES - 1'b1)  //�ж��Ƿ������
              R_MS <= S_IDLE;
            else begin
              if(rdiv_cnt < R_XDIV - 1'b1)begin//�����XSIZE���˷ִδ��䣬һ��XSIZEҲ��ҪXDIV��FDMA��ɴ���
                R_addr   <= R_addr + RX_BURST_ADDR_INC;  //�����ַ����
                rdiv_cnt <= rdiv_cnt + 1'b1;
              end else begin
                R_addr <= R_addr + RX_LAST_ADDR_INC; //�������һ�ε�ַ���������һ�ε�ַ����stride ����
                rdiv_cnt <= 0;
              end
              R_bcnt <= R_bcnt + 1'b1;
              R_MS   <= S_DATA1;
            end
          end
        end
        default: R_MS <= S_IDLE;
      endcase
    end
  end

  //��ͨ��������FIFO��������ԭ�����xpm_fifo_async fifo����FIFO�洢�ռ����㹻���࣬����һ��FDMA��burst���ɷ�������
  (*mark_debug = "true"*) (* KEEP = "TRUE" *)wire R_empty;  //synthesis keep
  wire R_tvalid;  //synthesis keep
  assign R_tvalid = ~R_empty;


  always @(posedge I_ui_clk) R_REQ <= (R_wcnt < FDMA_RX_BURST - 1 );

  assign O_R_tvalid = ~R_empty & I_R_tready;

  //always @(posedge I_ui_clk) R_tvalid <= R_valid & I_ui_rstn; // ��� TVALID

  //���´������ڲ���tuser �� tlast�����ڶ�ͨ��������һ��������������󲻿ɾ�����һ���ڲ�ͨ������Ӳ�����⣬Ҳ�������
  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg r_tuser_lock;  //synthesis keep
  //(*mark_debug = "true"*) (* KEEP = "TRUE" *) reg r_tuser;
  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg r_tlast;  //synthesis keep
  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg [15:0] r_xcnt;  //synthesis keep
  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg fram_end;  //synthesis keep
  (*mark_debug = "true"*) (* KEEP = "TRUE" *) reg [15:0] r_ycnt;  //synthesis keep

  assign O_R_tuser = r_tuser_lock && O_R_tvalid;
  assign O_R_tlast = (r_xcnt == R_XSIZE - 1) & O_R_tvalid;

  always @(posedge I_R_rclk or negedge I_ui_rstn) begin
    if (~I_ui_rstn) r_xcnt <= 0;
    else if (O_R_tvalid) begin
      if (r_xcnt == R_XSIZE - 1) r_xcnt <= 0;
      else r_xcnt <= r_xcnt + 1'b1;
    end
  end

  always @(posedge I_R_rclk or negedge I_ui_rstn) begin
    if (~I_ui_rstn) begin
      r_tuser_lock <= 1'b1;
      r_ycnt <= 0;
    end else begin
      if (O_R_tlast) begin
        if (r_ycnt == R_YSIZE - 1) begin
          r_tuser_lock <= 1'b1;
          r_ycnt <= 0;
        end else r_ycnt <= r_ycnt + 1'b1;
      end else if (O_R_tuser) r_tuser_lock <= 1'b0;

    end
  end


  rfifo #( 
      .DATA_WIDTH_W(AXI_DATA_WIDTH), 
      .DATA_WIDTH_R(R_DATAWIDTH), 
      .ADDR_WIDTH_W(R_WR_DATA_COUNT_WIDTH), 
      .ADDR_WIDTH_R(R_RD_DATA_COUNT_WIDTH), 
      .AL_FULL_NUM(RFIFO_DEPTH-2), 
      .AL_EMPTY_NUM(2), 
      .SHOW_AHEAD_EN(1'b1) , 
      .OUTREG_EN ("NOREG")
  ) rdbuf_fifo (
      .rst       (I_ui_rstn == 1'b0),
      .clkw      (I_ui_clk),
      .we        (I_fdma_rvalid),
      .di        (I_fdma_rdata),
      .wrusedw   (R_wcnt),
      .clkr      (I_R_rclk),
      .re        (O_R_tvalid),
      .dout      (O_R_tdata),
      .empty_flag(R_empty)

  );
//    cwc cwc_inst
//  (
//  .probe0  (r_xcnt ),
//  .probe1  (r_ycnt   ),
//  .probe2  (O_R_tvalid  ),
//  .probe3  (O_R_tdata  ),
//  .probe4  (O_R_tlast   ),
//  .probe5  (O_R_tuser  ),
//  .clk(I_R_rclk)
//  );
reg [1:0]WR_S;

always @(posedge I_ui_clk) begin
    if(!I_ui_rstn)begin
        WR_S            <= 2'd0;
        O_fdma_wareq_r  <= 1'd0;
        O_fdma_rareq_r  <= 1'd0;
    end
    else begin
        case(WR_S)
        0:begin
         if(I_fdma_wbusy == 1'b0 && W_REQ && W_MS == S_DATA1)begin //����ִ��д
            O_fdma_wareq_r  <= 1'b1;
            WR_S            <= 2'd1;
         end  
         else if(I_fdma_rbusy == 1'b0 && R_REQ  && R_MS == S_DATA1)begin//���д��ɺ���ִ�ж�
            O_fdma_rareq_r  <= 1'b1;  
            WR_S            <= 2'd2;
         end
        end
        1:begin
            if(I_fdma_wbusy == 1'b1) begin //�ȴ�д���
                O_fdma_wareq_r  <= 1'b0;
                WR_S            <= 3;
            end
        end          
        2:begin
            if(I_fdma_rbusy == 1'b1) begin //�ȴ������
                O_fdma_rareq_r  <= 1'b0;
                WR_S    <= 3;
            end            
        end
        3:begin
            if(I_fdma_wbusy==0&&I_fdma_rbusy==0)
                WR_S    <= 0;
        end
        default: WR_S <= 0;
        endcase
    end
end  






endmodule

