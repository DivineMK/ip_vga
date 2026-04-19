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
  logic [LineCharWidth-1:0][15:0] textbuffer_linebuf;
  logic [1:0][7:0] bitmap_buffer_d, bitmap_buffer_q;
  logic [31:0] pixel_horz_q, pixel_horz_d, pixel_vert_q, pixel_vert_d;
  logic [28:0] char_horz, char_vert;

  // font request
  logic [7:0] font_req_idx_d, font_req_idx_q;  // max = line_char_width = 80
  logic [FontAddrWidth-1:0] font_req;
  // font response
  logic [FontDataWidth-1:0] font_rsp;

  assign char_horz = pixel_horz_q >> $clog2(FontWidth);
  assign char_vert = pixel_vert_q >> $clog2(FontHeight);

  typedef enum logic [1:0] {
    INIT,
    REQ,
    IDLE
  } font_state_t;

  font_state_t font_state_q, font_state_d;
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

  assign valid = 1'b1;  // TODO

  always_comb begin : pixel_fsm
    pixel_horz_d = pixel_horz_q;
    pixel_vert_d = pixel_vert_q;

    if (ready) begin
      pixel_horz_d = pixel_horz_q + 1;
      if (pixel_horz_d == HoriVisibleSize) begin
        pixel_horz_d = 0;
        pixel_vert_d = pixel_vert_q + 1;
        if (pixel_vert_d == VertVisibleSize) begin
          pixel_vert_d = 0;
        end
      end
    end
  end

  always_comb begin : textbuffer_linebuf_init
    for (int i = 0; i < 80; i += 2) begin
      textbuffer_linebuf[i]   = 16'h0000;
      textbuffer_linebuf[i+1] = 16'h0001;
    end
  end

  always_comb begin : font_fsm
    font_req = textbuffer_linebuf[font_req_idx_q][7:0];
    font_req_idx_d = font_req_idx_q;
    font_state_d = font_state_q;
    bitmap_buffer_d[font_req_idx_q[0]] = bitmap_buffer_q[font_req_idx_q[0]];

    unique case (font_state_q)
      INIT: begin
        font_req_idx_d = 0;
        font_state_d   = REQ;
      end

      REQ: begin
        bitmap_buffer_d[font_req_idx_q[0]] = font_rsp[pixel_vert_q[2:0]*8+:8];
        font_state_d = IDLE;
      end

      IDLE: begin
        if (pixel_horz_q[2:0] == 3'd7 && pixel_horz_d[2:0] == 3'd0) begin
          font_req_idx_d = char_horz + 1;
          if (font_req_idx_d == LineCharWidth) font_req_idx_d = 0;
          font_state_d = REQ;
        end
      end

      default: begin
        font_state_d = INIT;
      end
    endcase
  end

  assign {red, green, blue} = (bitmap_buffer_q[char_horz[0]][pixel_horz_q[2:0]] == 1) ? 16'hFFFF : 16'h0;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      foreach (bitmap_buffer_q[i]) begin
        foreach (bitmap_buffer_q[i][j]) begin
          bitmap_buffer_q[i][j] <= 'b0;
        end
      end
    end else begin
      foreach (bitmap_buffer_q[i]) begin
        foreach (bitmap_buffer_q[i][j]) begin
          bitmap_buffer_q[i][j] <= bitmap_buffer_d[i][j];
        end
      end
    end
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      clk_cnt_q <= 'b0;
      pixel_horz_q <= 'b0;
      pixel_vert_q <= 'b0;
      font_req_idx_q <= 'b0;
      font_state_q <= INIT;
    end else begin
      clk_cnt_q <= clk_cnt_d;
      pixel_horz_q <= pixel_horz_d;
      pixel_vert_q <= pixel_vert_d;
      font_req_idx_q <= font_req_idx_d;
      font_state_q <= font_state_d;
    end
  end
endmodule
