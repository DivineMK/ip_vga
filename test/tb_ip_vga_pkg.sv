// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Khanh Lo <khanlo@student.ethz.ch>

package tb_ip_vga_pkg;
  export ip_vga_config_pkg::*;
  import ip_vga_config_pkg::*;

  // testbench specific
  localparam int unsigned RedWidth = 5;
  localparam int unsigned GreenWidth = 6;
  localparam int unsigned BlueWidth = 5;
  localparam int unsigned PixelWidth = 5 + 5 + 6;
  localparam int unsigned PixelByteWidth = PixelWidth / 8;
  localparam int unsigned ColorDepth = 8;  // per-pixel color depth of BMP file

  localparam int unsigned FullRenderWidth = HoriVisibleSize + HoriFrontPorchSize 
                                        + HoriBackPorchSize + HoriSyncSize;
  localparam int unsigned FullRenderHeight = VertVisibleSize + VertFrontPorchSize 
                                        + VertBackPorchSize + VertSyncSize;

  typedef struct packed {
    logic [RedWidth-1:0]   r;
    logic [GreenWidth-1:0] g;
    logic [BlueWidth-1:0]  b;
  } pixel_t;

endpackage
