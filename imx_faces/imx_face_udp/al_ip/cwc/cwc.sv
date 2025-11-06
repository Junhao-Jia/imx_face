module cwc
(
  input   [15:0]                probe0,
  input   [15:0]                probe1,
  input   [0:0]                 probe2,
  input   [31:0]                probe3,
  input   [0:0]                 probe4,
  input   [0:0]                 probe5,
  input                         clk
);

  ChipWatcher_fbcb26908372  ChipWatcher_fbcb26908372_Inst
  (
      .probe0(probe0),
      .probe1(probe1),
      .probe2(probe2),
      .probe3(probe3),
      .probe4(probe4),
      .probe5(probe5),
      .clk(clk)
  );
endmodule
