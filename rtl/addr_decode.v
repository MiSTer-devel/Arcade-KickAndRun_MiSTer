
module addr_decode(

  input [15:0] mcpu_ab,
  input [15:0] scpu_ab,
  input [15:0] ecpu_ab,
  input [11:0] mcu_ab,
  input        ecpu_wr,
  input        ecpu_rd,

  output reg mcpu_rom1_en, // 0000-7FFF
  output reg mcpu_rom2_en, // 8000-BFFF (4000) bank
  output reg mcpu_scrn_en, // C000-E7FF /screen ram shared with subCPU
  output reg mcpu_ps4r_en, // E800-EFFF /ps4 shared ram MCU
  output reg mcpu_reg1_wr, // F000-F007
  output reg mcpu_reg2_wr, // F008-F00F
  output reg mcpu_in3_rd,  // F010-F017
  output reg mcpu_tmcl_en, // F018-F01F
  output reg mcpu_exit_en, // F800-FFFF (subram) shared with eCPU

  output reg scpu_rom_en,  // 0000-7FFF
  output reg scpu_wrk_en,  // 8000-A7FF
  output reg scpu_ram_en,  // A800-BFFF
  output reg scpu_snd_en,  // C000-FFFF

  output reg ecpu_rom_en,  // 0000-3FFF
  output reg ecpu_ram_en,  // 4000-7FFF (but RAM is only $800 on schematic)
  output reg ecpu_ext_en,  // 8000-BFFF shared with MCPU
  output reg ecpu_pt0_en,
  output reg ecpu_pt1_en,
  output reg ecpu_pt2_en,
  output reg ecpu_pt3_en,
  output reg ecpu_pt4_wr,
  output reg ecpu_tmc_en,

  output reg mcu_ps4_en,
  output reg mcu_jh_en,
  output reg mcu_jl_en

);

always @* begin

  mcpu_rom1_en = 0;
  mcpu_rom2_en = 0;
  mcpu_scrn_en = 0;
  mcpu_ps4r_en = 0;
  mcpu_reg1_wr = 0;
  mcpu_reg2_wr = 0;
  mcpu_in3_rd  = 0;
  mcpu_tmcl_en = 0;
  mcpu_exit_en = 0;

  scpu_rom_en = 0;
  scpu_wrk_en = 0;
  scpu_ram_en = 0;
  scpu_snd_en = 0;

  ecpu_rom_en = 0;
  ecpu_ram_en = 0;
  ecpu_ext_en = 0;
  ecpu_pt0_en = 0;
  ecpu_pt1_en = 0;
  ecpu_pt2_en = 0;
  ecpu_pt3_en = 0;
  ecpu_pt4_wr = 0;
  ecpu_tmc_en = 0;

  mcu_ps4_en = 0;
  mcu_jh_en  = 0;
  mcu_jl_en  = 0;

  if (mcpu_ab >= 16'hf800) begin
    mcpu_exit_en = 1; // /exit - com ram
  end
  else if (mcpu_ab >= 16'hf000) begin
    case (mcpu_ab[4:3])
      2'b00: mcpu_reg1_wr = 1; // f000
      2'b01: mcpu_reg2_wr = 1; // f008
      2'b10: mcpu_in3_rd  = 1; // f010
      2'b11: mcpu_tmcl_en = 1; // f018
    endcase
  end
  else if (mcpu_ab >= 16'he800) begin
    mcpu_ps4r_en = 1; // /ps4 - mcu shared ram
  end
  else if (mcpu_ab >= 16'hc000) begin
    mcpu_scrn_en = 1; // /screen - main ram, shared with snd CPU
  end
  else if (mcpu_ab >= 16'h8000) begin
    mcpu_rom2_en = 1; // bank
  end
  else begin
    mcpu_rom1_en = 1; // rom
  end

  case (scpu_ab[15:14])
    2'b00, 2'b01: scpu_rom_en = 1; // 0000-7FFF
    2'b10: begin
      if (scpu_ab < 16'ha800)
        scpu_wrk_en = 1;
      else
        scpu_ram_en = 1;
    end
    2'b11: scpu_snd_en = 1; // C000 YM
  endcase

  case (ecpu_ab[15:14])
    2'b00: ecpu_rom_en = 1;
    2'b01: ecpu_ram_en = 1;
    2'b10: ecpu_ext_en = 1;
    2'b11: begin
      if (ecpu_rd) begin // read
        case (ecpu_ab[1:0])
          2'b00: ecpu_pt0_en = 1; // joy/btn
          2'b01: ecpu_pt1_en = 1; // joy/btn
          2'b10: ecpu_pt2_en = 1; // coin/select/service
          2'b11: ecpu_pt3_en = 1; // coin/select/service
        endcase
      end
      else if (ecpu_wr) begin // write
        case (ecpu_ab[2:1])
          2'b00: /* N/A */;
          2'b01: ecpu_tmc_en = 1;
          2'b10: ecpu_pt4_wr = 1;
          2'b11: /* N/C */;
        endcase
      end
    end
  endcase

  // not used
  if (~mcu_ab[11]) begin
    if (~mcu_ab[0])
      mcu_jh_en = 1;
    else
      mcu_jl_en = 1;
  end
  else begin
    mcu_ps4_en = 1;
  end

end

endmodule
