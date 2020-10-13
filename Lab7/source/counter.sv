// $Id: $
// File name:   counter.sv
// Created:     10/13/2020
// Author:      Jiahao Xu
// Lab Section: 337-002
// Version:     1.0  Initial Design Entry
// Description: .
module counter(clk, n_rst, cnt_up, clear, one_k_samples);
    input wire clk, n_rst, cnt_up, clear, one_k_samples;
    localparam NUM_BITS = 12;
    localparam VAL = 1000;
    flex_counter #(NUM_BITS) flx_cnt (
        .clk(clk), .n_rst(n_rst), 
        .clear(clear), .count_enable(cnt_up), 
        .rollover_val(VAL), .rollover_flag(one_k_samples)
    );
endmodule