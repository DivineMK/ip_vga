// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>
// Thomas Benz <tbenz@iis.ee.ethz.ch>

`include "common_cells/assertions.svh"
`include "common_cells/registers.svh"
`include "axi/typedef.svh"

/// Simple VGA IP capable of drawing frames from an external framebuffer.
module ip_vga #(
    parameter int unsigned RedWidth    = 5,
    parameter int unsigned GreenWidth  = 6,
    parameter int unsigned BlueWidth   = 5,
    parameter int unsigned HCountWidth = 32,
    parameter int unsigned VCountWidth = 32,
    parameter type         reg_req_t   = logic,
    parameter type         reg_resp_t  = logic
) (
    input logic clk_i,
    input logic rst_ni,

    input logic test_mode_en_i,

    // Regbus config ports
    // input  reg_req_t  reg_req_i,
    // output reg_resp_t reg_rsp_o,

    // Interrupts
    output logic frame_done_o,  // timing FSM signals end of visible area
    output logic vsync_start_o, // timing FSM signals start of VSYNC pulse

    // VGA interface
    output logic                  hsync_o,
    output logic                  vsync_o,
    output logic [  RedWidth-1:0] red_o,
    output logic [GreenWidth-1:0] green_o,
    output logic [ BlueWidth-1:0] blue_o
);
  import ip_vga_config_pkg::*;

  logic [7:0] clk_div;
  logic [7:0] clk_cnt_d, clk_cnt_q;

  // ip_vga_reg_pkg::axi_vga_reg2hw_t reg2hw;

  logic [  RedWidth-1:0] red;
  logic [GreenWidth-1:0] green;
  logic [ BlueWidth-1:0] blue;
  logic valid, ready;

  // Clock divider constant
  // assign clk_div   = |reg2hw.clk_div.q ? reg2hw.clk_div.q : 1;
  assign clk_div   = |ClkDiv ? ClkDiv : 1;

  // Cycle counter to scale the incoming clock
  assign clk_cnt_d = (clk_cnt_q < (clk_div - 1)) ? clk_cnt_q + 8'b0000_0001 : 8'b0;

  // Input: visible, vsync_start, valid
  // Output: r,g,b, ready
  //
  // localparam TB_LINEBUF = reg2hw.hori_visible_size.q / 8;
  logic [LineCharWidth-1:0][15:0]
      textbuffer_linebuf_d,
      textbuffer_linebuf_q;  // line buffer for fetching char code from text buffer (TB)
  logic [1:0][7:0] bitmap_buffer_d, bitmap_buffer_q;  // bitmap buffer for fetching from font
  logic [31:0] pixel_horz_q, pixel_horz_d, pixel_vert_q, pixel_vert_d;  // coordinate in pixel unit
  logic [28:0] char_horz, char_vert;  // coordinate in char unit

  assign char_horz = pixel_horz_q >> $clog2(FontWidth);
  assign char_vert = pixel_vert_q >> $clog2(FontHeight);

  // font request
  logic [$clog2(LineCharWidth)-1:0] font_req_idx_d, font_req_idx_q;  // index for request from textbuffer_linebuf and write to bitmap_buffer
  logic [FontAddrWidth-1:0] font_req;
  // font response
  logic [FontDataWidth-1:0] font_rsp;
  logic [FontWidthLog-1:0] font_sel_q, font_sel_d;  // select correct part from font_rsp
  logic font_cnt_q, font_cnt_d; // counter to wait for font response

  // text buffer (TB) request
  logic [$clog2(TBSize)-1:0] tb_req_idx_d, tb_req_idx_q; // index for request from TB and write to textbuffer_linebuf
  logic [TBAddrWidth-1:0] tb_req;
  // TB response
  logic [TBDataWidth-1:0] tb_rsp;
  logic tb_valid, tb_ready;
  logic tb_cnt_q, tb_cnt_d; // counter to wait for tb response

  typedef enum logic {
    FONT_REQ,
    FONT_IDLE
  } font_state_t;

  font_state_t font_state_q, font_state_d;

  typedef enum logic [1:0] {
    TB_INIT,
    TB_REQ,
    TB_IDLE
  } tb_state_t;
  tb_state_t tb_state_q, tb_state_d;

  // Regbus register interface
  // ip_vga_reg_top #(
  //     .reg_req_t(reg_req_t),
  //     .reg_rsp_t(reg_resp_t),
  //     .AW       (6)
  // ) i_ip_vga_register_file (
  //     .clk_i,
  //     .rst_ni,
  //     .reg_req_i,
  //     .reg_rsp_o,
  //     // To HW
  //     .reg2hw   (reg2hw),  // Write
  //     // Config
  //     .devmode_i('1)       // Explicit error for unmapped register access
  // );
  // TODO: reject burst split length larger than BufferDepth

  // FSM managing the VGA signals
  ip_vga_timing_fsm #(
      .RedWidth   (RedWidth),
      .GreenWidth (GreenWidth),
      .BlueWidth  (BlueWidth),
      .HCountWidth(HCountWidth),
      .VCountWidth(VCountWidth)
  ) i_ip_vga_timing_fsm (
      .clk_i,
      .rst_ni,

      .fsm_en_i(clk_cnt_q == 0),
      // .reg2hw_i(reg2hw),

      // Data input
      .red_i  (red),
      .green_i(green),
      .blue_i (blue),
      .valid_i(valid),
      .ready_o(ready),

      // Interrupts
      .frame_done_o,
      .vsync_start_o,

      // VGA interface
      .hsync_o,
      .vsync_o,
      .red_o,
      .green_o,
      .blue_o
  );

  font_rom #(
      .FontSize(FontSize),
      .FontWidth(FontWidth),
      .FontHeight(FontHeight),
      .FontDataWidth(FontDataWidth)
  ) i_font (
      .clk_i,
      .rst_ni,
      .req_addr_i(font_req),
      .rsp_data_o(font_rsp)
  );

  text_buffer #(
      .TBSize(TBSize),
      .TBAddrWidth(TBAddrWidth),
      .TBDataWidth(TBDataWidth)
  ) i_text_buffer (
      .clk_i,
      .rst_ni,
      .req_addr_i(tb_req),
      .rsp_data_o(tb_rsp),
      .ready_i(tb_ready), // TODO
      .valid_o(tb_valid)
  );

  assign valid = 1'b1;  // TODO
  assign tb_ready = 1'b1;

  always_comb begin : pixel_fsm
    pixel_horz_d = pixel_horz_q;
    pixel_vert_d = pixel_vert_q;

    if (ready) begin
      pixel_horz_d = pixel_horz_q - 1;
      if (pixel_horz_q == 0) begin  // avoid using _d var to avoid adder in path
        pixel_horz_d = HoriVisibleSize - 1;
        pixel_vert_d = pixel_vert_q - 1;
        if (pixel_vert_q == 0) begin
          pixel_vert_d = VertVisibleSize - 1;
        end
      end
    end
  end

  // always_comb begin : textbuffer_linebuf_init
  //   for (int unsigned i = LineCharWidth/2; i > 0; i -= 4) begin
  //     textbuffer_linebuf_d[(i-1)*2+:2] = 32'h00000001;
  //     textbuffer_linebuf_d[(i-2)*2+:2] = 32'h00020003;
  //     textbuffer_linebuf_d[(i-3)*2+:2] = 32'h00030002;
  //     textbuffer_linebuf_d[(i-4)*2+:2] = 32'h00010003;
  //   end
  //   // for (int i = 80; i > 0; i -= 4) begin
  //   //   textbuffer_linebuf[i]   = 16'h0000;
  //   //   textbuffer_linebuf[i-1] = 16'h0001;
  //   //   textbuffer_linebuf[i-2] = 16'h0002;
  //   //   textbuffer_linebuf[i-3] = 16'h0003;
  //   // end
  // end

  always_comb begin : tb_fsm
    tb_state_d = tb_state_q;
    textbuffer_linebuf_d = textbuffer_linebuf_q;
    tb_req_idx_d = tb_req_idx_q;
    tb_cnt_d = tb_cnt_q;
    tb_req = LineCharWidth/2 - 1 - tb_req_idx_q; // tb_req_idx is down counting, tb_req is up counting

    unique case (tb_state_q)
      TB_INIT: begin
        // TODO: determine better init condition
        if (rst_ni) begin
          tb_cnt_d = '0;
          tb_state_d = TB_REQ;
          tb_req_idx_d = LineCharWidth/2 - 1;
        end
      end

      TB_REQ: begin
        // TODO: need valid signal from tb
        tb_cnt_d = '1;
        if (tb_cnt_q == '1) begin
          // tb_rsp contains 2 char code
          textbuffer_linebuf_d[tb_req_idx_q*2+:2] = tb_rsp;
          tb_state_d = TB_IDLE;
        end
      end

      TB_IDLE: begin
        if (tb_ready) begin
          // prefetch 1 line
          tb_state_d = TB_REQ;
          tb_req_idx_d = tb_req_idx_q - 1;
          tb_cnt_d = '0;
          // when finished prefetching line
          if (tb_req_idx_q == 0) begin
            // wait for vsync
            if (~vsync_start_o) begin
              tb_state_d = TB_IDLE;
              tb_req_idx_d = tb_req_idx_q;
            end else begin
              tb_req_idx_d = LineCharWidth/2 - 1;
            end
          end
        end
      end

      // vsim warning
      default: begin
        tb_state_d = TB_INIT;
        tb_req_idx_d = LineCharWidth/2 - 1;
        tb_cnt_d = '0;
    end
    endcase
  end

  // request from font into bitmap_buffer
  always_comb begin : font_fsm
    font_req = textbuffer_linebuf_q[font_req_idx_q][7:0];
    font_req_idx_d = font_req_idx_q;
    font_state_d = font_state_q;
    font_sel_d = font_sel_q;
    font_cnt_d = font_cnt_q;
    bitmap_buffer_d = bitmap_buffer_q;

    unique case (font_state_q)
      FONT_REQ: begin
        font_cnt_d = '1;
        if (font_cnt_q == '1) begin
          bitmap_buffer_d[font_req_idx_q[0]] = font_rsp[font_sel_q*FontWidth+:FontWidth];
          font_state_d = FONT_IDLE;
        end
      end

      FONT_IDLE: begin
        // switch to FONT_REQ to prefetch 1 cycle before last pixel of char start
        // 1 cycle for req_idx_q to change, 1 cycle for font to response
        // depend on clk_div
        if (pixel_horz_q[2:0] == 1 && pixel_horz_d[2:0] == 0) begin
          font_state_d = FONT_REQ;
          font_cnt_d = '0;
          // at end of line
          if (char_horz == 0) begin
            font_sel_d = pixel_vert_q[2:0] - 1;  // move font_sel to next char vertically
            font_req_idx_d = LineCharWidth - 1;
          end else begin
            font_sel_d = pixel_vert_q[2:0];
            font_req_idx_d = char_horz - 1; // prefetch next char horizontally
          end
        end
      end

      default: begin
        font_req_idx_d = LineCharWidth - 1;
        font_state_d   = FONT_REQ;
        font_cnt_d     = '1;
      end
    endcase
  end

  // use bitmap_buffer to get current pixel bitmap
  // TODO: color from config bits
  assign {red, green, blue} = (bitmap_buffer_q[char_horz[0]][pixel_horz_q[2:0]] == 1) ? 16'hFFFF : 16'h0;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      clk_cnt_q <= '0;
      pixel_horz_q <= HoriVisibleSize - 1;
      pixel_vert_q <= VertVisibleSize - 1;

      font_req_idx_q <= LineCharWidth - 1;
      font_state_q <= FONT_REQ;
      font_sel_q <= FontHeight - 1;
      font_cnt_q <= '0;
      bitmap_buffer_q <= '0;

      tb_req_idx_q <= LineCharWidth/2 - 1;
      tb_state_q <= TB_INIT;
      tb_cnt_q <= '0;
      textbuffer_linebuf_q <= '0;
    end else begin
      clk_cnt_q <= clk_cnt_d;
      pixel_horz_q <= pixel_horz_d;
      pixel_vert_q <= pixel_vert_d;

      font_req_idx_q <= font_req_idx_d;
      font_state_q <= font_state_d;
      font_sel_q <= font_sel_d;
      font_cnt_q <= font_cnt_d;
      bitmap_buffer_q <= bitmap_buffer_d;

      tb_req_idx_q <= tb_req_idx_d;
      tb_state_q <= tb_state_d;
      tb_cnt_q <= tb_cnt_d;
      textbuffer_linebuf_q <= textbuffer_linebuf_d;
    end
  end
endmodule
