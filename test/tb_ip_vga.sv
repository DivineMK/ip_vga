// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>

`include "obi/typedef.svh"
// `include "register_interface/assign.svh"
// `include "register_interface/typedef.svh"

module tb_ip_vga;
  import ip_vga_config_pkg::*;  // needed in vsim for some reason?
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
  // Mem Depth
  localparam int unsigned NoCuts = 8;
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

  // AXI interface
  // verilog_format: off
  // `OBI_TYPEDEF_MINIMAL_A_OPTIONAL(ip_vga_tb_obi_a_optional_t)
  // `OBI_TYPEDEF_A_CHAN_T(ip_vga_tb_obi_a_chan_t, ObiAddrWidth, ObiDataWidth, ObiIdWidth, ip_vga_tb_obi_a_optional_t)
  // `OBI_TYPEDEF_REQ_T(ip_vga_tb_obi_req_t, ip_vga_tb_obi_a_chan_t)
  // `OBI_TYPEDEF_MINIMAL_R_OPTIONAL(ip_vga_tb_obi_r_optional_t)
  // `OBI_TYPEDEF_R_CHAN_T(ip_vga_tb_obi_r_chan_t, ObiDataWidth, ObiIdWidth, ip_vga_tb_obi_r_optional_t)
  // `OBI_TYPEDEF_RSP_T(ip_vga_tb_obi_rsp_t, ip_vga_tb_obi_r_chan_t)
  `OBI_TYPEDEF_DEFAULT_ALL(ip_vga_tb_obi, obi_pkg::ObiDefaultConfig)
  `OBI_TYPEDEF_DEFAULT_ALL(ip_vga_regs_obi, obi_pkg::ObiDefaultConfig)
  // verilog_format: on

  ip_vga_tb_obi_req_t ip_vga_tb_req, ip_vga_tb_req_delayed;
  ip_vga_tb_obi_rsp_t ip_vga_tb_rsp, ip_vga_tb_rsp_delayed;

  ip_vga_regs_obi_req_t ip_vga_regs_req;
  ip_vga_regs_obi_rsp_t ip_vga_regs_rsp;

  // logic [TBSize-1:0][31:0] tb;
  // always_comb begin
  //   for (logic [15:0] i = 0; i < LineCharHeight; i += 2) begin
  //     for (logic [15:0] j = 0; j < LineCharWidth / 2; j += 4) begin
  //       // tb[i*LineCharWidth/2+(j+0)] = {{12'd0, i[3:0]}, {12'd0, j[3:0]}};
  //       tb[i*LineCharWidth/2+(j+0)] = 32'h00010002;
  //       tb[i*LineCharWidth/2+(j+1)] = 32'h00020003;
  //       tb[i*LineCharWidth/2+(j+2)] = 32'h00030002;
  //       tb[i*LineCharWidth/2+(j+3)] = 32'h00010000;
  //     end
  //   end
  //
  //   for (logic [15:0] i = 1; i < LineCharHeight; i += 2) begin
  //     for (logic [15:0] j = 0; j < LineCharWidth / 2; j += 4) begin
  //       tb[i*LineCharWidth/2+(j+0)] = 32'h00000000;
  //       tb[i*LineCharWidth/2+(j+1)] = 32'h00030003;
  //       tb[i*LineCharWidth/2+(j+2)] = 32'h00020002;
  //       tb[i*LineCharWidth/2+(j+3)] = 32'h00010001;
  //     end
  //   end
  // end
  //
  // initial begin
  //   $info("Starting testbench for ip_vga...");
  //   for (logic [15:0] i = 0; i < 16; i++) begin
  //     $info("tb[%0d] = %0h", i, tb[i]);
  //   end
  //   $finish();
  // end

  initial begin
    $dumpfile("ip_vga.fst");
    $dumpvars(0, i_ip_vga);

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
    automatic bit [7:0] r8, g8, b8;
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
          // if ({i_ip_vga.red_o, i_ip_vga.green_o, i_ip_vga.blue_o} == 16'b0) begin
          //   $info("Error at time %0t in row %0d col %0d", $time, row, col);
          // end
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

  // text_buffer #(
  //     .TBSize(TBSize),
  //     .ObiAddrWidth(ObiAddrWidth),
  //     .ObiDataWidth(ObiDataWidth),
  //     .ObiIdWidth(ObiIdWidth),
  //     .obi_req_t(ip_vga_tb_obi_req_t),
  //     .obi_rsp_t(ip_vga_tb_obi_rsp_t)
  // ) i_text_buffer (
  //     .clk_i(clk),
  //     .rst_ni(rst_n),
  //     .obi_req_i(ip_vga_tb_req),
  //     .obi_rsp_o(ip_vga_tb_rsp)
  // );

  initial begin : textbuffer_init
    for (logic [15:0] i = 0; i < LineCharHeight; i += 1) begin
      for (logic [15:0] j = 0; j < LineCharWidth / 2; j += 1) begin
        i_obi_sim_mem.mem[((i+0)*LineCharWidth/2+j)*4+0] = {i[0], j[0]};
        i_obi_sim_mem.mem[((i+0)*LineCharWidth/2+j)*4+1] = 8'h00;
        i_obi_sim_mem.mem[((i+0)*LineCharWidth/2+j)*4+2] = {j[0], i[0]};
        i_obi_sim_mem.mem[((i+0)*LineCharWidth/2+j)*4+3] = 8'h00;
      end
    end

    // for (logic [15:0] i = 1; i < LineCharHeight; i += 2) begin
    //   for (logic [15:0] j = 0; j < LineCharWidth / 2; j += 1) begin
    //     for (logic [2:0] k = 0; k < 4; k++) begin
    //       if (k % 2 == 1) begin
    //         i_obi_sim_mem.mem[((i+0)*LineCharWidth/2+j)*4+k] = 8'h00;
    //       end else begin
    //         i_obi_sim_mem.mem[((i+0)*LineCharWidth/2+j)*4+k] = i[1:0] + j[1:0];
    //       end
    //     end
    //   end
    // end
    // for (logic [15:0] i = 1; i < LineCharHeight; i += 2) begin
    //   for (logic [15:0] j = 0; j < LineCharWidth / 2; j += 4) begin
    //     i_obi_sim_mem.mem[i*LineCharWidth/2+(j+0)] = 32'h00000000;
    //     i_obi_sim_mem.mem[i*LineCharWidth/2+(j+1)] = 32'h00030003;
    //     i_obi_sim_mem.mem[i*LineCharWidth/2+(j+2)] = 32'h00020002;
    //     i_obi_sim_mem.mem[i*LineCharWidth/2+(j+3)] = 32'h00010001;
    //   end
    // end
  end

  obi_sim_mem #(
      .ObiCfg           (obi_pkg::ObiDefaultConfig),
      .obi_req_t        (ip_vga_tb_obi_req_t),
      .obi_rsp_t        (ip_vga_tb_obi_rsp_t),
      .obi_r_chan_t     (ip_vga_tb_obi_r_chan_t),
      .WarnUninitialized('1),
      .ClearErrOnAccess ('0),                         // not used
      .ApplDelay        (ClkPeriod * 0.3),
      .AcqDelay         (ClkPeriod * 0.8)
  ) i_obi_sim_mem (
      .clk_i      (clk),
      .rst_ni     (rst_n),
      .obi_req_i  (ip_vga_tb_req_delayed),
      .obi_rsp_o  (ip_vga_tb_rsp_delayed),
      // Memory monitor signals for debugging
      .mon_valid_o(),
      .mon_we_o   (),
      .mon_addr_o (),
      .mon_wdata_o(),
      .mon_be_o   (),
      .mon_id_o   ()
  );

  if (NoCuts == '0) begin : gen_obi_cuts_bypass
    assign ip_vga_tb_rsp = ip_vga_tb_rsp_delayed;
    assign ip_vga_tb_req_delayed = ip_vga_tb_req;
  end else begin : gen_obi_cut
    ip_vga_tb_obi_req_t [NoCuts:0] req_cuts;
    ip_vga_tb_obi_rsp_t [NoCuts:0] rsp_cuts;

    assign req_cuts[0] = ip_vga_tb_req;
    assign ip_vga_tb_rsp = rsp_cuts[0];

    assign ip_vga_tb_req_delayed = req_cuts[NoCuts];
    assign rsp_cuts[NoCuts] = ip_vga_tb_rsp_delayed;

    for (genvar i = 0; i < NoCuts; i++) begin : gen_obi_cuts
      obi_cut #(
          .ObiCfg(obi_pkg::ObiDefaultConfig),
          .obi_a_chan_t(ip_vga_tb_obi_a_chan_t),
          .obi_r_chan_t(ip_vga_tb_obi_r_chan_t),
          .obi_req_t(ip_vga_tb_obi_req_t),
          .obi_rsp_t(ip_vga_tb_obi_rsp_t),
          .BypassReq(1'b0),
          .BypassRsp(1'b0)
      ) i_obi_cut (
          .clk_i         (clk),
          .rst_ni        (rst_n),
          .sbr_port_req_i(req_cuts[i]),
          .sbr_port_rsp_o(rsp_cuts[i]),
          .mgr_port_req_o(req_cuts[i+1]),
          .mgr_port_rsp_i(rsp_cuts[i+1])
      );
    end
  end


  ip_vga #(
      .RedWidth   (RedWidth),
      .GreenWidth (GreenWidth),
      .BlueWidth  (BlueWidth),
      .HCountWidth(12),
      .VCountWidth(12),
      .obi_req_t  (ip_vga_tb_obi_req_t),
      .obi_rsp_t  (ip_vga_tb_obi_rsp_t),
      .reg_req_t  (ip_vga_regs_obi_req_t),
      .reg_rsp_t  (ip_vga_regs_obi_rsp_t)
  ) i_ip_vga (
      .clk_i (clk),
      .rst_ni(rst_n),

      .test_mode_en_i(1'b0),

      // Regbus config ports
      .reg_req_i(ip_vga_regs_req),
      .reg_rsp_o(ip_vga_regs_rsp),
      //
      // // AXI Data ports
      // .axi_req_o (vga_axi_req),
      // .axi_rsp_i(vga_axi_rsp),

      // VGA interface
      .hsync_o(),
      .vsync_o(),
      .red_o  (),
      .green_o(),
      .blue_o (),

      .obi_req_o(ip_vga_tb_req),
      .obi_rsp_i(ip_vga_tb_rsp),

      .vsync_start_o(),
      .frame_done_o ()
  );


endmodule
