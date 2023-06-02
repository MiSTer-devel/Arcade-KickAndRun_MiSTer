`include "clocks.svh"

module core(
  input reset,
  input clk_sys,

  input [7:0] dsw1,
  input [7:0] dsw2,

  input [7:0] in0,
  input [7:0] in1,
  input [7:0] in2,
  input [7:0] in3,
  input [7:0] in4,
  input [7:0] in5,
  input [7:0] in6,
  input [7:0] in7,

  output [3:0] red,
  output [3:0] green,
  output [3:0] blue,
  output       hb,
  output       vb,
  output       hs,
  output       vs,
  output       ce_pix,

  input        ioctl_download,
  input [26:0] ioctl_addr,
  input [15:0] ioctl_dout,
  input        ioctl_wr,

  output [15:0] sound_mix

);

wire [15:0] mcpu_ab;
wire  [7:0] mcpu_din;
wire  [7:0] mcpu_dout;

wire mcpu_rd;
wire mcpu_wr;
wire mcpu_io;
wire mcpu_m1;
reg mcpu_wait;

wire mcpu_rom1_en;
wire mcpu_rom2_en;
wire mcpu_scrn_en;
wire mcpu_ps4r_en;
wire mcpu_reg1_wr;
wire mcpu_reg2_wr;
wire mcpu_in3_rd;
wire mcpu_tmcl_en;
wire mcpu_exit_en;
wire scpu_rom_en;
wire scpu_wrk_en;
wire scpu_ram_en;
wire scpu_snd_en;
wire ecpu_rom_en;
wire ecpu_ram_en;
wire ecpu_ext_en;
wire ecpu_pt0_en;
wire ecpu_pt1_en;
wire ecpu_pt2_en;
wire ecpu_pt3_en;
wire ecpu_pt4_wr;
wire ecpu_tmc_en;

wire  [7:0] scpu_din;
wire  [7:0] scpu_dout;
wire [15:0] scpu_ab;
wire        scpu_rd;
wire        scpu_wr;
wire        scpu_mreq;
wire        scpu_io;
reg         scpu_wait;

wire [7:0] mcpu_rom_data;

wire [7:0] exit_dout_a;
wire [7:0] exit_dout_b;
wire [7:0] ps4_dout_a;
wire [7:0] ps4_dout_b;
wire [7:0] scr_dout_a;
wire [7:0] scr_dout_b;
wire [7:0] scpu_ram_dout;

wire [16:0] char_rom_addr;
wire  [7:0] char_data1;
wire  [7:0] char_data2;

wire [7:0] pal_rom_addr;
wire [3:0] pal_rom_data1;
wire [3:0] pal_rom_data2;
wire [3:0] pal_rom_data3;

wire [12:0] sco_addr;

wire exit_wren_a = mcpu_exit_en & mcpu_wr;
wire exit_wren_b = ecpu_ext_en  & ecpu_wr;
wire ps4_wren_a  = mcpu_ps4r_en & mcpu_wr;

wire [7:0] mcu_p1 = in0;
wire [4:0] mcu_p2;
wire [7:0] mcu_p3_i;
wire [7:0] mcu_p3_o;
wire [7:0] mcu_p4;
wire       mcu_ps4_en;
wire       mcu_jh_en;
wire       mcu_jl_en;

wire [11:0] mcu_ab = { mcu_p2[0], 3'b0, mcu_p4 };

wire [7:0] scpu_rom_data;

wire  [7:0] ecpu_din;
wire  [7:0] ecpu_dout;
wire [15:0] ecpu_ab;
wire        ecpu_rd;
wire        ecpu_wr;
wire        ecpu_mreq;
wire        ecpu_io;

wire [7:0] ecpu_rom_data;
wire [7:0] ecpu_ram_dout;

wire [2:0] bank_num = mcpu_reg1[2:0]; // bit 2 is ROM1/0 switch, pin14 is connected to the bank register through PAL16G

reg [7:0] mcpu_reg1;
reg [7:0] mcpu_reg2;

wire [7:0] ym_dout;

always @(posedge clk_sys) begin
  if (mcpu_wr & mcpu_reg1_wr) mcpu_reg1 <= mcpu_dout; // 15H
  if (mcpu_wr & mcpu_reg2_wr) mcpu_reg2 <= mcpu_dout; // 14H
end

assign mcpu_din =
  mcpu_in3_rd  ? in3             :
  mcpu_scrn_en ? scr_dout_b      :
  mcpu_ps4r_en ? ps4_dout_a      :
  mcpu_exit_en ? exit_dout_a     :
  mcpu_rom1_en ? mcpu_rom_data   :
  mcpu_rom2_en ? mcpu_rom_data   : 8'h0;

assign scpu_din =
  scpu_snd_en ? ym_dout         :
  scpu_wrk_en ? scr_dout_a      :
  scpu_rom_en ? scpu_rom_data   :
  scpu_ram_en ? scpu_ram_dout   : 8'h0;

assign ecpu_din =
  ecpu_pt0_en ? in4           :
  ecpu_pt1_en ? in5           :
  ecpu_pt2_en ? in6           :
  ecpu_pt3_en ? in7           :
  ecpu_ext_en ? exit_dout_b   :
  ecpu_ram_en ? ecpu_ram_dout :
  ecpu_rom_en ? ecpu_rom_data : 8'h0;

assign mcu_p3_i =
  mcu_ps4_en ? ps4_dout_b             :
  ps4_rd_prt ? (~mcu_ab[0] ? in2 : in1) :
  8'd0;

mcpu mcpu(
  .reset     ( reset     ),
  .clk_sys   ( clk_sys   ),
  .mcpu_din  ( mcpu_din  ),
  .mcpu_dout ( mcpu_dout ),
  .mcpu_ab   ( mcpu_ab   ),
  .mcpu_rd   ( mcpu_rd   ),
  .mcpu_wr   ( mcpu_wr   ),
  .mcpu_io   ( mcpu_io   ),
  .mcpu_m1   ( mcpu_m1   ),
  .mcpu_wait ( mcpu_wait ),
  .sirq_n    ( ~vb       )
);

mcpu_rom u_mcpu_rom(
  .clk_sys        ( clk_sys        ),
  .mcpu_ab        ( mcpu_ab        ),
  .bank_num       ( bank_num       ),
  .mcpu_rom_data  ( mcpu_rom_data  ),
  .mcpu_rom1_en   ( mcpu_rom1_en   ),
  .mcpu_rom2_en   ( mcpu_rom2_en   ),
  .ioctl_download ( ioctl_download ),
  .ioctl_addr     ( ioctl_addr     ),
  .ioctl_dout     ( ioctl_dout     ),
  .ioctl_wr       ( ioctl_wr       )
);

scpu scpu(
  .reset     ( reset | ~mcpu_reg2[2] ),
  .clk_sys   ( clk_sys               ),
  .scpu_din  ( scpu_din              ),
  .scpu_dout ( scpu_dout             ),
  .scpu_ab   ( scpu_ab               ),
  .scpu_rd   ( scpu_rd               ),
  .scpu_wr   ( scpu_wr               ),
  .scpu_mreq ( scpu_mreq             ),
  .scpu_io   ( scpu_io               ),
  .scpu_wait ( scpu_wait             ),
  .irq_n     ( ~vb                   )
);

ram #(13,8) scpu_ram(
  .clk  ( clk_sys                 ),
  .addr ( scpu_ab[12:0]           ),
  .din  ( scpu_dout               ),
  .q    ( scpu_ram_dout           ),
  .rd_n ( 1'b0                    ),
  .wr_n ( ~scpu_wr                ),
  .ce_n ( ~scpu_ram_en            )
);

scpu_rom u_scpu_rom(
  .clk_sys        ( clk_sys        ),
  .scpu_ab        ( scpu_ab        ),
  .scpu_rom_data  ( scpu_rom_data  ),
  .ioctl_download ( ioctl_download ),
  .ioctl_addr     ( ioctl_addr     ),
  .ioctl_dout     ( ioctl_dout     ),
  .ioctl_wr       ( ioctl_wr       )
);

ecpu ecpu(
  .reset       ( reset | mcpu_reg2[2] ),
  .clk_sys     ( clk_sys              ),
  .ecpu_din    ( ecpu_din             ),
  .ecpu_dout   ( ecpu_dout            ),
  .ecpu_ab     ( ecpu_ab              ),
  .ecpu_rd     ( ecpu_rd              ),
  .ecpu_wr     ( ecpu_wr              ),
  .ecpu_mreq   ( ecpu_mreq            ),
  .ecpu_io     ( ecpu_io              ),
  .vb          ( vb                   )
);

ecpu_rom u_ecpu_rom(
  .clk_sys        ( clk_sys        ),
  .ecpu_ab        ( ecpu_ab        ),
  .ecpu_rom_data  ( ecpu_rom_data  ),
  .ioctl_download ( ioctl_download ),
  .ioctl_addr     ( ioctl_addr     ),
  .ioctl_dout     ( ioctl_dout     ),
  .ioctl_wr       ( ioctl_wr       )
);

addr_decode u_addr_decode(
  .mcpu_ab      ( mcpu_ab      ),
  .scpu_ab      ( scpu_ab      ),
  .ecpu_ab      ( ecpu_ab      ),
  .mcu_ab       ( mcu_ab       ),
  .ecpu_wr      ( ecpu_wr      ),
  .ecpu_rd      ( ecpu_rd      ),
  .mcpu_rom1_en ( mcpu_rom1_en ),
  .mcpu_rom2_en ( mcpu_rom2_en ),
  .mcpu_scrn_en ( mcpu_scrn_en ),
  .mcpu_ps4r_en ( mcpu_ps4r_en ),
  .mcpu_reg1_wr ( mcpu_reg1_wr ),
  .mcpu_reg2_wr ( mcpu_reg2_wr ),
  .mcpu_in3_rd  ( mcpu_in3_rd  ),
  .mcpu_tmcl_en ( mcpu_tmcl_en ),
  .mcpu_exit_en ( mcpu_exit_en ),
  .scpu_rom_en  ( scpu_rom_en  ),
  .scpu_wrk_en  ( scpu_wrk_en  ),
  .scpu_ram_en  ( scpu_ram_en  ),
  .scpu_snd_en  ( scpu_snd_en  ),
  .ecpu_rom_en  ( ecpu_rom_en  ),
  .ecpu_ram_en  ( ecpu_ram_en  ),
  .ecpu_ext_en  ( ecpu_ext_en  ),
  .ecpu_pt0_en  ( ecpu_pt0_en  ),
  .ecpu_pt1_en  ( ecpu_pt1_en  ),
  .ecpu_pt2_en  ( ecpu_pt2_en  ),
  .ecpu_pt3_en  ( ecpu_pt3_en  ),
  .ecpu_pt4_wr  ( ecpu_pt4_wr  ),
  .ecpu_tmc_en  ( ecpu_tmc_en  ),
  .mcu_ps4_en   ( mcu_ps4_en   ),
  .mcu_jh_en    ( mcu_jh_en    ),
  .mcu_jl_en    ( mcu_jl_en    )
);

mcu u_mcu(
  .reset          ( reset | ~mcpu_reg2[1] ),
  .clk_sys        ( clk_sys               ),
  .mcu_p1         ( mcu_p1                ),
  .mcu_p2         ( mcu_p2                ),
  .mcu_p3_o       ( mcu_p3_o              ),
  .mcu_p3_i       ( mcu_p3_i              ),
  .mcu_p4         ( mcu_p4                ),
  .mcu_irq        (                       ),
  .mcu_nmi        (                       ),
  .ioctl_download ( ioctl_download        ),
  .ioctl_addr     ( ioctl_addr            ),
  .ioctl_dout     ( ioctl_dout            ),
  .ioctl_wr       ( ioctl_wr              ),
  .vb             ( vb                    )
);

ram #(11,8) ecpu_ram(
  .clk  ( clk_sys       ),
  .addr ( ecpu_ab[10:0] ),
  .din  ( ecpu_dout     ),
  .q    ( ecpu_ram_dout ),
  .rd_n ( 1'b0          ),
  .wr_n ( ~ecpu_wr      ),
  .ce_n ( ~ecpu_ram_en  )
);


dpram #(11,8) exit(
  .address_a ( mcpu_ab[10:0] ),
  .address_b ( ecpu_ab[10:0] ),
  .clock     ( clk_sys       ),
  .data_a    ( mcpu_dout     ),
  .data_b    ( ecpu_dout     ),
  .rden_a    ( 1'b1          ),
  .rden_b    ( 1'b1          ),
  .wren_a    ( exit_wren_a   ),
  .wren_b    ( exit_wren_b   ),
  .q_a       ( exit_dout_a   ),
  .q_b       ( exit_dout_b   )
);

wire ps4_wren_b = ~mcu_p2[4] & mcu_p2[0] & ~mcu_p2[2];
wire ps4_rd_prt = mcu_p2[4] & ~mcu_p2[0] & mcu_p2[2];

dpram #(11,8) ps4r(
  .address_a ( mcpu_ab[10:0] ),
  .address_b ( mcu_ab[10:0]  ),
  .clock     ( clk_sys       ),
  .data_a    ( mcpu_dout     ),
  .data_b    ( mcu_p3_o      ),
  .rden_a    ( 1'b1          ),
  .rden_b    ( 1'b1          ),
  .wren_a    ( ps4_wren_a    ),
  .wren_b    ( ps4_wren_b    ),
  .q_a       ( ps4_dout_a    ),
  .q_b       ( ps4_dout_b    )
);

reg [13:0] scr_ram_addr_bus;
reg scr_ram_wr;

always @* begin
  dma_wait = 1'b0;
  scr_ram_wr = 1'b0;
  if (scpu_wrk_en) begin
    dma_wait = dma_en ? 1'b1 : 1'b0;
    scr_ram_wr = scpu_wr;
    scr_ram_addr_bus = scpu_ab[13:0];
  end
  else if (dma_en) begin
    scr_ram_addr_bus = { 1'b0, dma_addr };
  end
end

reg dma_wait;
wire [12:0] dma_addr;
wire [7:0] dma_data = scr_dout_a;
wire dma_en;

dpram #(14,8) scr1(
  .clock     ( clk_sys                       ),
  .address_a ( scr_ram_addr_bus              ), // SCPU | DMA
  .address_b ( mcpu_ab[13:0]                 ),
  .data_a    ( scpu_dout                     ),
  .data_b    ( mcpu_dout                     ),
  .rden_a    ( 1'b1                          ),
  .rden_b    ( 1'b1                          ),
  .wren_a    ( scr_ram_wr                    ),
  .wren_b    ( mcpu_scrn_en ? mcpu_wr : 1'b0 ),
  .q_a       ( scr_dout_a                    ),
  .q_b       ( scr_dout_b                    )
);

video video(
  .reset         ( reset         ),
  .clk_sys       ( clk_sys       ),
  .dma_addr      ( dma_addr      ),
  .dma_data      ( dma_data      ),
  .dma_en        ( dma_en        ),
  .dma_wait      ( dma_wait      ),
  .bank          ( mcpu_reg1[5]  ),
  .char_rom_addr ( char_rom_addr ),
  .char_data1    ( char_data1    ),
  .char_data2    ( char_data2    ),
  .pal_rom_addr  ( pal_rom_addr  ),
  .pal_rom_data1 ( pal_rom_data1 ),
  .pal_rom_data2 ( pal_rom_data2 ),
  .pal_rom_data3 ( pal_rom_data3 ),
  .red           ( red           ),
  .green         ( green         ),
  .blue          ( blue          ),
  .hb            ( hb            ),
  .vb            ( vb            ),
  .hs            ( hs            ),
  .vs            ( vs            ),
  .ce_pix        ( ce_pix        )
);


data vdata(
  .clk_sys        ( clk_sys        ),
  .char_rom_addr  ( char_rom_addr  ),
  .char_data1     ( char_data1     ),
  .char_data2     ( char_data2     ),
  .pal_rom_addr   ( pal_rom_addr   ),
  .pal_rom_data1  ( pal_rom_data1  ),
  .pal_rom_data2  ( pal_rom_data2  ),
  .pal_rom_data3  ( pal_rom_data3  ),
  .ioctl_download ( ioctl_download ),
  .ioctl_addr     ( ioctl_addr     ),
  .ioctl_dout     ( ioctl_dout     ),
  .ioctl_wr       ( ioctl_wr       )
);


wire cen_6, clk_6;
clk_en #(CORE_CLK_6) u_ck_en(clk_sys, cen_6, clk_6);

wire jt03_wr_n = ~(scpu_snd_en & scpu_wr);
wire [7:0] jt03_din = ~jt03_wr_n ? scpu_dout : 8'd0;

reg jt03_addr;
always @(posedge clk_sys)
  if (scpu_snd_en) jt03_addr <= scpu_ab[0];


jt03 u_jt03(
  .rst        ( reset        ),
  .clk        ( clk_sys      ),
  .cen        ( cen_6        ),
  .din        ( jt03_din    ),
  .addr       ( jt03_addr    ),
  .cs_n       ( ~(scpu_snd_en & scpu_mreq) ),
  .wr_n       ( jt03_wr_n    ),
  .dout       ( ym_dout      ),
  .irq_n      (              ),
  .IOA_in     ( dsw1         ),
  .IOB_in     ( dsw2         ),
  .psg_A      (              ),
  .psg_B      (              ),
  .psg_C      (              ),
  .fm_snd     (              ),
  .psg_snd    (              ),
  .snd        ( sound_mix    ),
  .snd_sample (              )
);



endmodule
