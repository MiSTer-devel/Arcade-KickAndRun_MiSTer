
module mcpu(
  input         clk_sys,
  input         reset,
  input  [7:0]  mcpu_din,
  output [7:0]  mcpu_dout,
  output [15:0] mcpu_ab,
  output        mcpu_wr,
  output        mcpu_rd,
  output        mcpu_io,
  output        mcpu_m1,
  input         mcpu_wait,
  input         sirq_n
);

wire cen_6;
wire mcpu_m1_n;
wire mcpu_nmi_n = 1;
wire mcpu_rd_re;
wire mcpu_iorq_n;
wire mcpu_mreq_n;
reg  mcpu_int_n = 1;
wire mcpu_wr_n;
wire mcpu_rd_n;

assign mcpu_io = ~mcpu_iorq_n;
assign mcpu_m1 = ~mcpu_m1_n;
assign mcpu_wr = ~mcpu_wr_n;
assign mcpu_rd = ~mcpu_rd_n;

clk_en #(CORE_CLK_6) cpu_clk_en(.ref_clk(~clk_sys), .cen(cen_6), .clk());

reg sirq_n1;
reg [7:0] data_latch;
always @(posedge clk_sys) begin
  sirq_n1 <= sirq_n;
  if (mcpu_rd) data_latch <= mcpu_din;

  // ugly fix for mode2, $92 must be coming from $e800
  // but I can't see how the MCU shared RAM is enabled on schematic
  if (~sirq_n & ~mcpu_iorq_n & ~mcpu_m1_n) data_latch <= 8'h92;
  if (sirq_n1 & ~sirq_n) mcpu_int_n <= 1'b0;
  if (~mcpu_iorq_n & ~mcpu_m1_n) mcpu_int_n <= 1'b1;

end


//`define TV80_REFRESH 1
tv80s mcpu_18F(
  .reset_n ( ~reset       ),
  .clk     ( ~clk_sys      ),
  .cen     ( cen_6        ),
  .wait_n  ( ~mcpu_wait   ),
  .int_n   ( mcpu_int_n   ),
  .nmi_n   ( mcpu_nmi_n   ),
  .busrq_n ( 1'b1         ),
  .m1_n    ( mcpu_m1_n    ),
  .mreq_n  ( mcpu_mreq_n  ),
  .iorq_n  ( mcpu_iorq_n  ),
  .rd_n    ( mcpu_rd_n    ),
  .wr_n    ( mcpu_wr_n    ),
  .rfsh_n  (              ),
  .halt_n  (              ),
  .busak_n (              ),
  .A       ( mcpu_ab      ),
  .di      ( data_latch   ),
  .dout    ( mcpu_dout    )
);


endmodule
