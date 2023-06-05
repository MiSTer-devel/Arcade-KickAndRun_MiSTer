
module video(
  input reset,
  input clk_sys,
  output reg [12:0] dma_addr,
  output dma_en,
  input dma_wait,
  input [7:0] dma_data,

  output reg [16:0] char_rom_addr,
  input [7:0] char_data1,
  input [7:0] char_data2,

  output reg [7:0] pal_rom_addr,
  input [3:0] pal_rom_data1,
  input [3:0] pal_rom_data2,
  input [3:0] pal_rom_data3,

  input bank,

  output reg [3:0] red,
  output reg [3:0] green,
  output reg [3:0] blue,

  output hb,
  output vb,
  output hs,
  output vs,
  output ce_pix
);

wire [8:0] hcount;
wire [8:0] vcount;

reg dma_wr;
reg [2:0] dma_state;
reg vb0;

// original machine has no DMA

assign dma_en = |dma_state;

always @(posedge clk_sys) begin
  vb0 <= vb;
  if (reset) begin
    dma_state <= 0;
    dma_wr <= 0;
  end else if (!dma_wait) begin
    dma_wr <= 0;

    case (dma_state)
      0: begin
        dma_addr <= 0;
        if (vcount == 9'd235) begin
          dma_state <= 1;
        end
      end
      1: begin
        dma_wr <= 1;
        dma_state <= 2;
      end
      2: begin
        dma_addr <= dma_addr + 13'd1;
        if (dma_addr == 13'h1fff) dma_state <= 0;
        else dma_state <= 3;
      end
      3: dma_state <= 4;
      4: dma_state <= 1;
    endcase
  end
end

wire en0 = dma_addr[1:0] == 2'b00;
wire en1 = dma_addr[1:0] == 2'b01;
wire en2 = dma_addr[1:0] == 2'b10;
wire en3 = dma_addr[1:0] == 2'b11;

reg [12:0] spr_addr;
reg [12:0] obj_addr;
reg [12:0] eff_addr;
reg  [3:0] spr_state;
reg  [2:0] nxt_state;
reg  [7:0] spr_attr;
wire [7:0] spr_data1;
wire [7:0] spr_data2;
wire [7:0] spr_data3;
wire [7:0] spr_data4;

reg  [3:0] xx;                                       // x pixel position within sprite
wire [7:0] yy = vcount - yp + 15;                    // y pixel position within sprite
wire       vf = yy[3] ? spr_data4[6] : spr_data2[6]; // flip
wire [3:0] xv = xx ^ {4{vf}};                        // x pixel position within sprite with flip applied
reg  [7:0] id;                                       // id = sprite code
wire [7:0] sy = id[7] ? 9'd255 : 9'd15;              // sprite height-1 in pixel
reg  [8:0] xp, yp;                                   // xp, yp = sprite position
wire [7:0] px = xp + { xx[3], xv[2:0] };
wire [8:0] spr_btm = (spr_data2[7] ? 256 : (spr_data1^8'hff) + 16);
wire [8:0] spr_vpos = (spr_data1^8'hff) + (spr_data2[7] ? 16 : 0);


wire b4 = char_data1[xx[1:0]];
wire b3 = char_data1[xx[1:0]+4];
wire b2 = char_data2[xx[1:0]];
wire b1 = char_data2[xx[1:0]+4];


dpram #(11,8) spr0(
  .clock     ( clk_sys        ),
  .address_a ( dma_addr[12:2] ),
  .address_b ( spr_addr[12:2] ),
  .data_a    ( dma_data       ),
  .data_b    ( 8'd0           ),
  .rden_a    ( 1'b0           ),
  .rden_b    ( 1'b1           ),
  .wren_a    ( dma_wr & en0   ),
  .wren_b    ( 1'b0           ),
  .q_a       (                ),
  .q_b       ( spr_data1      )
);

dpram #(11,8) spr1(
  .clock     ( clk_sys        ),
  .address_a ( dma_addr[12:2] ),
  .address_b ( spr_addr[12:2] ),
  .data_a    ( dma_data       ),
  .data_b    ( 8'd0           ),
  .rden_a    ( 1'b0           ),
  .rden_b    ( 1'b1           ),
  .wren_a    ( dma_wr & en1   ),
  .wren_b    ( 1'b0           ),
  .q_a       (                ),
  .q_b       ( spr_data2      )
);

dpram #(11,8) spr2(
  .clock     ( clk_sys        ),
  .address_a ( dma_addr[12:2] ),
  .address_b ( spr_addr[12:2] ),
  .data_a    ( dma_data       ),
  .data_b    ( 8'd0           ),
  .rden_a    ( 1'b0           ),
  .rden_b    ( 1'b1           ),
  .wren_a    ( dma_wr & en2   ),
  .wren_b    ( 1'b0           ),
  .q_a       (                ),
  .q_b       ( spr_data3      )
);

dpram #(11,8) spr3(
  .clock     ( clk_sys        ),
  .address_a ( dma_addr[12:2] ),
  .address_b ( spr_addr[12:2] ),
  .data_a    ( dma_data       ),
  .data_b    ( 8'd0           ),
  .rden_a    ( 1'b0           ),
  .rden_b    ( 1'b1           ),
  .wren_a    ( dma_wr & en3   ),
  .wren_b    ( 1'b0           ),
  .q_a       (                ),
  .q_b       ( spr_data4      )
);


hvgen hvgen(
  .clk_sys ( clk_sys ),
  .hb      ( hb      ),
  .vb      ( vb      ),
  .hs      ( hs      ),
  .vs      ( vs      ),
  .hcount  ( hcount  ),
  .vcount  ( vcount  ),
  .ce_pix  ( ce_pix  )
);

wire [7:0] hc = hcount[7:0];

always @* begin
    if (~yy[3])
      char_rom_addr = { bank, spr_data2[7], spr_data2[2:0], spr_data1, yy[2:0], xx[2] };
    else
      char_rom_addr = { bank, spr_data4[7], spr_data4[2:0], spr_data3, yy[2:0], xx[2] };
end

reg [16:0] vram_addr;
reg [7:0] vram_data;
reg vram_write;
wire [16:0] vram_read_addr = { vcount[0], hc };
reg vram_clear, vram_clear_old;
wire [7:0] vram_q_a;

always @(posedge clk_sys) begin
  vram_clear_old <= vram_clear;
  if (vram_clear) begin
    vram_clear <= 1'b0;
  end
  else if (vram_clear_old & ~vram_clear) begin
    pal_rom_addr <= vram_q_a;
  end
  else if (ce_pix & ~vb & ~hb) begin
    red <= pal_rom_data1;
    green <= pal_rom_data2;
    blue <= pal_rom_data3;
    vram_clear <= 1'b1;
  end
  else if (hc < 11 || hc > 248 || vcount < 17) begin
    red <= 0;
    green <= 0;
    blue <= 0;
  end
end

dpram #(9,8) vram(
  .address_a ( vram_read_addr     ),
  .address_b ( vram_addr          ),
  .clock     ( clk_sys            ),
  .data_a    ( 8'h0f              ),
  .data_b    ( vram_data          ),
  .rden_a    ( 1'b1               ),
  .rden_b    ( 1'b0               ),
  .wren_a    ( vram_clear         ),
  .wren_b    ( vram_write         ),
  .q_a       ( vram_q_a           ),
  .q_b       (                    )
);


wire [7:0] new_ram_data = {
  spr_attr[1],
  yy[3] ? spr_data4[5:3] : spr_data2[5:3],
  b1, b2, b3, b4
};


always @(posedge clk_sys) begin

  if (reset) begin

    obj_addr <= 0;
    spr_state <= 0;

  end else begin

    case (spr_state)

      0: begin

        spr_addr <= 13'h1500;
        obj_addr <= 13'h1500;
        xx <= 4'd0;
        if (hcount == 0 && ~vb) spr_state <= 1;

      end

      1: begin

        yp <= spr_vpos;
        id <= spr_data2;
        xp <= spr_data2[7:6] == 2'b11 ? xp + 8'd16 : spr_data3;
        spr_attr <= spr_data4;

        if (spr_data2[7]) // 16x256
          eff_addr <= { spr_data2[5:0], 7'd0 };
        else // 16x16
          eff_addr <= { spr_data2[4:0], 1'b0, spr_data2[6:5], 4'd0 } + 13'd12;

        if (~|(spr_data1|spr_data2|spr_data3|spr_data4))
          spr_state <= 5;
        else if (vcount+15 < spr_vpos[7:0] || vcount+15 > spr_btm) begin
          spr_state <= spr_data2[7] ? 2 : 5; // skip
        end
        else begin
          nxt_state <= 2;
          spr_state <= 6;
        end

      end

      2: begin

        vram_write <= 0;
        spr_addr <= eff_addr + { xx[3], yy[7:3], 1'b0 };
        nxt_state <= 4;
        spr_state <= 6;

      end

      4: begin

        spr_state <= 3;

      end

      3: begin
				if ({b1,b2,b3,b4}!=4'hf) begin

          vram_addr <= { ~vcount[0], px };
          vram_data <= new_ram_data;
          vram_write <= 1;
        end

        xx <= xx + 4'd1;
        spr_state <= 2;

        if (xx == 4'd15) begin
          spr_state <= 6;
          nxt_state <= 5;
        end

      end
      5: begin

        vram_write <= 0;

        obj_addr <= obj_addr + 13'd4;
        spr_addr <= obj_addr + 13'd4;

        xx <= 4'd0;

        if (vb) begin
          spr_state <= 0;
        end

        else if (obj_addr == 13'h17fc) begin
          obj_addr <= 13'h1980;
          spr_addr <= 13'h1980;
          spr_state <= 6;
          nxt_state <= 1;
        end

        else if (obj_addr >= 13'h19bc) begin
          spr_state <= 0;
        end

        else begin
          spr_state <= 6;
          nxt_state <= 1;
        end

      end

      6: begin
        spr_state <= 9;
      end
      9: begin
        spr_state <= nxt_state;
      end
    endcase

  end
end

endmodule
