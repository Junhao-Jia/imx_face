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



inout  wire            			IO_cam_sda	,
output wire           			O_cam_scl	,
output wire           			O_clk_24m	,

output wire           			O_phy_rst,            //以太网芯片复位信号，低电平有效 
input  wire [3:0]     			I_a_rgmii_rxd,        //RGMII输入数据
input  wire           			I_a_rgmii_rx_ctl,     //RGMII输入数据有效信号
input  wire           			I_a_rgmii_rxc,        //RGMII接收数据时钟
output wire [3:0]     			O_a_rgmii_txd,        //RGMII输出数据 
output wire           			O_a_rgmii_tx_ctl,     //RGMII输出数据有效信号
output wire           			O_a_rgmii_txc
);

wire        S_rst;
wire        clk_125;
wire 		clk_125_90;
wire        vtc_clk;
wire 		S_pll_lock;
assign S_rst = ~S_pll_lock;
wire        clk_24m;

  PH1_LOGIC_ODDR CMOS_CLK (
      .q  (O_clk_24m),  //output 125mhz（1gbps） 25mhz(100mbps)    2.5mhz(10mbps)
      .clk(clk_24m),
      .d0 (1'b1),
      .d1 (1'b0),
      .rst(1'b0)
  );

pll u_pll(
.refclk   ( I_sys_clk_25m          ),
.lock     ( S_pll_lock             ),
 
.clk0_out ( clk_125                ),
.clk1_out ( clk_125_90             ),
.clk2_out ( S_clk_70m              ),
.clk3_out ( clk_24m                ),
.clk4_out ( vtc_clk                )
);

wire [15:0]ae;//synthesis keep
wire [15:0]ag;//synthesis keep
wire cam_cfg_done,ae_cfg_done;
wire ae_req;

wire        O_phyrst_done;      
wire        phy_rst;            //synthesis keep
wire        reset;              //synthesis keep

assign      reset     = ~phy_rst;
assign      O_phy_rst = phy_rst;

uiphyrst#
(
.CLK_FREQ(32'd125_000_000)          //时钟参数
)
uiphyrst_inst                      //设置分频系数，降低流水灯的变化速度
(                                  //该参数可以由上层调用时修改
.I_CLK(clk_125),                    //系统时钟信号
.I_rstn(S_pll_lock),               //全局复位
.I_phyrst(S_pll_lock),             //复位时钟
.O_phyrst(phy_rst),                //复位输出
.O_phyrst_done(O_phyrst_done)
);

uicfg_imx415#
(
.CLK_DIV(24_000_000/100_000-1)
)
u_uicfg_imx415
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

//csi ����ΪRAW����
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

// ����ΪRAW10
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

isp_top u_isp_top (
.axi4s_video_aclk(S_hs_rx_clk),
.I_rst_n         (S_pll_lock),
.I_tlast         (axis_tlast ),
.I_tuser         (axis_tuser ),
.I_tdata         (axis_tdata ),
.I_tvalid        (axis_tvalid),
.I_tdest         (),
.O_tready        (ISP_O_tready),
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

//����DDR IP
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

wire [AXI_ADDR_WIDTH-1:  0]      fdma_waddr;    
wire                             fdma_wareq;    
wire [15: 0]                     fdma_wsize;                        
wire                             fdma_wbusy;    
wire [AXI_DATA_WIDTH-1 : 0]      fdma_wdata;    
wire                             fdma_wvalid;   
wire                             fdma_wready;   

wire [AXI_ADDR_WIDTH-1:  0]      fdma_raddr;    
wire                             fdma_rareq;    
wire [15: 0]                     fdma_rsize;                          
wire                             fdma_rbusy;    	
wire [AXI_DATA_WIDTH-1 : 0]      fdma_rdata;    
wire                             fdma_rvalid;   
wire                             fdma_rready;   
wire                             test_error;    

//����������uiFDMA AXI ������ IP
uiFDMA#
(
.M_AXI_ID(0),
.M_AXI_ID_WIDTH(AXI_ID_WIDTH)           ,
.M_AXI_ADDR_WIDTH(AXI_ADDR_WIDTH)		,
.M_AXI_DATA_WIDTH(AXI_DATA_WIDTH)		,
.M_AXI_MAX_BURST_LEN (16)                
)
uiFDMA_inst
(
.I_fdma_waddr(fdma_waddr)          ,
.I_fdma_wareq(fdma_wareq)          ,
.I_fdma_wsize(fdma_wsize)          ,                            
.O_fdma_wbusy(fdma_wbusy)          ,
				
.I_fdma_wdata(fdma_wdata)		   ,
.O_fdma_wvalid(fdma_wvalid)        ,
.I_fdma_wready(1'b1)		       ,

.I_fdma_raddr(fdma_raddr)          ,
.I_fdma_rareq(fdma_rareq)          ,
.I_fdma_rsize(fdma_rsize)          ,                        
.O_fdma_rbusy(fdma_rbusy)          ,
				
.O_fdma_rdata(fdma_rdata)		   ,
.O_fdma_rvalid(fdma_rvalid)        ,
.I_fdma_rready(1'b1)		       ,

//����ΪAXI�����ź�		
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

//����3֡���棬���ӳ�д1֡
uisetvbuf#(
.BUF_DELAY(0),
.BUF_LENTH(2)
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

wire vtc_vs;
wire vtc_de_valid;  //synthesis keep
wire vtc_user;  //synthesis keep  
wire vtc_last;  //synthesis keep  

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
.W_BUFSIZE(2),

.R_BUFDEPTH(2048),
.R_DATAWIDTH(32),
.R_BASEADDR(0),
.R_DSIZEBITS(23),
.R_XSIZE(1920),
.R_XSTRIDE(1920),
.R_YSIZE(1080),
.R_XDIV(6),
.R_BUFSIZE(2)
)
uidbuf_u0
(
.I_ui_clk(dfi_clk),
.I_ui_rstn(ddr_init_cal_done),

.I_W_en      (1),
.I_W_wclk    (S_hs_rx_clk),
.I_W_tuser   (o_face_user ),
.I_W_tvalid  (o_face_valid),
.I_W_tdata   (o_face_data ),
.I_W_tlast   (o_face_last ),
.O_W_tready  (ISP_O_tready),
.O_W_sync_cnt(wbuf_sync),
.I_W_buf     (wbuf_sync),

.I_R_en      (1),
.I_R_rclk    (vtc_clk),
.I_R_tready  (fdma_I_R_tready),
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


wire [23:0] fdma_O_R_tdata_24;

uirgb32to24 u_uirgb32to24 (
      .rgb24(fdma_O_R_tdata_24),
      .rgb32(fdma_O_R_tdata)
  );
wire init_done;
assign  init_done   = ddr_init_cal_done && phy_rst;

reg [20:0] fifowait;  //synthesis keep  
  always @(posedge vtc_clk or negedge init_done) begin
    if (init_done == 'b0) fifowait <= 'b0;
    else if (fifowait[20] == 0) fifowait <= fifowait + 1;
    else fifowait <= fifowait;
  end

uivtc #(
 //1080P @ 137.5M
.H_ActiveSize       (1920), 
.H_SyncStart        (1920+88), 
.H_SyncEnd          (1920+88+44),
.H_FrameSize        (1920+88+44+16), 
.V_ActiveSize       (1080),
.V_SyncStart        (1080+4),
.V_SyncEnd          (1080+4+5), 
.V_FrameSize        (1080+4+5+19) 
)
uivtc_inst (
.I_vtc_clk(vtc_clk),  
.I_vtc_rstn(fifowait[20]),
//.I_vtc_rstn(S_pll_lock),
.O_vtc_vs  (vtc_vs),
.O_vtc_hs  (),
.O_vtc_de_valid(vtc_de_valid),
.O_vtc_user(vtc_user),    
.O_vtc_last(vtc_last)    
);
  
wire I_video_in_user;  //synthesis keep  
wire I_video_in_valid;  //synthesis keep  
wire I_video_in_last;  //synthesis keep  
wire [23:0] I_video_in_data;  //synthesis keep  
  
assign I_video_in_user  = fdma_O_R_tuser;  
assign I_video_in_valid = fdma_O_R_tvalid  ;  
assign I_video_in_last  = fdma_O_R_tlast;  
assign I_video_in_data  = fdma_O_R_tdata_24;  

localparam      S_SYNC_1        = 3'd0;
localparam      S_SYNC_2        = 3'd1;
localparam      S_SYNC_3        = 3'd2;
localparam      S_UDP_WAIT      = 3'd3;
localparam      S_UDP_ACK       = 3'd4;
localparam      S_UDP_HEADER    = 3'd5;
localparam      S_UDP_DATA      = 3'd6;
localparam      S_UDP_END       = 3'd7;

localparam      IMG_HEADER      = 32'hAA0055FF;
localparam      IMG_WIDTH       = 16'd1920; 
localparam      IMG_HEIGHT      = 16'd1080; 
//localparam      IMG_TOTAL       = IMG_WIDTH*IMG_HEIGHT*3;
localparam      IMG_FRAMSIZE    = 32'd1440;
localparam      IMG_FRAMTOTAL   = IMG_WIDTH*IMG_HEIGHT*3/IMG_FRAMSIZE;
localparam      IMG_HEADERSIZE  = 6'd16;
reg  [15 :0]    IMG_FRAMSEQ;
reg  [15 :0]    IMG_PICSEQ; 
wire [127:0]    STHEADER_X86    = {IMG_FRAMSIZE,IMG_FRAMSEQ,IMG_PICSEQ,IMG_HEIGHT,IMG_WIDTH,IMG_HEADER};


wire [7:0]  gmii_tdata;
wire        gmii_tvalid;
wire [7:0]  gmii_rdata;
wire        gmii_rvalid;

wire        R_udp_valid;
wire [7:0]  R_udp_data;
wire [15:0] R_udp_len;
wire [15:0] R_udp_src_port;


wire        W_udp_busy; //synthesis keep
reg         W_udp_req; //synthesis keep
reg         W_udp_valid;//synthesis keep 
reg [7 :0]  W_udp_data;
reg [15:0]  W_udp_len;
reg         W_udp_data_read;

reg [2 :0] UDP_MS;          //synthesis keep
reg [11:0] W_pkg_cnt;       //synthesis keep//每次发送UDP的计数器
reg [1 :0] rd_index;        //synthesis keep
wire[23:0] udp_rdata;       //synthesis keep
wire       udp_ren;         //synthesis keep

wire        [12:0] wr_cnt; //synthesis keep
udp_pkg_buf #(
.DATA_WIDTH_W   (24), 
.DATA_WIDTH_R   (24), 
.ADDR_WIDTH_W   (12), 
.ADDR_WIDTH_R   (12), 
.AL_FULL_NUM    (2045), 
.AL_EMPTY_NUM   (2), 
.SHOW_AHEAD_EN  (1'b1), 
.OUTREG_EN      ("NOREG")
) 
udp_tfifo_inst(
.rst    (vtc_vs |  reset    ),      //asynchronous port,active hight
.clkw   (vtc_clk    ),      //write clock
.clkr   (clk_125    ),      //read ()clock
.we     (I_video_in_valid  ),      //write enable,active hight
.di     (I_video_in_data),      //write data
.re     (udp_ren    ),      //read enable,active hight
.dout   (udp_rdata  ),      //read data
.valid  (           ),      //read data valid flag
.wrusedw(wr_cnt     )       //stored data number in fifo 
); 


// 当vtc_de_valid = 1 ud_rdata_cnt =1 读1个数据，但是ud_rfifo_en延迟1个周期输出1，fifo再延迟1个周期更新数据
assign udp_ren = (rd_index == 2'd2 )&& (UDP_MS == S_UDP_DATA );

always @(posedge clk_125 or posedge reset) begin
    if(reset)
        W_udp_data <= 0;
    else begin
        if(UDP_MS == S_UDP_ACK || UDP_MS == S_UDP_HEADER)begin
            W_udp_data <= STHEADER_X86[W_pkg_cnt*8 +: 8];
        end
        else if(UDP_MS == S_UDP_DATA)begin
            case(rd_index)
            'd0: W_udp_data <=  udp_rdata[23:16]; 
            'd1: W_udp_data <=  udp_rdata[15: 8];
            'd2: W_udp_data <=  udp_rdata[7 : 0];          
            default:
                 W_udp_data <= W_udp_data;
            endcase
        end
    end
end


reg[22:0] T_interval;

reg R0_FS_i;

always@(posedge clk_125 or posedge reset)begin
    if(reset) begin
        W_udp_req           <= 1'b0;
        W_udp_valid         <= 1'b0;
        W_pkg_cnt           <= 12'd0;
        R0_FS_i             <= 1'b0; 
        IMG_PICSEQ          <= 32'd0;
        IMG_FRAMSEQ         <= 32'd0;
        rd_index            <= 2'd0;
        T_interval          <=0;
        UDP_MS              <= S_SYNC_1;
    end
    else begin
       case(UDP_MS)
       S_SYNC_1:begin //产生VS同步，通过FDMA从DDR读取数据
         if(vtc_vs)begin
         rd_index    <= 2'd0;
         R0_FS_i     <= 1'b0;
         IMG_FRAMSEQ <= 32'd0; //一帧图片会分为IMG_FRAMSEQ次发送，并且上位机缓存依据此此序号对一帧图片内的数据包重组为一帧图片
         IMG_PICSEQ  <= IMG_PICSEQ + 1'b1;//图片计数器，该计数器提供给上位机缓存，用于根据图片的计数器号，一次显示图片
         UDP_MS      <= S_SYNC_2;
         end
       end
       S_SYNC_2:begin
            if(~vtc_vs)
            UDP_MS      <= S_SYNC_3;
       end
       S_SYNC_3:begin
         R0_FS_i     <= 1'b0;
         UDP_MS      <= S_UDP_WAIT;
       end
       S_UDP_WAIT:begin      //等待UDP准备好发送
          W_pkg_cnt <= 12'd0; //每次UDP发送的数据计数器
          //if(~W_udp_busy&(~R0_empty)) begin//UDP控制器发送非忙，以及读缓存有数据
           if(~W_udp_busy & (wr_cnt >= 480)) begin//UDP控制器发送非忙，以及读缓存有数据
              W_udp_req <= 1'b1;UDP_MS <= S_UDP_ACK;//发送UDP发数据请求
           end
           else begin
               W_udp_req <= 1'b0;UDP_MS <= S_UDP_WAIT;
           end
       end
       
       S_UDP_ACK:begin
          if(W_udp_busy) begin //当UDP总线忙，代表正在发送数据
               W_udp_req         <= 1'b0;
               W_udp_valid       <= 1'b1;   //发送有效数据
               W_pkg_cnt         <= W_pkg_cnt + 1;
               IMG_FRAMSEQ       <= IMG_FRAMSEQ + 1'b1;
               UDP_MS            <= S_UDP_HEADER;
           end
         end
        S_UDP_HEADER:begin
            W_udp_valid <= 1'b1;    //发送有效数据
            W_pkg_cnt   <= W_pkg_cnt + 1;
            if(W_pkg_cnt == IMG_HEADERSIZE -1'b1 )
                UDP_MS           <= S_UDP_DATA;
                    
        end 
        S_UDP_DATA:begin
            W_udp_valid <= 1'b1;
            if(rd_index[1:0] == 2'd2) 
                rd_index[1:0] <= 2'd0;
             else
                rd_index[1:0] <= rd_index[1:0]  + 1'b1;
                
            W_pkg_cnt   <= W_pkg_cnt + 1'b1;
            if(W_pkg_cnt == IMG_FRAMSIZE + IMG_HEADERSIZE - 1'b1   )         
                UDP_MS <= S_UDP_END;
            else 
                UDP_MS <= S_UDP_DATA;            
         end
         
         S_UDP_END:begin
            W_udp_valid <= 1'b0; 
			if(~W_udp_busy)begin
				if(IMG_FRAMSEQ == IMG_FRAMTOTAL) 
					UDP_MS <= S_SYNC_1;
				else 
					UDP_MS  <= S_UDP_WAIT; 
			end
			else
				UDP_MS	<=	S_UDP_END;
          end
          default: UDP_MS <= S_SYNC_1;
        endcase
    end
end      

//UDP协议栈     
uiudp_stack #
(   
.CRC_GEN_EN             (1'b1),             //使能MAC层CRC校验
.INTER_FRAME_GAP        (4'd12)             //插入帧间隔，2帧之间最少需要IFGmini=96bit/speed,比如1000M 96ns 100M 960ns 10M 9600ns，对于1000M 125M发送时钟，为12
)
udp_stack_inst
(
.I_uclk                 (clk_125        ), 
.I_reset                (reset          ), 

.I_mac_local_addr       (48'h0123456789ab),//本地MAC地址    
.I_udp_local_port       (16'd6002       ), //本地端口号
.I_ip_local_addr        ({8'd192, 8'd168,8'd137, 8'd2}      ), //本地ip地址

.I_udp_dest_port        (16'd6001       ), //目的端口
.I_ip_dest_addr         ({8'd192, 8'd168,8'd137, 8'd1}      ), //目的IP地址

.O_W_udp_busy           (W_udp_busy     ), //udp写忙
.I_W_udp_req            (W_udp_req      ), //udp写数据请求
.I_W_udp_valid          (W_udp_valid    ), //udp写数据有效
.I_W_udp_data           (W_udp_data     ), //udp写数据
.I_W_udp_len            (16'd1456       ), //udp写数据长度

.O_R_udp_valid          (R_udp_valid    ), //udp读数据有效
.O_R_udp_data           (R_udp_data     ), //udp读数据
.O_R_udp_len            (R_udp_len      ), //udp读数据长度
.O_R_udp_src_port       (R_udp_src_port ), //udp读数据的远端主机端口号

.I_gmii_rclk            (gmii_rclk      ), //mac层接收GMII时钟
.I_gmii_rvalid          (gmii_rvalid    ), //mac层接收GMII数据有效
.I_gmii_rdata           (gmii_rdata     ), //mac层接收GMII数据

.I_gmii_tclk            (clk_125        ), //mac层发送GMII时钟
.O_gmii_tvalid          (gmii_tvalid    ), //mac层发送GMII数据有效
.O_gmii_tdata           (gmii_tdata     ), //mac层发送GMII数据有
.O_ip_rerror            (ip_rx_error    ), //接收数据IP层数据校验错误
.O_mac_rerror           (mac_rx_error   )  //接收数据MAC层数据校验错误
);


rgmii_interface rgmii_interface_inst(

.speed_10_100   (1'b0               ),   // 指示当前运行速度为10/100 或者1000
.gmii_tx_clk_d  (clk_125            ),   //RGMII发送时序调整，当PHY 接收来自FPGA的TX信号，没有使用内部2ns延迟情况需要在fpga端设置2ns延迟 
.gmii_tx_reset_d(reset              ),  
.gmii_tx_reset  (reset              ),
.gmii_tx_clk    (clk_125            ),     
.gmii_txd       (gmii_tdata         ),
.gmii_tx_en     (gmii_tvalid        ),
.gmii_tx_er     (                   ),

.gmii_rx_reset  (reset              ),
.gmii_rx_clk    (gmii_rclk          ),    //output： 125mhz（1gbps） 25mhz(100mbps)    2.5mhz(10mbps)
.gmii_rxd       (gmii_rdata         ),
.gmii_rx_dv     (gmii_rvalid        ),
.gmii_rx_er     (                   ),

// 以下端口是RGMII物理接口：这些端口将位于FPGA的引脚上
.rgmii_txd      (O_a_rgmii_txd      ),
.rgmii_tx_ctl   (O_a_rgmii_tx_ctl   ),
.rgmii_txc      (O_a_rgmii_txc      ),

.rgmii_rxd      (I_a_rgmii_rxd      ),
.rgmii_rx_ctl   (I_a_rgmii_rx_ctl   ),
.rgmii_rxc      (I_a_rgmii_rxc      ),
.gmii_crs       (                   ),
.gmii_col       (                   ),
// 以下信号为RGMII状态信号
.link_status    (                   ),
.clock_speed    (                   ),
.duplex_status  (                   )
);


    
endmodule
