`timescale 1ns / 1ns

//////////////////////////////////////////////////////////////////////////////////
// Author:Niculescu Vlad
// Module Name:    Sum 
//////////////////////////////////////////////////////////////////////////////////

module Sum(a,b,s
    );
input  [19 : 0] a;
input  [19 : 0] b;
output [20 : 0] s;
adder your_instance_name (
  .a(a), // input [19 : 0] a
  .b(b), // input [19 : 0] b
  .s(s) // output [20 : 0] s
);
endmodule
