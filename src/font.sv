module font #(
    parameter int unsigned FontSize = 256,
    parameter int unsigned FontAddrWidth = $clog2(FontSize),
    parameter int unsigned FontDataWidth = 64
) (
    input  logic                       clk_i,
    input  logic                       rst_ni,
    // Read port
    input  logic [  FontAddrWidth-1:0] req_addr_i,
    output logic [  FontDataWidth-1:0] rsp_data_o,
    // Write port
    input  logic                       wr_req_i,
    input  logic [  FontAddrWidth-1:0] wr_addr_i,
    input  logic [  FontDataWidth-1:0] wr_data_i,
    input  logic [FontDataWidth/8-1:0] wr_be_i
);

  logic [FontSize-1:0][FontDataWidth-1:0] font_init_data;

  // https://github.com/alexfru/512_8/blob/master/512_8_bold.txt
  // ........ ........ ........ ........ ........ ........ ........ ........ ........ ........ ........ ........ ........ ........ ........
  // ...O.... OOOOOO.. .OOOOO.. OOOOOO.. OOOOOOO. OOOOOOO. .OOOOO.. OO...OO. OOOOOO.. ...OOOO. OOO..OO. OOOO.... OO...OO. OO...OO. .OOOOO..
  // ..OOO... .OO..OO. OO...OO. .OO..OO. .OO...O. .OO...O. OO...OO. OO...OO. ..OO.... ....OO.. .OO.OO.. .OO..... OOO.OOO. OOO..OO. OO...OO.
  // .OO.OO.. .OOOOO.. OO...... .OO..OO. .OOOO... .OOOO... OO...... OOOOOOO. ..OO.... ....OO.. .OOOO... .OO..... OOOOOOO. OO.O.OO. OO...OO.
  // .OO.OO.. .OO..OO. OO...... .OO..OO. .OO..... .OO..... OO..OOO. OO...OO. ..OO.... ....OO.. .OO.OO.. .OO..... OO.O.OO. OO.O.OO. OO...OO.
  // OOOOOOO. .OO..OO. OO...OO. .OO..OO. .OO...O. .OO..... OO...OO. OO...OO. ..OO.... OO..OO.. .OO..OO. .OO..O.. OO...OO. OO..OOO. OO...OO.
  // OO...OO. OOOOOO.. .OOOOO.. OOOOOO.. OOOOOOO. OOOO.... .OOOOO.. OO...OO. OOOOOO.. .OOOO... OOO..OO. OOOOOO.. OO...OO. OO...OO. .OOOOO..
  // ........ ........ ........ ........ ........ ........ ........ ........ ........ ........ ........ ........ ........ ........ ........
  always_comb begin : font_init
    for (int unsigned i = 0; i < FontSize; i += 4) begin
      font_init_data[i] = {
        8'b00000000, // ........
        8'b00010000, // ...O....
        8'b00111000, // ..OOO...
        8'b01101100, // .OO.OO..
        8'b01101100, // .OO.OO..
        8'b11111110, // OOOOOOO.
        8'b11000110, // OO...OO.
        8'b00000000  // ........
      };

      font_init_data[i+1] = {
        8'b00000000, // ........
        8'b11111100, // OOOOOO..
        8'b01100110, // .OO..OO.
        8'b01111100, // .OOOOO..
        8'b01100110, // .OO..OO.
        8'b01100110, // .OO..OO.
        8'b11111100, // OOOOOO..
        8'b00000000  // ........
      };

      font_init_data[i+2] = {
        8'b00000000, // ........
        8'b01111100, // .OOOOO..
        8'b11000110, // OO...OO.
        8'b11000000, // OO......
        8'b11000000, // OO......
        8'b11000110, // OO...OO.
        8'b01111100, // .OOOOO..
        8'b00000000  // ........
      };

      font_init_data[i+3] = {
        8'b00000000, // ........
        8'b11111100, // OOOOOO..
        8'b01100110, // .OO..OO.
        8'b01100110, // .OO..OO.
        8'b01100110, // .OO..OO.
        8'b01100110, // .OO..OO.
        8'b11111100, // OOOOOO..
        8'b00000000  // ........
      };
    end
  end

  logic [FontAddrWidth-1:0] init_cnt_q, init_cnt_d;
  logic init_done_q, init_done_d;

  always_ff @(posedge clk_i, negedge rst_ni) begin : init_seq
    if (~rst_ni) begin
      init_cnt_q  <= '0;
      init_done_q <= 1'b0;
    end else begin
      init_cnt_q  <= init_cnt_d;
      init_done_q <= init_done_d;
    end
  end

  always_comb begin : init_ctrl
    init_cnt_d  = init_cnt_q;
    init_done_d = init_done_q;
    if (~init_done_q) begin
      if (init_cnt_q == FontSize - 1) begin
        init_done_d = 1'b1;
      end else begin
        init_cnt_d = init_cnt_q + 1'b1;
      end
    end
  end

  logic                       sram_we;
  logic [  FontAddrWidth-1:0] sram_addr;
  logic [  FontDataWidth-1:0] sram_wdata;
  logic [FontDataWidth/8-1:0] sram_be;
  logic [  FontDataWidth-1:0] sram_rdata;

  assign sram_we    = ~init_done_q | wr_req_i;
  assign sram_addr  = ~init_done_q ? init_cnt_q : wr_req_i ? wr_addr_i : req_addr_i;
  assign sram_wdata = ~init_done_q ? font_init_data[init_cnt_q] : wr_data_i;
  assign sram_be    = ~init_done_q ? '1 : wr_be_i;

  assign rsp_data_o = init_done_q ? sram_rdata : '0;

  tc_sram_impl #(
      .NumWords (FontSize),
      .DataWidth(FontDataWidth),
      .ByteWidth(8),
      .NumPorts (1),
      .Latency  (1),
      .SimInit  ("none")
  ) i_tc_sram (
      .clk_i,
      .rst_ni,
      .req_i  (1'b1),
      .we_i   (sram_we),
      .addr_i (sram_addr),
      .wdata_i(sram_wdata),
      .be_i   (sram_be),
      .rdata_o(sram_rdata),
      .impl_i ('0),
      .impl_o ()
  );

endmodule
