

module data(
  input clk_sys,

  input [16:0] char_rom_addr,
  output [7:0] char_data1,
  output [7:0] char_data2,

  input  [7:0] pal_rom_addr,
  output [3:0] pal_rom_data1,
  output [3:0] pal_rom_data2,
  output [3:0] pal_rom_data3,

  input        ioctl_download,
  input [26:0] ioctl_addr,
  input [15:0] ioctl_dout,
  input        ioctl_wr

);

wire [16:0] char_addr = ioctl_download ? ioctl_addr - 27'h2d000 : char_rom_addr;
wire        char1_wr  = ioctl_download && ioctl_addr >= 27'h2d000 && ioctl_addr < 27'h4d000 ? ioctl_wr : 1'b0;
wire        char2_wr  = ioctl_download && ioctl_addr >= 27'h4d000 && ioctl_addr < 27'h6d000 ? ioctl_wr : 1'b0;

wire [7:0] prom_addr = ioctl_download ? ioctl_addr - 27'h6d000 : pal_rom_addr;
wire        prom1_wr  = ioctl_download && ioctl_addr >= 27'h6d000 && ioctl_addr < 27'h6d100 ? ioctl_wr : 1'b0;
wire        prom2_wr  = ioctl_download && ioctl_addr >= 27'h6d100 && ioctl_addr < 27'h6d200 ? ioctl_wr : 1'b0;
wire        prom3_wr  = ioctl_download && ioctl_addr >= 27'h6d200 && ioctl_addr < 27'h6d300 ? ioctl_wr : 1'b0;

wire [7:0] prom_data1;
wire [7:0] prom_data2;
wire [7:0] prom_data3;

assign pal_rom_data1 = prom_data1[3:0];
assign pal_rom_data2 = prom_data2[3:0];
assign pal_rom_data3 = prom_data3[3:0];

ram #(8,8) prom1(
  .clk  ( clk_sys    ),
  .addr ( prom_addr  ),
  .din  ( ioctl_dout ),
  .q    ( prom_data1 ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~prom1_wr  ),
  .ce_n ( 1'b0       )
);

ram #(8,8) prom2(
  .clk  ( clk_sys    ),
  .addr ( prom_addr  ),
  .din  ( ioctl_dout ),
  .q    ( prom_data2 ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~prom2_wr  ),
  .ce_n ( 1'b0       )
);

ram #(8,8) prom3(
  .clk  ( clk_sys    ),
  .addr ( prom_addr  ),
  .din  ( ioctl_dout ),
  .q    ( prom_data3 ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~prom3_wr  ),
  .ce_n ( 1'b0       )
);

ram #(17,8) char_rom1(
  .clk  ( clk_sys    ),
  .addr ( char_addr  ),
  .din  ( ioctl_dout ^ 8'hff ),
  .q    ( char_data1 ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~char1_wr  ),
  .ce_n ( 1'b0       )
);

ram #(17,8) char_rom2(
  .clk  ( clk_sys    ),
  .addr ( char_addr  ),
  .din  ( ioctl_dout ^ 8'hff ),
  .q    ( char_data2 ),
  .rd_n ( 1'b0       ),
  .wr_n ( ~char2_wr  ),
  .ce_n ( 1'b0       )
);

endmodule
