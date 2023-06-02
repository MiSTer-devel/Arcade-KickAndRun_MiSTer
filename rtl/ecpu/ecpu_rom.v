
module ecpu_rom(
  input        clk_sys,
  input [15:0] ecpu_ab,
  output [7:0] ecpu_rom_data,

  input        ioctl_download,
  input [26:0] ioctl_addr,
  input [15:0] ioctl_dout,
  input        ioctl_wr
);

wire [13:0] addr = ioctl_download ? ioctl_addr[13:0] - 27'h29000 : ecpu_ab[13:0];
wire        wr   = ioctl_download && ioctl_addr >= 27'h29000 && ioctl_addr < 27'h2d000 ? ioctl_wr : 1'b0;

ram #(14,8) rom(
  .clk  ( clk_sys       ),
  .addr ( addr          ),
  .din  ( ioctl_dout    ),
  .q    ( ecpu_rom_data ),
  .rd_n ( 1'b0          ),
  .wr_n ( ~wr           ),
  .ce_n ( 1'b0          )
);

endmodule
