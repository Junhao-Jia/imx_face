module cwc1
(
  input   [0:0]                 probe0,
  input   [0:0]                 probe1,
  input   [0:0]                 probe2,
  input   [23:0]                probe3,
  input   [23:0]                probe4,
  input                         clk
);

  ChipWatcher_eab5e30cd908  ChipWatcher_eab5e30cd908_Inst
  (
      .probe0(probe0),
      .probe1(probe1),
      .probe2(probe2),
      .probe3(probe3),
      .probe4(probe4),
      .clk(clk)
  );
endmodule
