// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>

`include "axi/typedef.svh"
`include "register_interface/assign.svh"
`include "register_interface/typedef.svh"

module tb_ip_vga;
  import tb_ip_vga_pkg::*;

  localparam int unsigned ClkPeriod = 20ns;

  // // AXI parameters
  // localparam int unsigned AXIAddrWidth = 48;
  // localparam int unsigned AXIDataWidth = 64;
  // localparam int unsigned AXIStrbWidth = 8;
  // localparam int unsigned AXIIdWidth = 2;
  // localparam int unsigned AXIUserWidth = 1;
  //
  // // Buffer
  // localparam int unsigned BufferDepth = 16;
  // localparam int unsigned MaxReadTxns = 24;
  // // Mem Depth
  // localparam int unsigned MemDepth = 32;
  //
  // // RegBus parameters
  // localparam int unsigned RegBusAddrWidth = 48;
  // localparam int unsigned RegBusDataWidth = 32;
  // localparam int unsigned RegBusStrbWidth = 4;

  logic clk, rst_n;

  clk_rst_gen #(
      .ClkPeriod   (ClkPeriod),
      .RstClkCycles(5)
  ) i_clk_rst (
      .clk_o (clk),
      .rst_no(rst_n)
  );

  // // AXI interface
  // `AXI_TYPEDEF_ALL(ip_vga_tb, logic [AXIAddrWidth-1:0], logic [AXIIdWidth-1:0],
  //                  logic [AXIDataWidth-1:0], logic [AXIStrbWidth-1:0], logic [AXIUserWidth-1:0])
  //
  // ip_vga_tb_req_t vga_axi_req, vga_axi_req_dly;
  // ip_vga_tb_resp_t vga_axi_resp, vga_axi_resp_dly;
  //
  // // RegBus interface
  // `REG_BUS_TYPEDEF_ALL(reg_vga_tb, logic [RegBusAddrWidth-1:0], logic [RegBusDataWidth-1:0],
  //                      logic [RegBusStrbWidth-1:0])
  //
  // REG_BUS #(
  //     .ADDR_WIDTH(RegBusAddrWidth),
  //     .DATA_WIDTH(RegBusDataWidth)
  // ) i_tb_regbus (
  //     .clk_i(clk)
  // );
  //
  // typedef reg_test::reg_driver#(
  //     .AW(RegBusAddrWidth),
  //     .DW(RegBusDataWidth)
  // ) reg_driver_t;
  //
  // reg_driver_t tb_reg_driver = new(i_tb_regbus);
  //
  // reg_vga_tb_req_t vga_reg_req;
  // reg_vga_tb_rsp_t vga_reg_rsp;
  //
  // `REG_BUS_ASSIGN_TO_REQ(vga_reg_req, i_tb_regbus)
  // `REG_BUS_ASSIGN_FROM_RSP(i_tb_regbus, vga_reg_rsp)
  //
  //
  // typedef struct {
  //   logic [AXIAddrWidth-1:0] addr;
  //   logic [AXIDataWidth-1:0] data;
  //   string desc;
  // } reg_write_t;
  //
  // logic bus_error = 0;
  //
  // // Initiate VGA driver - 32x16 testing mode
  // initial begin
  //   automatic
  //   reg_write_t
  //   writes[] = '{
  //       '{ip_vga_CLK_DIV_OFFSET, cfg.clk_div, "Clock divider"},
  //       '{AXI_VGA_HORI_VISIBLE_SIZE_OFFSET, cfg.hori_visible_size, "Horizontal visible frame size"},
  //       '{
  //           AXI_VGA_HORI_FRONT_PORCH_SIZE_OFFSET,
  //           cfg.hori_front_porch_size,
  //           "Horizontal front porch"
  //       },
  //       '{AXI_VGA_HORI_SYNC_SIZE_OFFSET, cfg.hori_sync_size, "Horizontal sync part"},
  //       '{AXI_VGA_HORI_BACK_PORCH_SIZE_OFFSET, cfg.hori_back_porch_size, "Horizontal back porch"},
  //       '{AXI_VGA_VERT_VISIBLE_SIZE_OFFSET, cfg.vert_visible_size, "Vertical visible frame size"},
  //       '{AXI_VGA_VERT_FRONT_PORCH_SIZE_OFFSET, cfg.vert_front_porch_size, "Vertical front porch"},
  //       '{AXI_VGA_VERT_SYNC_SIZE_OFFSET, cfg.vert_sync_size, "Vertical sync part"},
  //       '{AXI_VGA_VERT_BACK_PORCH_SIZE_OFFSET, cfg.vert_back_porch_size, "Vertical back porch"},
  //       '{AXI_VGA_START_ADDR_LOW_OFFSET, cfg.start_addr_low, "Low end of frame buffer"},
  //       '{AXI_VGA_START_ADDR_HIGH_OFFSET, cfg.start_addr_high, "High end of frame buffer"},
  //       '{AXI_VGA_FRAME_SIZE_OFFSET, cfg.frame_size, "Frame size (#pixels)"},
  //       '{AXI_VGA_BURST_LEN_OFFSET, cfg.burst_len, "Prefetch burst length"},
  //       '{AXI_VGA_BURST_SPLIT_LEN_OFFSET, cfg.burst_split_len, "AXI burst length"}
  //   };
  //
  //   #(10 * ClkPeriod);
  //   tb_reg_driver.reset_master();
  //   #(10 * ClkPeriod);
  //
  //   for (int i = 0; i < writes.size(); i++) begin
  //     $info("TEST: %s", writes[i].desc);
  //     tb_reg_driver.send_write(writes[i].addr, writes[i].data, 4'hF, bus_error);
  //     assert (!bus_error)
  //     else $fatal("Write to VGA cfg reg (0x%0h) failed", writes[i].addr);
  //   end
  //
  //   $info("TEST: FSM enable");
  //   tb_reg_driver.send_write(AXI_VGA_CONTROL_OFFSET, 32'h1, 4'hf, bus_error);
  //   assert (!bus_error)
  //   else $fatal("Write to VGA cfg reg (0x%0h) failed", AXI_VGA_CONTROL_OFFSET);
  //
  //   $info("TEST: Render");
  //   // See frame capture bock below
  //   #(3 * ClkPeriod * cfg.clk_div * FullRenderHeight * FullRenderWidth);
  //   #(5000 * ClkPeriod);
  //   $info("TIMEOUT");
  //   $finish();
  // end

  initial begin
    $dumpfile("ip_vga.fst");
    $dumpvars(0, ip_vga);

    #(3 * ClkPeriod * ClkDiv * FullRenderHeight * FullRenderWidth);
    #(5000 * ClkPeriod);
    $info("TIMEOUT");
    $finish();
  end

  final begin
    $dumpflush;
  end

  pixel_t framebuffer[FrameHeight][FrameWidth];

  task write_frame_to_bmp(string file);
    automatic int fd, fd_debug;
    automatic int i, j;
    automatic byte r8, g8, b8;
    automatic int row_pad = (4 - (FrameWidth * 3) % 4) % 4;  // pad row to 4-byte aligned
    automatic int filesize = 54 + (FrameWidth * 3 + row_pad) * FrameHeight;

    fd = $fopen(file, "wb");
    fd_debug = $fopen("bmp_write_dump.txt", "w");

    // bitmap header (14 bytes)
    $fwrite(fd, "%c%c", "B", "M");  // signature (fixed)
    $fwrite(fd, "%u", filesize);  // file size (#bytes)
    $fwrite(fd, "%u", 0);  // reserved
    $fwrite(fd, "%u", 54);  // data offset

    // DIP header (BITMAPINFOHEADER)
    $fwrite(fd, "%u", 40);  // header size
    $fwrite(fd, "%u", FrameWidth);  // img width (#pixels)
    $fwrite(fd, "%u", FrameHeight);  // img height (#pixels)
    $fwrite(fd, "%u", 32'h00_18_00_01);  // #planes (must be 1), #bits per pixel (24)
    $fwrite(fd, "%u", 0);  // compression (no)
    $fwrite(fd, "%u", (FrameWidth * 3 + row_pad) * FrameHeight);  // image size
    $fwrite(fd, "%u", 1000);  // X pixels/meter
    $fwrite(fd, "%u", 1000);  // Y pixels/meter
    $fwrite(fd, "%u", 0);  // colors used
    $fwrite(fd, "%u", 0);  // important colors

    // Pixels (format:BGR, frame bottom-up)
    for (i = FrameHeight - 1; i >= 0; i--) begin
      for (j = 0; j < FrameWidth; j++) begin
        r8 = framebuffer[i][j].r << (8 - RedWidth);
        g8 = framebuffer[i][j].g << (8 - GreenWidth);
        b8 = framebuffer[i][j].b << (8 - BlueWidth);
        $fwrite(fd, "%c%c%c", b8, g8, r8);
        $fwrite(fd_debug, "(row=%0d, col=%0d): R=%0d, G=%0d, B=%0d\n", FrameHeight - 1 - i, j, r8,
                g8, b8);
      end
      for (j = 0; j < row_pad; j++) $fwrite(fd, "%c", 8'h00);
    end

    $fclose(fd_debug);
    $fclose(fd);
  endtask


  initial begin : frame_capture
    automatic int clk_div_counter = 0;
    automatic int hsync_porch = 0, vsync_porch = 0;
    automatic bit hsync_prev = 0, vsync_prev = 0;
    automatic int row = 0, col = 0;
    automatic int frame_num = 0;
    automatic bit capturing = 0;
    automatic string file;

    wait (rst_n === 0);
    @(posedge rst_n);
    @(negedge i_ip_vga.vsync_o);  // sync capturing on first vsync
    forever begin
      // before the divided clock, capture the previous values
      if (clk_div_counter == '0) begin
        hsync_prev = i_ip_vga.hsync_o;
        vsync_prev = i_ip_vga.vsync_o;
      end

      @(posedge clk);
      #(0.8 * ClkPeriod);

      // clock divider: skip rest except every N-th clock edge
      clk_div_counter++;
      if (clk_div_counter < ClkDiv) begin
        continue;
      end else begin
        clk_div_counter = 0;
      end

      // start capturing frame after vsync pulse
      if (vsync_prev == ControlVsyncPol && i_ip_vga.vsync_o == ~ControlVsyncPol) begin
        vsync_porch = 0;
        hsync_porch = 0;
        row = 0;
        col = 0;
        capturing = 1;
        $info("VSYNC PULSE: Start capturing frame");
        continue;
      end

      // skip vertical back porch
      if (capturing && vsync_porch < VertBackPorchSize) begin
        if (hsync_prev == ControlHsyncPol && i_ip_vga.hsync_o == ~ControlHsyncPol) begin
          vsync_porch++;
        end
        continue;
      end


      // capture lines with visible area
      if (capturing && row < FrameHeight) begin
        // start capturing current line after hsync pulse
        if (hsync_prev == ControlHsyncPol && i_ip_vga.hsync_o == ~ControlHsyncPol) begin
          hsync_porch = 0;
          col = 0;
          row++;
          $info("Capturing line no #%0d", row);
          continue;
        end

        // skip horizontal back porch
        if (hsync_porch < (HoriBackPorchSize - 1)) begin
          hsync_porch++;
          continue;
        end

        // capture pixel in visible area of this line
        if (col < FrameWidth) begin
          framebuffer[row][col].r = i_ip_vga.red_o;
          framebuffer[row][col].g = i_ip_vga.green_o;
          framebuffer[row][col].b = i_ip_vga.blue_o;
          col++;
        end
      end

      if (capturing && row == FrameHeight) begin
        file = $sformatf("frame_%0d.bmp", frame_num++);
        write_frame_to_bmp(file);
        $info("Frame #%0d captured to %s", frame_num - 1, file);
        capturing = 0;
      end
    end
  end

  ip_vga #(
      .RedWidth   (RedWidth),
      .GreenWidth (GreenWidth),
      .BlueWidth  (BlueWidth),
      .HCountWidth(12),
      .VCountWidth(12)
      // .axi_req_t   (ip_vga_tb_req_t),
      // .axi_resp_t  (ip_vga_tb_resp_t),
      // .reg_req_t   (reg_vga_tb_req_t),
      // .reg_resp_t  (reg_vga_tb_rsp_t)
  ) i_ip_vga (
      .clk_i (clk),
      .rst_ni(rst_n),

      .test_mode_en_i(1'b0),

      // Regbus config ports
      // .reg_req_i(vga_reg_req),
      // .reg_rsp_o(vga_reg_rsp),
      //
      // // AXI Data ports
      // .axi_req_o (vga_axi_req),
      // .axi_resp_i(vga_axi_resp),

      // VGA interface
      .hsync_o(),
      .vsync_o(),
      .red_o  (),
      .green_o(),
      .blue_o ()
  );


endmodule
