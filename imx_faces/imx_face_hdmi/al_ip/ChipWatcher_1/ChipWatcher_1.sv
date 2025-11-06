/************************************************************\
**	Copyright (c) 2012-2025 Anlogic Inc.
**	All Right Reserved.
\************************************************************/
/************************************************************\
**	Build time: Oct 25 2025 19:55:53
**	TD version	:	6.2.168116
************************************************************/
module ChipWatcher_1
(
  input   [0:0]                 probe0,
  input   [7:0]                 probe1,
  input   [7:0]                 probe2,
  input                         clk
);

  ChipWatcher_5e540ae434a3  ChipWatcher_5e540ae434a3_Inst
  (
      .probe0(probe0),
      .probe1(probe1),
      .probe2(probe2),
      .clk(clk)
  );
endmodule
