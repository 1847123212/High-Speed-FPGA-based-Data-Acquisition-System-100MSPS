`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author:Niculescu Vlad
// Module Name:    decoder
//////////////////////////////////////////////////////////////////////////////////

//This module converts a binary offset number in a wo's complement one
module decoder(input [9:0] in, output [9:0] out
    );
MUX_converter mux(.a(in[8:0]), .x(out[8:0]),.sel(in[9]));
assign out[9]=~in[9];

endmodule
