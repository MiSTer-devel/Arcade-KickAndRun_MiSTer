
module ecpu(
  input         reset,
  input         clk_sys,
  input   [7:0] ecpu_din,
  output  [7:0] ecpu_dout,
  output [15:0] ecpu_ab,
  output        ecpu_rd,
  output        ecpu_wr,
  output        ecpu_mreq,
  output        ecpu_io,
  input         vb
);

wire cen_4;
wire ecpu_m1_n;
wire ecpu_nmi_n = 1;
wire ecpu_wait_n = 1;
wire ecpu_iorq_n;
wire ecpu_wr_n;
wire ecpu_rd_n;
wire ecpu_mreq_n;
reg  ecpu_int_n;

assign ecpu_io   = ~ecpu_iorq_n;
assign ecpu_wr   = ~ecpu_wr_n;
assign ecpu_rd   = ~ecpu_rd_n;
assign ecpu_mreq = ~ecpu_mreq_n;

clk_en #(CORE_CLK_4) cpu_clk_en(.ref_clk(clk_sys), .cen(cen_4), .clk());

reg old_vb;
reg [7:0] data_latch;
always @(posedge clk_sys) begin
  old_vb <= vb;
  if (~old_vb & vb) ecpu_int_n <= 1'b0;
  if (~(ecpu_iorq_n|ecpu_m1_n)) ecpu_int_n <= 1'b1;
  if (ecpu_rd) data_latch <= ecpu_din;
end

tv80s ecpu(
  .reset_n ( ~reset       ),
  .clk     ( clk_sys      ),
  .cen     ( cen_4        ),
  .wait_n  ( ecpu_wait_n  ),
  .int_n   ( ecpu_int_n   ),
  .nmi_n   ( ecpu_nmi_n   ),
  .busrq_n ( 1'b1         ),
  .m1_n    ( ecpu_m1_n    ),
  .mreq_n  ( ecpu_mreq_n  ),
  .iorq_n  ( ecpu_iorq_n  ),
  .rd_n    ( ecpu_rd_n    ),
  .wr_n    ( ecpu_wr_n    ),
  .rfsh_n  (              ),
  .halt_n  (              ),
  .busak_n (              ),
  .A       ( ecpu_ab      ),
  .di      ( data_latch   ),
  .dout    ( ecpu_dout    )
);


endmodule
