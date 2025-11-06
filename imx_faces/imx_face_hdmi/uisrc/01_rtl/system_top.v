`timescale 1ns / 1ns 
`define DRAM_BYTE_NUM 4    // 1 = x8, 2 = x16,4 = x32,8=x64
`define DRAM_SIZE    "4G"     // AP106,AP102=2G ,AP104=4G    1G , 2G , 4G = 256x16bit, 8G    ,ONE DDR particle capacity

//`define XLNX_NATIVE
//`define ALC_NATIVE  
`define MC_AXI  
 
//`define AXI_ATG  
//`define ATG   
//`define DFI

module system_top#(
parameter DRAM_TYPE       = "DDR3"  ,            //"DDR4" "DDR3"
parameter ECC             = "OFF",
parameter APP_ADDR_WIDTH  = (`DRAM_SIZE=="1G")?26:(`DRAM_SIZE=="2G")?27:(`DRAM_SIZE == "4G")?28:(`DRAM_SIZE == "8G")?29:28, //512Mx16bit=29 ,256Mx16bit=28 ,128Mx16bit=27,64Mx16bit = 26,
parameter AXI_ID_WIDTH    =  4,                                                                                   
parameter APP_DATA_WIDTH  = (ECC == "ON")? (`DRAM_BYTE_NUM-1)*8*8 : `DRAM_BYTE_NUM*8*8,
parameter APP_MASK_WIDTH  = (ECC == "ON")? (`DRAM_BYTE_NUM-1)*8   : `DRAM_BYTE_NUM*8,
parameter AXI_ADDR_WIDTH  = APP_ADDR_WIDTH+4,
parameter AXI_DATA_WIDTH  = APP_DATA_WIDTH,
parameter DQ_WIDTH        = `DRAM_BYTE_NUM * 8,
parameter DQS_WIDTH       = `DRAM_BYTE_NUM,
parameter DM_WIDTH        = `DRAM_BYTE_NUM,
parameter ADDR_WIDTH      = (DRAM_TYPE=="DDR4")?17:(`DRAM_SIZE=="1G")?13:(`DRAM_SIZE=="2G")?14:(`DRAM_SIZE == "4G")?15:(`DRAM_SIZE == "8G")?16:15, // 512Mx16bit=16 ,256Mx16bit=15,128Mx16bit=14,64Mx16bit=13
parameter ROW_WIDTH       = (`DRAM_SIZE=="1G")?13:(`DRAM_SIZE=="2G")?14:(`DRAM_SIZE == "4G")?15:(`DRAM_SIZE == "8G")?16:15,                        // 512Mx16bit=16 ,256Mx16bit=15,128Mx16bit=14,64Mx16bit=13
parameter COL_WIDTH       = 10,                  //
parameter BA_WIDTH        = 3,                   //
parameter BG_WIDTH        = 1,                   //
parameter ODT_WIDTH       = 1,                   // PP phy 2, single phy 1
parameter CKE_WIDTH       = 1,                   // PP phy 2, single phy 1
parameter CS_WIDTH        = 1                    // PP phy 2, single phy 1
)
(
input wire            			I_sys_clk_25m,
input wire            			I_ddr_clk	,
output    [ADDR_WIDTH-1:0]      ddr_addr    , 
output    [  BA_WIDTH-1:0]      ddr_ba      ,
output    [ CKE_WIDTH-1:0]      ddr_cke     ,
output    [ ODT_WIDTH-1:0]      ddr_odt     ,
output    [  CS_WIDTH-1:0]      ddr_cs_n    ,
output                          ddr_ras_n   ,
output                          ddr_cas_n   ,
output                          ddr_we_n    ,
output                          ddr_ck_p    ,
output                          ddr_ck_n    ,
output                          ddr_reset_n ,
inout     [  DM_WIDTH-1:0]      ddr_dm  	,	
inout     [  DQ_WIDTH-1:0]      ddr_dq      ,
inout     [ DQS_WIDTH-1:0]      ddr_dqs_n   ,
inout     [ DQS_WIDTH-1:0]      ddr_dqs_p   ,


input  wire   [1:0]				I_button	,
inout  wire            			IO_cam_sda	,
output wire           			O_cam_scl	,
output wire           			O_clk_24m	,
output wire   [2:0]   			O_hdmi_tx_p	,
output wire           			O_hdmi_clk_p
);

wire        S_rst;
wire        pclkx1;
wire        pclkx5;
wire 		S_pll_lock;
assign S_rst = ~S_pll_lock;
wire        clk_24m;

pll u_pll(
.refclk   ( I_sys_clk_25m          ),
.lock     ( S_pll_lock             ),
 
.clk0_out ( pclkx1                 ),
.clk1_out ( pclkx5                 ),
.clk2_out ( S_clk_70m              ),
.clk3_out ( clk_24m              )
);

wire [7:0]ae;//synthesis keep
wire cam_cfg_done,ae_cfg_done;
wire ae_req;

//手动配置相机AE
ae_set u_ae_set(
.I_clk(clk_24m),
.I_rst(S_pll_lock),
.I_btn(~I_button),
.I_cam_cfg_done(cam_cfg_done),
.I_ae_cfg_done(ae_cfg_done),
.O_ae_req(ae_req),
.O_ae(ae)
);

u_imx_415#
(
.CLK_DIV(24_000_000/100_000-1)
)
u_imx_415_inst
(
.I_clk(clk_24m),  
.I_rst_n(S_pll_lock),  
.I_ae_req(ae_req),
.I_ae_data(ae),
.O_cam_scl(O_cam_scl), 
.IO_cam_sda(IO_cam_sda), 
.O_cfg_done(cam_cfg_done),
.O_ae_cfg_done(ae_cfg_done)

);

  PH1_LOGIC_ODDR CMOS_CLK (
      .q  (O_clk_24m),  //output 125mhz�?1gbps�? 25mhz(100mbps)    2.5mhz(10mbps)
      .clk(clk_24m),
      .d0 (1'b1),
      .d1 (1'b0),
      .rst(1'b0)
  );

wire        I_lp_tx_en     ;
wire        I_lp_tx_lane0_p;
wire        I_lp_tx_lane0_n;
wire        S_hs_rx_clk;           //synthesis keep  
wire        S_hs_rx_valid;         //synthesis keep  
wire [31:0] S_hs_rx_data;          //synthesis keep
wire [1:0]  S_lane_error;          //synthesis keep
wire [7:0]  S_clk_lane_idelay  ;
wire [8:0]  S_data_lane0_idelay;
wire [8:0]  S_data_lane1_idelay;
wire [8:0]  S_data_lane2_idelay;
wire [8:0]  S_data_lane3_idelay;
// assign S_data_lane1_idelay = 0;
// assign S_data_lane0_idelay = 0;
// assign S_clk_lane_idelay   = 20;

mipi_dphy_rx_ph1a_mipiio_wrapper#(
.LANE_NUM              ( 4 ),
.BYTE_NUM              ( 1 )
)u_mipi_dphy_rx_ph1a_mipiio_wrapper(
.I_lp_clk              ( S_clk_70m    ),
.I_rst                 ( S_rst        ),

.I_clk_lane_in_delay   ( S_clk_lane_idelay     ),
.I_data_lane0_in_delay ( S_data_lane0_idelay   ),
.I_data_lane1_in_delay ( S_data_lane1_idelay   ),
.I_data_lane2_in_delay ( S_data_lane2_idelay  ),
.I_data_lane3_in_delay ( S_data_lane3_idelay  ),

.I_lane_invert         ( 4'b0000         ),

.O_hs_rx_clk           ( S_hs_rx_clk     ),
.O_hs_rx_valid         ( S_hs_rx_valid   ),
.O_hs_rx_data          ( S_hs_rx_data    ),

.I_lp_tx_en            (1'b0 ),
.I_lp_tx_lane0_p       (1'b0 ),
.I_lp_tx_lane0_n       (1'b0 ),

.O_lane_error          ( S_lane_error    )
);


wire        S_csi_frame_start;       
wire        S_csi_frame_end;         
wire        S_csi_valid;             
wire[31:0]  S_csi_data;  

//csi 解码为RAW数据
csi_unpacket_4lane u_csi_unpacket(
.I_clk                 ( S_hs_rx_clk       ),
.I_rst_n               ( S_pll_lock        ),
.I_hs_valid            ( S_hs_rx_valid     ),
.I_hs_data             ( S_hs_rx_data      ),

.O_csi_frame_start     ( S_csi_frame_start ),
.O_csi_frame_end       ( S_csi_frame_end   ),
.O_csi_valid           ( S_csi_valid       ),
.O_csi_data            ( S_csi_data        )
);


wire        S_raw10_frame_start; 
wire        S_raw10_frame_end  ;   
wire        S_raw10_valid      ;       
wire [39:0] S_raw10_data       ;

//解码RAW10
raw10_unpacket_4lane u_raw10_unpacket (
.I_clk  (S_hs_rx_clk),
.I_rst_n(S_pll_lock),

.I_csi_frame_start(S_csi_frame_start),
.I_csi_frame_end  (S_csi_frame_end),
.I_csi_valid      (S_csi_valid),
.I_csi_data       (S_csi_data),

.O_raw10_frame_start(S_raw10_frame_start),
.O_raw10_frame_end  (S_raw10_frame_end  ),
.O_raw10_valid      (S_raw10_valid      ),
.O_raw10_data       (S_raw10_data       )

);
wire [39:0]	axis_tdata ;
wire 		axis_tvalid;  
wire 		axis_tlast;  
wire 		axis_tuser; 
//图像裁剪纠�??
image_correction #(
    .DATA_WIDTH  (40),
    .TDEST_WIDTH (10)
)image_correction
(
    /*input                          */.I_clk            (S_hs_rx_clk),
    /*input                          */.I_rst_n          (S_pll_lock),

    /*input    [DATA_WIDTH - 1:0]    */.I_raw_data       (S_raw10_data       ),       
    /*input                          */.I_raw_valid      (S_raw10_valid      ),     
    /*input                          */.I_raw_frame_start(S_raw10_frame_start),
    /*input                          */.I_raw_frame_end  (S_raw10_frame_end  ),
    /*// 输出RAW10数据
    /*output     [DATA_WIDTH - 1:0]  */.O_raw_tdata (axis_tdata ),
    /*output                         */.O_raw_tlast (axis_tlast ),
    /*output reg [TDEST_WIDTH - 1:0] */.O_raw_tdest (           ),
    /*output                         */.O_raw_tvalid(axis_tvalid),
    /*output                         */.O_raw_tuser (axis_tuser )

);

wire			ISP_O_tready;
wire [127:0]	ISP_O_tdata ;
wire 			ISP_O_tlast ;
wire 			ISP_O_tuser ;
wire 			ISP_O_tvalid;
//ISP图像处理
isp_top u_isp_top (
.axi4s_video_aclk(S_hs_rx_clk),
.I_rst_n         (S_pll_lock),
.I_tlast         (axis_tlast ),
.I_tuser         (axis_tuser ),
.I_tdata         (axis_tdata ),
.I_tvalid        (axis_tvalid),
.I_tdest         (),
.O_tready        (ISP_O_tready),//input
.O_tdata         (ISP_O_tdata ),
.O_tlast         (ISP_O_tlast ),
.O_tuser         (ISP_O_tuser ),
.O_tvalid        (ISP_O_tvalid),
.I_tready        ()
  );
 
wire  o_face_last ;
wire  o_face_user ; 
wire  o_face_valid;
wire [127:0]  o_face_data;

face_recognition # (
    .R_VALUE(255),
    .G_VALUE(0 ),
    .B_VALUE(0 ),
    .H_ActiveSize(1920),
    .H_FrameSize(1920+88+44+148 ),
    .H_SyncStart(1920+88),
    .H_SyncEnd(1920+88+44),
    .H_FRONT_PORCH(88),
    .H_SYNC_TIME(44),
    .H_BACK_PORCH(148),
    .V_ActiveSize(1080),
    .V_FrameSize(1080+4+5+36 ),
    .V_SyncStart(1080+4),
    .V_SyncEnd(1080+4+5),
    .V_FRONT_PORCH(4),
    .V_SYNC_TIME(5),
    .V_BACK_PORCH(36)
  )
  face_recognition_inst (
    .i_clk(S_hs_rx_clk),
    .i_rst_n(S_pll_lock),
    .i_isp_data(ISP_O_tdata),
    .I_tlast (ISP_O_tlast ),
    .I_tuser (ISP_O_tuser ),
    .I_tvalid(ISP_O_tvalid),
    .o_last  (o_face_last ),
    .o_user  (o_face_user ),
    .o_valid (o_face_valid),
    .o_data  (o_face_data)
  );


//    cwc cwc_inst
//  (
//  .probe0  (S_hs_rx_valid),
//  .probe1  (S_hs_rx_data ),
//  .probe2  (axis_tdata ),
//  .probe3  (axis_tlast ),
//  .probe4  (axis_tvali),
//  .probe5  (axis_tuser),
//  .clk(S_hs_rx_clk)
//  );

//-------- User Clock --------//
wire                           pll_locked ;
wire                           ddr_init_cal_done  ;
wire                           dfi_clk;
wire    [  3:0]                dfi_reset_n ;
wire    [  CKE_WIDTH*4-1:0]    dfi_cke;
wire    [  ODT_WIDTH*4-1:0]    dfi_odt;
wire    [  CS_WIDTH *4-1:0]    dfi_cs_n;
wire    [  3:0]                dfi_ras_n;
wire    [  3:0]                dfi_cas_n;
wire    [  3:0]                dfi_act_n;
wire    [  3:0]                dfi_we_n;
wire    [  BA_WIDTH*4-1 :0]    dfi_bank;
wire    [  BG_WIDTH*4-1 :0]    dfi_bg;
wire    [  ADDR_WIDTH*4-1:0]   dfi_address;
wire    [  DQS_WIDTH*4-1:0]    dfi_wrdata_en;
wire    [  DQ_WIDTH*8-1:0]     dfi_wrdata;
wire    [  DM_WIDTH*8-1:0]     dfi_wrdata_mask;
wire    [  DQS_WIDTH*4-1:0]    dfi_rddata_en;
wire    [  DQS_WIDTH*4-1:0]    dfi_rddata_valid;
wire    [  DQ_WIDTH*8-1:0]     dfi_rddata;
wire    [  DM_WIDTH*8-1:0]     dfi_rddata_dbi_n;

reg                            init_cal_done_d;
reg                            init_cal_done;

//����APP�ӿ�תAXI�ӿ�

// AXI Write Addr
wire [AXI_ADDR_WIDTH-1:0]      axi_awaddr  ;
wire                           axi_awvalid ;
wire                           axi_awready ;
wire   [AXI_ID_WIDTH-1:0]      axi_awid    ;
wire                [7:0]      axi_awlen   ; 
wire                [2:0]      axi_awsize  ; 
wire                [1:0]      axi_awburst ; 
wire                [0:0]      axi_awlock  ; 
wire                [3:0]      axi_awcache ; 
wire                [2:0]      axi_awprot  ; 
wire                [3:0]      axi_awqos   ;
// AXI Write Data              
wire [APP_DATA_WIDTH-1:0]      axi_wdata   ;
wire [APP_MASK_WIDTH-1:0]      axi_wstrb   ;
wire                           axi_wvalid  ;
wire                           axi_wlast   ;
wire                           axi_wready  ;
// Write Response Port         
wire   [AXI_ID_WIDTH-1:0]      axi_bid     ;    
wire                [1:0]      axi_bresp   ;    
wire                           axi_bvalid  ;    
wire                           axi_bready  ;    
                               
// AXI Read Addr               
wire [AXI_ADDR_WIDTH-1:0]      axi_araddr  ;
wire                           axi_arvalid ;
wire                           axi_arready ;
wire [  AXI_ID_WIDTH-1:0]      axi_arid    ;
wire                [7:0]      axi_arlen   ;
wire                [2:0]      axi_arsize  ;
wire                [1:0]      axi_arburst ;
wire                [0:0]      axi_arlock  ;
wire                [3:0]      axi_arcache ;
wire                [2:0]      axi_arprot  ;
wire                [3:0]      axi_arqos   ;
// AXI Read Data               
wire [APP_DATA_WIDTH-1:0]      axi_rdata   ;
wire                           axi_rlast   ;
wire                           axi_rvalid  ;
wire                           axi_rready  ;
wire   [AXI_ID_WIDTH-1:0]      axi_rid     ;
wire                [1:0]      axi_rresp   ;

//===== DDR3 PHY INS =====//
ddr_ip u_ddr_phy (
`ifndef DFI
        .sys_clk                    ( I_ddr_clk      ),
        .sys_rst_n                  (   1        ),
`else
        .sys_clk_p                  ( I_ddr_clk      ),
        .sys_rstn                   (   1        ),
`endif
        .dfi_clk                    ( dfi_clk          ), 
        .pll_locked                 ( pll_locked       ),
//        .user_clk0                  (                  ),
         //DDR bus signals                             
        .ddr_addr                   ( ddr_addr         ),
        .ddr_ba                     ( ddr_ba           ),
        //.ddr_bg                     ( ddr_bg           ),
        .ddr_ck_n                   ( ddr_ck_n         ),
        .ddr_ck_p                   ( ddr_ck_p         ),
        .ddr_ras_n                  ( ddr_ras_n        ),
        .ddr_cas_n                  ( ddr_cas_n        ),
        .ddr_we_n                   ( ddr_we_n         ),  
        //.ddr_act_n                  ( ddr_act_n        ),
        .ddr_cke                    ( ddr_cke          ),
        .ddr_cs_n                   ( ddr_cs_n         ),
        .ddr_dm                     ( ddr_dm ),        
        .ddr_odt                    ( ddr_odt          ),
        .ddr_reset_n                ( ddr_reset_n      ),
        .ddr_dq                     ( ddr_dq           ),
        .ddr_dqs_n                  ( ddr_dqs_n        ),
        .ddr_dqs_p                  ( ddr_dqs_p        ),  

        .uart_txd                   ( O_uart_txd         ),
        .uart_rxd                   ( I_uart_rxd         ),
        .ddr_init_cal_done          ( ddr_init_cal_done    ),

`ifdef DFI
         // DFI bus signals, between hard 
         // controller and users or top-level systems  
        .dfi_reset_n                ( dfi_reset_n      ),
        .dfi_cke                    ( dfi_cke          ),
        .dfi_odt                    ( dfi_odt          ),
        .dfi_cs_n                   ( dfi_cs_n         ),
        .dfi_ras_n                  ( dfi_ras_n        ),
        .dfi_cas_n                  ( dfi_cas_n        ),
        .dfi_we_n                   ( dfi_we_n         ),
        //.dfi_act_n                  ( dfi_act_n        ),
        .dfi_bank                   ( dfi_bank         ),
        //.dfi_bg                     ( dfi_bg           ),
        .dfi_address                ( dfi_address      ),
        .dfi_wrdata_en              ( dfi_wrdata_en    ),
        .dfi_wrdata                 ( dfi_wrdata       ),
        .dfi_wrdata_mask            ( dfi_wrdata_mask  ), 
        .dfi_rddata_en              ( dfi_rddata_en    ),
        .dfi_rddata_valid           ( dfi_rddata_valid ),
        .dfi_rddata                 ( dfi_rddata       ),
        .dfi_rddata_dbi_n           ( dfi_rddata_dbi_n ), 
        .dfi_ctrlupd_req            ( 2'b00            ),
        .dfi_ctrlupd_ack            (                  ),
        .dfi_phyupd_req             (                  ),
        .dfi_phyupd_ack             ( 2'h0             ),
        .dfi_phyupd_type            (                  )

`elsif MC_AXI  
 // Write Addr Ports                            
        .axi_awaddr                 ( axi_awaddr       ),
        .axi_awvalid                ( axi_awvalid      ),
        .axi_awready                ( axi_awready      ),
                                          
        .axi_awid                   ( axi_awid         ),
        .axi_awlen                  ( axi_awlen        ),
        .axi_awsize                 ( axi_awsize       ),
        .axi_awburst                ( axi_awburst      ),
        .axi_awlock                 ( axi_awlock       ),
        .axi_awcache                ( axi_awcache      ),
        .axi_awprot                 ( axi_awprot       ),
        .axi_awqos                  ( axi_awqos        ),
                                                
        // Write Data Port                             
        .axi_wdata                  ( axi_wdata        ),
        .axi_wstrb                  ( axi_wstrb        ),
        .axi_wvalid                 ( axi_wvalid       ),
        .axi_wlast                  ( axi_wlast        ),
        .axi_wready                 ( axi_wready       ),
        // Write Response Port                         
        .axi_bid                    ( axi_bid          ),
        .axi_bresp                  ( axi_bresp        ),
        .axi_bvalid                 ( axi_bvalid       ),
        .axi_bready                 ( axi_bready       ),
        // Read Address Ports                          
        .axi_araddr                 ( axi_araddr       ),
        .axi_arvalid                ( axi_arvalid      ),
        .axi_arready                ( axi_arready      ),
                                          
        .axi_arid                   ( axi_arid         ),
        .axi_arlen                  ( axi_arlen        ),
        .axi_arsize                 ( axi_arsize       ),
        .axi_arburst                ( axi_arburst      ),
        .axi_arlock                 ( axi_arlock       ),
        .axi_arcache                ( axi_arcache      ),
        .axi_arprot                 ( axi_arprot       ),
        .axi_arqos                  ( axi_arqos        ),
                                                 
        // Read Data Ports                                                         
        .axi_rid                    ( axi_rid          ),
        .axi_rresp                  ( axi_rresp        ),                                       
        .axi_rdata                  ( axi_rdata        ),
        .axi_rlast                  ( axi_rlast        ),
        .axi_rvalid                 ( axi_rvalid       ),
        .axi_rready                 ( axi_rready       )
  `else
        // Native
        .paxi_awaddr        ( axi_awaddr       ),
        .paxi_awvalid       ( axi_awvalid      ),
        .paxi_awready       ( axi_awready      ),
        
        .paxi_wdata         ( axi_wdata        ),
        .paxi_wstrb         ( axi_wstrb        ),
        .paxi_wvalid        ( axi_wvalid       ),
        .paxi_wlast         ( axi_wlast        ),
        .paxi_wready        ( axi_wready       ),
        
         // Write Response Port
        .paxi_bid           ( axi_bid          ),
        .paxi_bresp         ( axi_bresp        ),
        .paxi_bvalid        ( axi_bvalid       ),
        .paxi_bready        ( axi_bready       ),
         // Read Address Ports
        .paxi_araddr        ( axi_araddr       ),
        .paxi_arvalid       ( axi_arvalid      ),
        .paxi_arready       ( axi_arready      ),
        
         // Read Data Ports
        .paxi_rdata         ( axi_rdata        ),
        .paxi_rlast         ( axi_rlast        ),
        .paxi_rvalid        ( axi_rvalid       ),
        .paxi_rready        ( axi_rready       )

`endif 
);

wire [AXI_ADDR_WIDTH-1:  0]      fdma_waddr;    //FDMA写通道地址
wire                             fdma_wareq;    //FDMA写通道请求
wire [15: 0]                     fdma_wsize;    //FDMA写通道一�?FDMA的传输大�?                               
wire                             fdma_wbusy;    //FDMA处于BUSY状态，AXI总线正在写操�? 	
wire [AXI_DATA_WIDTH-1 : 0]      fdma_wdata;    //FDMA写数�?
wire                             fdma_wvalid;   //FDMA 写有�?
wire                             fdma_wready;   //FDMA写准备好，用户可以写数据
                                                  
wire [AXI_ADDR_WIDTH-1:  0]      fdma_raddr;    //FDMA读通道地址
wire                             fdma_rareq;    //FDMA读通道请求
wire [15: 0]                     fdma_rsize;    //FDMA读通道一�?FDMA的传输大�?                                 
wire                             fdma_rbusy;    //FDMA处于BUSY状态，AXI总线正在读操�? 		
wire [AXI_DATA_WIDTH-1 : 0]      fdma_rdata;    //FDMA读数�?
wire                             fdma_rvalid;   //FDMA 读有�?
wire                             fdma_rready;   //FDMA读准备好，用户可以�?�数�?	
wire                             test_error;   


//例化米联�?uiFDMA AXI 控制�? IP
uiFDMA#
(
.M_AXI_ID(0)                        ,//ID,demo�?没用�?
.M_AXI_ID_WIDTH(AXI_ID_WIDTH)       ,//ID,demo�?没用�?
.M_AXI_ADDR_WIDTH(AXI_ADDR_WIDTH)		,//内存地址位�??
.M_AXI_DATA_WIDTH(AXI_DATA_WIDTH)		,//AXI总线的数�?位�??
.M_AXI_MAX_BURST_LEN (16)            //AXI总线的burst 大小，�?�于AXI4，支持任意长度，对于AXI3以下最�?1
)
uiFDMA_inst
(
.I_fdma_waddr(fdma_waddr)          ,//FDMA写通道地址
.I_fdma_wareq(fdma_wareq)          ,//FDMA写通道请求
.I_fdma_wsize(fdma_wsize)          ,//FDMA写通道一�?FDMA的传输大�?                                   
.O_fdma_wbusy(fdma_wbusy)          ,//FDMA处于BUSY状态，AXI总线正在写操�?   
				
.I_fdma_wdata(fdma_wdata)		   ,//FDMA写数�?
.O_fdma_wvalid(fdma_wvalid)        ,//FDMA 写有�?
.I_fdma_wready(1'b1)		       ,//FDMA写准备好，用户可以写数据

.I_fdma_raddr(fdma_raddr)          ,// FDMA读通道地址
.I_fdma_rareq(fdma_rareq)          ,// FDMA读通道请求
.I_fdma_rsize(fdma_rsize)          ,// FDMA读通道一�?FDMA的传输大�?                                     
.O_fdma_rbusy(fdma_rbusy)          ,// FDMA处于BUSY状态，AXI总线正在读操�? 
				
.O_fdma_rdata(fdma_rdata)		   ,// FDMA读数�?
.O_fdma_rvalid(fdma_rvalid)        ,// FDMA 读有�?
.I_fdma_rready(1'b1)		       ,// FDMA读准备好，用户可以�?�数�?
//以下为AXI总线信号	
.M_AXI_ACLK                             (dfi_clk),
.M_AXI_ARESETN                          (ddr_init_cal_done),
// Master Interface Write Address Ports
.M_AXI_AWID                             (axi_awid),
.M_AXI_AWADDR                           (axi_awaddr),
.M_AXI_AWLEN                            (axi_awlen),
.M_AXI_AWSIZE                           (axi_awsize),
.M_AXI_AWBURST                          (axi_awburst),
.M_AXI_AWLOCK                           (),
.M_AXI_AWCACHE                          (axi_awcache),
.M_AXI_AWPROT                           (axi_awprot),
.M_AXI_AWQOS                            (),
.M_AXI_AWVALID                          (axi_awvalid),
.M_AXI_AWREADY                          (axi_awready),
// Master Interface Write Data Ports
.M_AXI_WDATA                            (axi_wdata),
.M_AXI_WSTRB                            (axi_wstrb),
.M_AXI_WLAST                            (axi_wlast),
.M_AXI_WVALID                           (axi_wvalid),
.M_AXI_WREADY                           (axi_wready),
// Master Interface Write Response Ports
.M_AXI_BID                              (axi_bid),
.M_AXI_BRESP                            (axi_bresp),
.M_AXI_BVALID                           (axi_bvalid),
.M_AXI_BREADY                           (axi_bready),
// Master Interface Read Address Ports
.M_AXI_ARID                             (axi_arid),
.M_AXI_ARADDR                           (axi_araddr),
.M_AXI_ARLEN                            (axi_arlen),
.M_AXI_ARSIZE                           (axi_arsize),
.M_AXI_ARBURST                          (axi_arburst),
.M_AXI_ARLOCK                           (),
.M_AXI_ARCACHE                          (axi_arcache),
.M_AXI_ARPROT                           (),
.M_AXI_ARQOS                            (),
.M_AXI_ARVALID                          (axi_arvalid),
.M_AXI_ARREADY                          (axi_arready),
// Master Interface Read Data Ports
.M_AXI_RID                              (axi_rid),
.M_AXI_RDATA                            (axi_rdata),
.M_AXI_RRESP                            (axi_rresp),
.M_AXI_RLAST                            (axi_rlast),
.M_AXI_RVALID                           (axi_rvalid),
.M_AXI_RREADY                           (axi_rready)		
);

wire [7:0] wbuf_sync,rbuf_sync;

//设置3帧缓存，读延迟写1�?
uisetvbuf#(
.BUF_DELAY(1),
.BUF_LENTH(3)
)
uisetvbuf_u
(
.I_bufn(wbuf_sync),
.O_bufn(rbuf_sync)
);

wire fdma_I_R_tready;       
wire fdma_O_R_tuser;
wire fdma_O_R_tvalid;       
wire [31:0] fdma_O_R_tdata; 
wire fdma_O_R_tlast;

wire vtc_de_valid;  //VTC数据有效信号
wire vtc_user;      //VTC帧起始信�?
wire vtc_last;      //VTC行结束信�?

assign fdma_I_R_tready = vtc_de_valid;


uidbuf# (

.AXI_DATA_WIDTH(AXI_DATA_WIDTH),
.AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),

.W_BUFDEPTH(2048),
.W_DATAWIDTH(128),
.W_BASEADDR(0),
.W_DSIZEBITS(23),
.W_XSIZE(480),
.W_XSTRIDE(480),
.W_YSIZE(1080),
.W_XDIV(6),
.W_BUFSIZE(3),

.R_BUFDEPTH(2048),
.R_DATAWIDTH(32),
.R_BASEADDR(0),
.R_DSIZEBITS(23),
.R_XSIZE(1920),
.R_XSTRIDE(1920),
.R_YSIZE(1080),
.R_XDIV(6),
.R_BUFSIZE(3)
)
uidbuf_u0
(
.I_ui_clk(dfi_clk),
.I_ui_rstn(ddr_init_cal_done),

.I_W_en      (1),
.I_W_wclk    (S_hs_rx_clk),    
.I_W_tuser   (o_face_user),
.I_W_tvalid  (o_face_valid),                              
.I_W_tdata   (o_face_data),
.I_W_tlast   (o_face_last),
.O_W_tready  (ISP_O_tready),
.O_W_sync_cnt(wbuf_sync),
.I_W_buf     (wbuf_sync),

.I_R_en      (1),
.I_R_rclk    (pclkx1),
.I_R_tready  (fdma_I_R_tready),//o_vtc
.O_R_tuser   (fdma_O_R_tuser),
.O_R_tvalid  (fdma_O_R_tvalid),
.O_R_tdata   (fdma_O_R_tdata),
.O_R_tlast   (fdma_O_R_tlast),
.O_R_sync_cnt(),
.I_R_buf     (rbuf_sync),

.O_fdma_waddr (fdma_waddr),
.O_fdma_wareq (fdma_wareq),
.O_fdma_wsize (fdma_wsize),
.I_fdma_wbusy (fdma_wbusy),
.O_fdma_wdata (fdma_wdata),
.I_fdma_wvalid(fdma_wvalid),
.O_fdma_wready(fdma_wready),
.O_fdma_raddr (fdma_raddr),
.O_fdma_rareq (fdma_rareq),
.O_fdma_rsize (fdma_rsize),
.I_fdma_rbusy (fdma_rbusy),
.I_fdma_rdata (fdma_rdata),
.I_fdma_rvalid(fdma_rvalid),
.O_fdma_rready(fdma_rready)
//.O_fmda_wbuf  	(fdma_wbuf	),	
//.O_fdma_wirq  	(fdma_wirq	),		
//.O_fmda_rbuf  	(fdma_rbuf	),	
//.O_fdma_rirq  	(fdma_rirq	)
);

wire  o_face_last;
wire  o_face_user;
wire  o_face_valid;
wire  [23:0] o_face_data;

wire [23:0] fdma_O_R_tdata_24;


assign fdma_O_R_tdata_24= fdma_O_R_tdata[23:0];

reg [20:0] fifowait;  //synthesis keep  
  always @(posedge pclkx1 or negedge ddr_init_cal_done) begin
    if (ddr_init_cal_done == 'b0) fifowait <= 'b0;
    else if (fifowait[20] == 0) fifowait <= fifowait + 1;
    else fifowait <= fifowait;
  end
uivtc #(
 //1080P @ 137.5M
.H_ActiveSize       (1920), //视�?�时间参�?,行�?��?�信号，一行有�?(需要显示的部分)像素所占的时钟数，一�?时钟对应一�?有效像素
.H_SyncStart        (1920+88), //视�?�时间参�?,行同步开始，即�?�少时钟数后开始产生�?�同步信�? 
.H_SyncEnd          (1920+88+44),//视�?�时间参�?,行同步结束，即�?�少时钟数后停�??产生行同步信号，之后就是行有效数�?部分
.H_FrameSize        (1920+88+44+16), //视�?�时间参�?,行�?��?�信号，一行�?��?�信号总�?�占用的时钟�?
.V_ActiveSize       (1080),//视�?�时间参�?,场�?��?�信号，一帧图像所占用的有�?(需要显示的部分)行数量，通常说的视�?�分辨率即H_ActiveSize*V_ActiveSize
.V_SyncStart        (1080+4),//视�?�时间参�?,场同步开始，即�?�少行数后开始产生场同�?�信�? 
.V_SyncEnd          (1080+4+5), //视�?�时间参�?,场同步结束，多少行后停�??产生长同步信�?  
.V_FrameSize        (1080+4+5+19) //视�?�时间参�?,场�?��?�信号，一帧�?��?�信号总�?�占用的行数�?   
)
uivtc_inst (
.I_vtc_clk(pclkx1),  //系统时钟
.I_vtc_rstn(fifowait[20]),
.O_vtc_vs  (),//场同步输�?
.O_vtc_hs  (),//行同步输�?
.O_vtc_de_valid(vtc_de_valid),//视�?�数�?有效
.O_vtc_user(vtc_user),    //满足stream时序产生 user 信号,用于帧同�?
.O_vtc_last(vtc_last)     //满足stream时序产生 later 信号,用于每�?�结�?
);
  
  
//wire I_video_in_user;  //synthesis keep  
//wire I_video_in_valid;  //synthesis keep  
//wire I_video_in_last;  //synthesis keep  
//wire [23:0] I_video_in_data;  //synthesis keep  
  
assign I_video_in_user  = fdma_O_R_tuser;  //��Ƶ����֡��ʼ�ź�
assign I_video_in_valid = fdma_O_R_tvalid  ;  //��Ƶ������Ч�ź�
assign I_video_in_last  = fdma_O_R_tlast;  //��Ƶ�����н����ź�
assign I_video_in_data  = fdma_O_R_tdata_24;  //��Ƶ��������

wire I_video_in_user;   
wire I_video_in_valid;  
wire I_video_in_last; 
wire [23:0] I_video_in_data;  
  
//assign I_video_in_user  = o_face_user; //视�?�输入帧起�?�信�?
//assign I_video_in_valid = o_face_valid;   //视�?�输入有效信�?
//assign I_video_in_last  = o_face_last; //视�?�输入�?�结束信�?
//assign I_video_in_data  = o_face_data; //视�?�输入数�?

//hdmi 输出IP
hdmi_tx#(
 //HDMI视�?�参数�?�置   
 //1080P @ 137.5M
.H_ActiveSize       (1920), //视�?�时间参�?,行�?��?�信号，一行有�?(需要显示的部分)像素所占的时钟数，一�?时钟对应一�?有效像素
.H_SyncStart        (1920+88), //视�?�时间参�?,行同步开始，即�?�少时钟数后开始产生�?�同步信�? 
.H_SyncEnd          (1920+88+44),//视�?�时间参�?,行同步结束，即�?�少时钟数后停�??产生行同步信号，之后就是行有效数�?部分
.H_FrameSize        (1920+88+44+16), //视�?�时间参�?,行�?��?�信号，一行�?��?�信号总�?�占用的时钟�?
.V_ActiveSize       (1080),//视�?�时间参�?,场�?��?�信号，一帧图像所占用的有�?(需要显示的部分)行数量，通常说的视�?�分辨率即H_ActiveSize*V_ActiveSize
.V_SyncStart        (1080+4),//视�?�时间参�?,场同步开始，即�?�少行数后开始产生场同�?�信�? 
.V_SyncEnd          (1080+4+5), //视�?�时间参�?,场同步结束，多少行后停�??产生长同步信�?  
.V_FrameSize        (1080+4+5+19), //视�?�时间参�?,场�?��?�信号，一帧�?��?�信号总�?�占用的行数�?   

.VIDEO_VIC          ( 16       ),
.VIDEO_TPG          ( "Disable"),//设置disable，用户数�?驱动HDMI接口，否则�?�置eable产生内部测试图形
.VIDEO_FORMAT       ( "RGB444" )//设置输入数据格式为RGB格式
)u_hdmi_tx
(
.I_pixel_clk        ( pclkx1           ),//像素时钟
.I_serial_clk       ( pclkx5           ),//串�?�发送时�?
.I_rst              ( ~fifowait[20]      ),//异�?��?�位信号，高电平有效

.I_video_in_user    ( I_video_in_user    ),//视�?�输入帧起�?�信�?
.I_video_in_valid   ( I_video_in_valid   ),//视�?�输入有效信�?
.I_video_in_last    ( I_video_in_last    ),//视�?�输入�?�结束信�?
.I_video_in_data    ( I_video_in_data    ),//视�?�输入数�?

.O_hdmi_clk_p       ( O_hdmi_clk_p     ),//HDMI时钟通道
.O_hdmi_tx_p        ( O_hdmi_tx_p      )//HDMI数据通道
);


    
endmodule
