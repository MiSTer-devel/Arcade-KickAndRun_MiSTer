
module scpu_rom(
  input        clk_sys,
  input [15:0] scpu_ab,
  output [7:0] scpu_rom_data,

  input        ioctl_download,
  input [26:0] ioctl_addr,
  input [15:0] ioctl_dout,
  input        ioctl_wr
);

wire [14:0] addr = ioctl_download ? ioctl_addr[14:0] - 27'h21000 : scpu_ab[14:0];
wire        wr   = ioctl_download && ioctl_addr >= 27'h21000 && ioctl_addr < 27'h29000 ? ioctl_wr : 1'b0;

ram #(15,8) rom(
  .clk  ( clk_sys       ),
  .addr ( addr          ),
  .din  ( ioctl_dout    ),
  .q    ( scpu_rom_data ),
  .rd_n ( 1'b0          ),
  .wr_n ( ~wr           ),
  .ce_n ( 1'b0          )
);


endmodule
