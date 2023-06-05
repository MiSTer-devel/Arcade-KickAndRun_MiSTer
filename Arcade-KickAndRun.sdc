derive_pll_clocks
derive_clock_uncertainty

set clk_sys {*|pll|pll_inst|altera_pll_i|*[0].*|divclk}

set_false_path -from [get_keepers {emu|u_core|scpu|scpu_4F|i_tv80_core|A[11]}]

set_multicycle_path -setup -end -to   [get_keepers {*_osd|osd_vcnt*}]    2
set_multicycle_path -hold -end -to    [get_keepers {*_osd|osd_vcnt*}]    1
set_multicycle_path -setup -end -from [get_keepers {emu|u_core|mcpu|*}]  2
set_multicycle_path -hold -end -from  [get_keepers {emu|u_core|mcpu|*}]  1
set_multicycle_path -setup -end -from [get_keepers {emu|u_core|scpu|*}]  2
set_multicycle_path -hold -end -from  [get_keepers {emu|u_core|scpu|*}]  1
set_multicycle_path -setup -end -from [get_keepers {emu|u_core|u_mcu|*}] 2
set_multicycle_path -hold -end -from  [get_keepers {emu|u_core|u_mcu|*}] 1
set_multicycle_path -setup -end -from [get_keepers {emu|u_core|ecpu|*}]  2
set_multicycle_path -hold -end -from  [get_keepers {emu|u_core|ecpu|*}]  1
