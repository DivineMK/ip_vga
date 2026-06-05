// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Khanh Lo <khanlo@student.ethz.ch>

`include "common_cells/registers.svh"

import ip_vga_config_pkg::*;

module text_buffer #(
    parameter int unsigned ObiAddrWidth  = 32,
    parameter int unsigned ObiDataWidth  = 32,
    parameter int unsigned ObiRDataWidth = ObiDataWidth,
    parameter int unsigned ObiIdWidth    = ObiIdWidth,
    parameter type         obi_req_t     = logic,
    parameter type         obi_rsp_t     = logic,

    parameter int unsigned TBSize = TBSize,
    parameter int unsigned TBAddrWidth = ObiAddrWidth,
    parameter int unsigned TBDataWidth = ObiRDataWidth
) (
    input  logic     clk_i,
    input  logic     rst_ni,
    input  obi_req_t obi_req_i,
    output obi_rsp_t obi_rsp_o
);

  logic [TBSize-1:0][TBDataWidth-1:0] tb;
  logic [TBAddrWidth-1:0] addr_d, addr_q;

  // OBI specific
  logic req_d, req_q;
  logic we_d, we_q;
  logic [ObiIdWidth-1:0] id_d, id_q;
  // logic [ObiDataWidth-1:0] wdata_d, wdata_q; // TODO: allow write

  always_comb begin : tb_init
    for (logic [15:0] i = 0; i < LineCharHeight; i += 2) begin
      for (logic [15:0] j = 0; j < LineCharWidth / 2; j += 4) begin
        // tb[i*LineCharWidth/2+(j+0)] = {{12'd0, i[3:0]}, {12'd0, j[3:0]}};
        tb[i*LineCharWidth/2+(j+0)] = 32'h00010002;
        tb[i*LineCharWidth/2+(j+1)] = 32'h00020003;
        tb[i*LineCharWidth/2+(j+2)] = 32'h00030002;
        tb[i*LineCharWidth/2+(j+3)] = 32'h00020001;
        // tb[(i-1)*LineCharWidth + (j-1)] = 32'h00010001;
        // tb[(i-1)*LineCharWidth + (j-2)] = 32'h00020002;
        // tb[(i-1)*LineCharWidth + (j-3)] = 32'h00030003;
        // tb[(i-1)*LineCharWidth + (j-4)] = 32'h00000000;
      end
    end

    for (logic [15:0] i = 1; i < LineCharHeight; i += 2) begin
      for (logic [15:0] j = 0; j < LineCharWidth / 2; j += 4) begin
        tb[i*LineCharWidth/2+(j+0)] = 32'h00000000;
        tb[i*LineCharWidth/2+(j+1)] = 32'h00030003;
        tb[i*LineCharWidth/2+(j+2)] = 32'h00020002;
        tb[i*LineCharWidth/2+(j+3)] = 32'h00010001;
      end
    end
  end

  // Request (A channel)
  // rready = 1
  assign req_d = obi_req_i.req;
  assign addr_d = obi_req_i.a.addr;
  assign we_d = obi_req_i.a.we;
  assign id_d = obi_req_i.a.aid;
  // Handshakes
  assign obi_rsp_o.gnt = obi_req_i.req;
  assign obi_rsp_o.rvalid = req_q;
  // Response (R channel)
  assign obi_rsp_o.r.rdata = tb[addr_q[TBAddrWidth-1:2]];
  assign obi_rsp_o.r.rid = id_q;
  assign obi_rsp_o.r.err = '0;
  // assign obi_rsp_o.r.r_optional = '0;

  `FF(addr_q, addr_d, '0);
  `FF(req_q, req_d, '0);
  `FF(we_q, we_d, '0);
  `FF(id_q, id_d, '0);
endmodule
