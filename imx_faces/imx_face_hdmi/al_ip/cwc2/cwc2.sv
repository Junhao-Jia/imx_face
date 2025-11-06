module cwc2
(
  input   [14:0]                probe0,
  input   [14:0]                probe1,
  input   [0:0]                 probe2,
  input   [16:0]                probe3,
  input   [0:0]                 probe4,
  input   [0:0]                 probe5,
  input   [39:0]                probe6,
  input                         clk
);

  ChipWatcher_8361fd8ed3c5  ChipWatcher_8361fd8ed3c5_Inst
  (
      .probe0(probe0),
      .probe1(probe1),
      .probe2(probe2),
      .probe3(probe3),
      .probe4(probe4),
      .probe5(probe5),
      .probe6(probe6),
      .clk(clk)
  );
endmodule
