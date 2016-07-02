`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
// Author:Niculescu Vlad
// Module Name:    Fourier 
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
module Fourier(clk, start, xn_re, xn_im, fwd_inv, fwd_inv_we, scale_sch, scale_sch_we, rfd, xn_index, busy, edone, done, dv, xk_index, 
				   xk_re, xk_im
    );

input clk;
input start;
input [9:0] xn_re;
input [9:0] xn_im;
input fwd_inv;
input fwd_inv_we;
input [11:0] scale_sch;
input scale_sch_we;
output rfd;
output [10 : 0] xn_index;
output busy;
output edone;
output done;
output dv;
output [10 : 0] xk_index;
output [9 : 0] xk_re;
output [9 : 0] xk_im;



fft your_instance_name (
  .clk(clk), // input clk
  .start(start), // input start
  .xn_re(xn_re), // input [9 : 0] xn_re
  .xn_im(xn_im), // input [9 : 0] xn_im
  .fwd_inv(fwd_inv), // input fwd_inv
  .fwd_inv_we(fwd_inv_we), // input fwd_inv_we
  .scale_sch(scale_sch), // input [11 : 0] scale_sch
  .scale_sch_we(scale_sch_we), // input scale_sch_we
  .rfd(rfd), // output rfd
  .xn_index(xn_index), // output [10 : 0] xn_index
  .busy(busy), // output busy
  .edone(edone), // output edone
  .done(done), // output done
  .dv(dv), // output dv
  .xk_index(xk_index), // output [10 : 0] xk_index
  .xk_re(xk_re), // output [9 : 0] xk_re
  .xk_im(xk_im) // output [9 : 0] xk_im
);
endmodule
