
module scpu(
  input         reset,
  input         clk_sys,
  input   [7:0] scpu_din,
  output  [7:0] scpu_dout,
  output [15:0] scpu_ab,
  output        scpu_rd,
  output        scpu_wr,
  output        scpu_mreq,
  output        scpu_io,
  input         scpu_wait,
  input         irq_n
);

wire cen_6;
wire scpu_m1_n;
wire scpu_nmi_n = 1;
wire scpu_iorq_n;
reg scpu_int_n;
wire scpu_wr_n;
wire scpu_rd_n;
wire scpu_mreq_n;

assign scpu_io = ~scpu_iorq_n;
assign scpu_wr = ~scpu_wr_n;
assign scpu_rd = ~scpu_rd_n;
assign scpu_mreq = ~scpu_mreq_n;

clk_en #(CORE_CLK_6) cpu_clk_en(.ref_clk(clk_sys), .cen(cen_6), .clk());

reg old_vb;
reg [7:0] data_latch;
always @(posedge clk_sys) begin
  old_vb <= irq_n;
  if (old_vb & ~irq_n) scpu_int_n <= 1'b0;
  if (~(scpu_iorq_n|scpu_m1_n)) scpu_int_n <= 1'b1;
  if (scpu_rd) data_latch <= scpu_din;
end

tv80s scpu_4F(
  .reset_n ( ~reset       ),
  .clk     ( clk_sys      ),
  .cen     ( cen_6        ),
  .wait_n  ( ~scpu_wait   ),
  .int_n   ( scpu_int_n   ),
  .nmi_n   ( scpu_nmi_n   ),
  .busrq_n ( 1'b1         ),
  .m1_n    ( scpu_m1_n    ),
  .mreq_n  ( scpu_mreq_n  ),
  .iorq_n  ( scpu_iorq_n  ),
  .rd_n    ( scpu_rd_n    ),
  .wr_n    ( scpu_wr_n    ),
  .rfsh_n  (              ),
  .halt_n  (              ),
  .busak_n (              ),
  .A       ( scpu_ab      ),
  .di      ( data_latch   ),
  .dout    ( scpu_dout    )
);


endmodule
