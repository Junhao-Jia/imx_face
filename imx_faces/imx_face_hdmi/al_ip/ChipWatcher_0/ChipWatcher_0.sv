/************************************************************\
**	Copyright (c) 2012-2025 Anlogic Inc.
**	All Right Reserved.
\************************************************************/
/************************************************************\
**	Build time: Oct 25 2025 21:39:57
**	TD version	:	6.2.168116
************************************************************/
module ChipWatcher_0
(
  input   [3:0]                 probe0,
  input   [9:0]                 probe1,
  input   [9:0]                 probe2,
  input   [9:0]                 probe3,
  input   [9:0]                 probe4,
  input   [9:0]                 probe5,
  input   [9:0]                 probe6,
  input                         clk
);

  ChipWatcher_8ea1df140bd0  ChipWatcher_8ea1df140bd0_Inst
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
