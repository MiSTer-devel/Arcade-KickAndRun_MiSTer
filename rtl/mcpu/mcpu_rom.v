
module mcpu_rom(
  input        clk_sys,
  input [15:0] mcpu_ab,
  input  [2:0] bank_num, // bit 15/14 of of ROM2 address & bit 14 of ROM1
  output [7:0] mcpu_rom_data,
  input        mcpu_rom1_en,
  input        mcpu_rom2_en, // actually it can be ROM1

  input        ioctl_download,
  input [26:0] ioctl_addr,
  input [15:0] ioctl_dout,
  input        ioctl_wr
);

// @$8000
// 00 = H18 $0000
// 01 = H18 $4000
// 02 = H18 $8000
// 03 = H18 $C000
// 04 = H16 $8000
// 05 = H16 $C000


wire [15:0] addr1 = ioctl_download ? ioctl_addr[15:0] : { (bank_num[2] & mcpu_rom2_en ? { 1'b1, bank_num[0] } : mcpu_ab[15:14]), mcpu_ab[13:0] };
wire        wr1   = ioctl_download && ioctl_addr < 27'h10000 ? ioctl_wr : 1'b0;

wire [15:0] addr2 = ioctl_download ? ioctl_addr[15:0] - 27'h10000 : { bank_num[1:0], mcpu_ab[13:0] };
wire        wr2   = ioctl_download && ioctl_addr >= 27'h10000 && ioctl_addr < 27'h20000 ? ioctl_wr : 1'b0;

wire [7:0] rom_data1;
wire [7:0] rom_data2;

assign mcpu_rom_data =
  mcpu_rom1_en ? rom_data1 :
  mcpu_rom2_en & ~bank_num[2] ? rom_data2 :
  mcpu_rom2_en & bank_num[2] ? rom_data1 : 8'd0;

ram #(16,8) rom1(
  .clk  ( clk_sys       ),
  .addr ( addr1         ),
  .din  ( ioctl_dout    ),
  .q    ( rom_data1     ),
  .rd_n ( 1'b0          ),
  .wr_n ( ~wr1          ),
  .ce_n ( 1'b0          )
);

ram #(16,8) rom2(
  .clk  ( clk_sys       ),
  .addr ( addr2         ),
  .din  ( ioctl_dout    ),
  .q    ( rom_data2     ),
  .rd_n ( 1'b0          ),
  .wr_n ( ~wr2          ),
  .ce_n ( 1'b0          )
);

endmodule
