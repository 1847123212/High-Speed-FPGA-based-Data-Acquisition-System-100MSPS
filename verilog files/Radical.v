`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Author:Niculescu Vlad
// Module Name:    Root_square 
//////////////////////////////////////////////////////////////////////////////////
module Root_square(x_in, x_out, rdy, clk, sclr
    );
	 
 input [19 : 0] x_in;
 output [10 : 0] x_out;
 output rdy;
 input clk;
 input sclr;


Root your_instance_name (
  .x_in(x_in), // input [19 : 0] x_in
  .x_out(x_out), // output [10 : 0] x_out
  .rdy(rdy), // output rdy
  .clk(clk), // input clk
  .sclr(sclr) // input sclr
);
endmodule
