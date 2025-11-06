`timescale 1ns / 1ps
/*****************************************************************
Company : MiLianKe Electronic Technology Co., Ltd.
WebSite:https://www.milianke.com
TechWeb:https://www.uisrc.com
tmall-shop:https://milianke.tmall.com
jd-shop:https://milianke.jd.com
taobao-shop: https://milianke.taobao.com
Description: 
The reference demo provided by Milianke is only used for learning. 
We cannot ensure that the demo itself is free of bugs, so users 
should be responsible for the technical problems and consequences
caused by the use of their own products.
@Author      :   XiaoQingquan 
@Time        :   2024/10 
version:     :   
@Description :   
*****************************************************************/


module line_buffer_demosaic #(
    parameter IMG_HEIGHT = 1080,
    parameter IMG_WIDTH  = 1920
) (
    input              I_clk,
    input              I_rst_n,
    input              I_tuser,  //synthesis keep 
    input  wire        I_valid,  //synthesis keep 
    input  wire [32:0] I_data,   //synthesis keep 
    output wire        O_valid,  //synthesis keep 
    output wire [32:0] O_data    //synthesis keep 
);

  wire        rd_en;  //synthesis keep 

  reg  [10:0] addra;  //synthesis keep 
  reg  [10:0] addrb;  //synthesis keep 
  reg  [32:0] data_d0;  //synthesis keep 
  reg         valid_d0;  //synthesis keep 

  localparam IMG_WIDTH_4x = (IMG_WIDTH >> 2);
  always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
      data_d0  <= 0;
      valid_d0 <= 0;
    end else begin
      data_d0  <= I_data;
      valid_d0 <= I_valid;
    end
  end


  always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n || I_tuser) begin
      addra <= 0;
    end else if (valid_d0) begin
      addra <= (addra == IMG_WIDTH_4x - 1) ? 'b0 : addra + 1'b1;
    end
  end

  reg tlast_lock_d0;
  always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n || I_tuser) begin
      tlast_lock_d0 <= 'b0;
    end else if ((tlast_lock_d0 == 'b0) & (addra == IMG_WIDTH_4x - 1)) tlast_lock_d0 <= 'b1;
  end


  assign rd_en = I_valid && tlast_lock_d0 ? 1'b1 : 1'b0;

  always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n || I_tuser) begin
      addrb <= 0;
    end else begin
      addrb <= rd_en ? (addrb == IMG_WIDTH_4x - 1) ? 'b0 : addrb + 1'b1 : addrb;
    end
  end

  assign O_valid = valid_d0 && tlast_lock_d0 ? 1:0;
  blk_mem_gen_demosaic blk_mem_gen_demosaic_r0 (
      .clka(I_clk),  // input wire clka
      .wea(valid_d0),  // input wire [0 : 0] wea
      .addra(addra),  // input wire [10 : 0] addra
      .dia(data_d0),  // input wire [33 : 0] dina
      .clkb(I_clk),  // input wire clkb
      .addrb(addrb),  // input wire [10 : 0] addrb
      .dob(O_data)  // output wire [33 : 0] doutb
  );

endmodule
