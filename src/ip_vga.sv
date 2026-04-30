// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>
// Thomas Benz <tbenz@iis.ee.ethz.ch>

`include "common_cells/assertions.svh"
`include "common_cells/registers.svh"
`include "obi/typedef.svh"

/// Simple VGA IP capable of drawing frames from an external framebuffer.
module ip_vga #(
    parameter int unsigned RedWidth      = 5,
    parameter int unsigned GreenWidth    = 6,
    parameter int unsigned BlueWidth     = 5,
    parameter int unsigned HCountWidth   = 32,
    parameter int unsigned VCountWidth   = 32,
    parameter int unsigned OBIAddrWidth  = 32,
    parameter int unsigned OBIDataWidth  = 32,
    parameter int unsigned OBIRDataWidth = 32,
    parameter int unsigned OBIIDWidth    = 1,
    parameter type         obi_req_t     = logic,
    parameter type         obi_rsp_t     = logic
    // parameter type         reg_req_t   = logic,
    // parameter type         reg_rsp_t  = logic
) (
    input logic clk_i,
    input logic rst_ni,

    input logic test_mode_en_i,

    // Regbus config ports
    // input  reg_req_t  reg_req_i,
    // output reg_rsp_t reg_rsp_o,

    // OBI Data ports
    output obi_req_t obi_req_o,
    input  obi_rsp_t obi_rsp_i,

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

  logic timing_ready;
  logic [7:0] clk_div;
  logic [7:0] clk_cnt_d, clk_cnt_q;

  // ip_vga_reg_pkg::axi_vga_reg2hw_t reg2hw;

  logic [  RedWidth-1:0] red;
  logic [GreenWidth-1:0] green;
  logic [ BlueWidth-1:0] blue;

  // Clock divider constant
  // assign clk_div   = |reg2hw.clk_div.q ? reg2hw.clk_div.q : 1;
  assign clk_div   = |ClkDiv ? ClkDiv : 1;

  // Cycle counter to scale the incoming clock
  assign clk_cnt_d = (clk_cnt_q < (clk_div - 1)) ? clk_cnt_q + 8'b0000_0001 : 8'b0;

  // Regbus register interface
  // ip_vga_reg_top #(
  //     .reg_req_t(reg_req_t),
  //     .reg_rsp_t(reg_rsp_t),
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
      .valid_i('1),
      .ready_o(timing_ready),

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

  ip_vga_fetcher #(
      .RedWidth  (RedWidth),
      .GreenWidth(GreenWidth),
      .BlueWidth (BlueWidth),
      .obi_req_t (obi_req_t),
      .obi_rsp_t (obi_rsp_t)
  ) i_ip_vga_fetcher (
      .clk_i,
      .rst_ni,

      .vsync_start_i (vsync_start_o),
      .timing_ready_i(timing_ready),

      .obi_req_o,
      .obi_rsp_i,

      .red_o  (red),
      .green_o(green),
      .blue_o (blue)
  );

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      clk_cnt_q <= '0;
    end else begin
      clk_cnt_q <= clk_cnt_d;
    end
  end
endmodule
