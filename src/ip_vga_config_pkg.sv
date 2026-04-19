package ip_vga_config_pkg;
  localparam int unsigned FontSize = 256;
  localparam int unsigned FontAddrWidth = $clog2(FontSize);
  localparam int unsigned FontWidth = 8;
  localparam int unsigned FontHeight = 8;
  localparam int unsigned FontDataWidth = 64;  // font word size

  localparam int unsigned LineCharWidth = 80;
  localparam int unsigned LineCharHeight = 25;

  localparam int unsigned HoriVisibleSize = FontWidth * LineCharWidth;
  localparam int unsigned HoriFrontPorchSize = FontWidth * LineCharWidth;
  localparam int unsigned HoriBackPorchSize = FontWidth * LineCharWidth;
  localparam int unsigned HoriSyncSize = FontWidth * LineCharWidth;

  localparam int unsigned VertVisibleSize = FontHeight * LineCharHeight;
  localparam int unsigned VertFrontPorchSize = FontWidth * LineCharWidth;
  localparam int unsigned VertBackPorchSize = FontWidth * LineCharWidth;
  localparam int unsigned VertSyncSize = FontWidth * LineCharWidth;

  localparam int unsigned ClkDiv = 2;
  localparam logic ControlEnable = 1;
  localparam logic ControlHsyncPol = 0;
  localparam logic ControlVsyncPol = 0;
endpackage
