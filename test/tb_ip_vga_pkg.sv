package tb_ip_vga_pkg;
  localparam int unsigned FontSize = 256;
  localparam int unsigned FontAddrWidth = $clog2(FontSize);
  localparam int unsigned FontWidth = 8;
  localparam int unsigned FontHeight = 8;
  localparam int unsigned FontDataWidth = 64; // font word size

  localparam int unsigned LineCharWidth = 80;
  localparam int unsigned LineCharHeight = 25;

  localparam int unsigned FrameWidth = FontWidth * LineCharWidth;
  localparam int unsigned FrameHeight = FontHeight * LineCharHeight;

  localparam int unsigned HoriVisibleSize = FrameWidth;
  localparam int unsigned HoriFrontPorchSize = 32'h00000010;
  localparam int unsigned HoriBackPorchSize = 32'h00000060;
  localparam int unsigned HoriSyncSize = 32'h00000060;

  localparam int unsigned VertVisibleSize = FrameHeight;
  localparam int unsigned VertFrontPorchSize = 32'h0000000A;
  localparam int unsigned VertBackPorchSize = 32'h00000021;
  localparam int unsigned VertSyncSize = 32'h00000002;

  localparam int unsigned ClkDiv = 2;
  localparam logic ControlEnable = 1;
  localparam logic ControlHsyncPol = 0;
  localparam logic ControlVsyncPol = 0;

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
