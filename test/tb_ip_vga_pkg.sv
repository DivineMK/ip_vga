package tb_ip_vga_pkg;
  import tb_ip_vga_config_pkg::*;
  // testbench specific
  localparam int unsigned FrameWidth = tb_ip_vga_config_pkg::HoriVisibleSize;
  localparam int unsigned FrameHeight = tb_ip_vga_config_pkg::VertVisibleSize;

  localparam int unsigned RedWidth = 5;
  localparam int unsigned GreenWidth = 6;
  localparam int unsigned BlueWidth = 5;
  localparam int unsigned PixelWidth = 5 + 5 + 6;
  localparam int unsigned PixelByteWidth = PixelWidth / 8;
  localparam int unsigned ColorDepth = 8;  // per-pixel color depth of BMP file

  localparam int unsigned FullRenderWidth = tb_ip_vga_config_pkg::FullRenderWidth;
  localparam int unsigned FullRenderHeight = tb_ip_vga_config_pkg::FullRenderHeight;

  typedef struct packed {
    logic [RedWidth-1:0]   r;
    logic [GreenWidth-1:0] g;
    logic [BlueWidth-1:0]  b;
  } pixel_t;
  // defined in src
  // localparam int unsigned FontSize = 256;
  // localparam int unsigned FontAddrWidth = $clog2(FontSize);
  // localparam int unsigned FontWidth = 8;
  // localparam int unsigned FontHeight = 8;
  // localparam int unsigned FontDataWidth = 64; // font word size
  //
  // localparam int unsigned LineCharWidth = 80;
  // localparam int unsigned LineCharHeight = 25;
  //
  // localparam int unsigned HoriVisibleSize = FontWidth * LineCharWidth;
  // localparam int unsigned HoriFrontPorchSize = FontWidth * LineCharWidth;
  // localparam int unsigned HoriBackPorchSize = FontWidth * LineCharWidth;
  // localparam int unsigned HoriSyncSize = FontWidth * LineCharWidth;
  //
  // localparam int unsigned VertVisibleSize = FontHeight * LineCharHeight;
  // localparam int unsigned VertFrontPorchSize = FontWidth * LineCharWidth;
  // localparam int unsigned VertBackPorchSize = FontWidth * LineCharWidth;
  // localparam int unsigned VertSyncSize = FontWidth * LineCharWidth;
  //
  // localparam int unsigned ClkDiv = 1;
  // localparam logic ControlEnable = 1;
  // localparam logic ControlHsyncPol = 0;
  // localparam logic ControlVsyncPol = 0;

endpackage
