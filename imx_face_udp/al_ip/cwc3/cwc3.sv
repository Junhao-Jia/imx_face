module cwc3
(
  input   [0:0]                 probe0,
  input   [127:0]               probe1,
  input   [0:0]                 probe2,
  input   [0:0]                 probe3,
  input   [0:0]                 probe4,
  input                         clk
);

  ChipWatcher_b2f4824a9b6e  ChipWatcher_b2f4824a9b6e_Inst
  (
      .probe0(probe0),
      .probe1(probe1),
      .probe2(probe2),
      .probe3(probe3),
      .probe4(probe4),
      .clk(clk)
  );
endmodule
