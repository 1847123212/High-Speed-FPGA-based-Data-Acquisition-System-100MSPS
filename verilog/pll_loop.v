`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
//Author:Niculescu Vlad
//Module Name:    pll_loop
//////////////////////////////////////////////////////////////////////////////////
module pll_loop(CLK_IN1, CLK_OUT1, CLK_OUT2, CLK_OUT3, CLK_OUT4
    );

input CLK_IN1;
output CLK_OUT1;
output CLK_OUT2;
output CLK_OUT3;
output CLK_OUT4;

 pll instance_name
   (// Clock in ports
    .CLK_IN1(CLK_IN1),      
    // Clock out ports
    .CLK_OUT1(CLK_OUT1),     
    .CLK_OUT2(CLK_OUT2),
	 .CLK_OUT3(CLK_OUT3),
	 .CLK_OUT4(CLK_OUT4)
	 );   
endmodule
