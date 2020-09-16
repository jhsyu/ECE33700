// $Id: $
// File name:   sync_low.sv
// Created:     9/16/2020
// Author:      Jiahao Xu
// Lab Section: 337-002
// Version:     1.0  Initial Design Entry
// Description: . 

module sync_low (
    clk, 
    n_rst,
    async_in,
    sync_out,
);
    input logic clk, n_rst, async_in;
    output logic sync_out;
    always_ff @ (posedge clk, negedge n_rst) begin
        if (n_rst == 1'b0) sync_out <= 1'b0;
        else sync_out <= async_in;
    end
endmodule
