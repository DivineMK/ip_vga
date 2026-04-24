import ip_vga_config_pkg::*;

module text_buffer #(
    parameter int unsigned TBSize = TBSize,
    parameter int unsigned TBAddrWidth = TBAddrWidth,
    parameter int unsigned TBDataWidth = TBDataWidth
) (
    input  logic                   clk_i,
    input  logic                   rst_ni,
    input  logic [TBAddrWidth-1:0] req_addr_i,
    output logic [TBDataWidth-1:0] rsp_data_o,
    input  logic                   ready_i,
    output logic                   valid_o
);

  logic [TBSize-1:0][TBDataWidth-1:0] tb;
  logic [TBAddrWidth-1:0] req_d, req_q;

  always_comb begin : tb_init
    for (int unsigned i = TBSize; i > 0; i -= 4) begin
      tb[i-1] = 32'h00000001;
      tb[i-2] = 32'h00020003;
      tb[i-3] = 32'h00030002;
      tb[i-4] = 32'h00000001;
    end
  end

  assign req_d = req_addr_i;
  assign rsp_data_o = tb[req_q];
  assign valid_o = ready_i; // TODO

  always_ff @(posedge clk_i, negedge rst_ni) begin : ff
    if (~rst_ni) begin
      req_q <= '0;
    end else begin
      req_q <= req_d;
    end
  end
endmodule
