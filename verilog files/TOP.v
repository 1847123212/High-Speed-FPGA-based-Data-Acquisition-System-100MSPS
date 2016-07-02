`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////
//Author:Niculescu Vlad
/*  Short description of the flow
The algorithm below, is able to capture a waveform, with a sampling rate of up to 100MSPS.
It is also able to compute the absolute value of FFT for the captured window. 
Steps:
1. Capture a frame, and store it in ram1 (ram_adc)
2. Load the samples from ram1, into FFT module
3.Compute FFT
4.Unload data from FFT module, and store it into ram2. Because the FFT's output is a complex number, between FFT's
out and ram2, it was introduced a square module(^2 operation), and an adder. In this way, if re and im are the output
of the FFT, at the ram2's input will be re^2+im^2. The only thing to do in order to obtain a aquare rate is the square root.
5.The aquare root module is not a 0 latency module, so it requires eight clock cycles.
6.Data is loaded into and square root module, and then is stored into ram3. From here data is sent to PC(both waveform and FFT)
7.LabView displays the waveforms
8.Another process is started in FPGA, just when it is requested by PC
*/

//////////////////////////////////////////////////////////////

module TOP(input clk_in,             //input clock: provided by the Nexys' 100Mhz onboard oscillator- the input for the pll module
           input [9:0] adc_read,     //parallel data provided by adc
			  input serial_in,			 //serial input(RX)   
			  output adc_pwdn,          //adc power down pin(active HIGH)
			  output clock_adc_out,     //clock signal for the ADC converter
			  output reg [9:0] leds,    //led bar for debugging  
			  output serial_out,        //serial output(TX)
			  output reg [2:0] adj      //adjustments for the analogic circuit(set the amplification/attenuation)
			  		
    );


reg adc_state=1'b1;        //enable pin for ADC
wire dserial_avail;        //data pending on the input of the serial module
wire [7:0] dserial_in;     //serial input buffer
reg en=1'b0;               //serial transmitter enable pin
reg [15:0] aggregated;     //serial transmitter buffer (load data in order to be sent)
reg [10:0] ADR=11'b00000000000;  //write address for the first RAM- which stores samples from adc
wire [10:0] ADR_r;               //read address for the final ram
reg [10:0] cnt=11'b00000000000;  //counter for memory addressing 
reg we=1'b1;                     //write-enable control pin for the first ram
wire [9:0] buffer;               //wire for adc's data bus
reg rx_allowed=1'b1;             //rx flag
reg res_serial;                  //serial module reset pin
wire carry;                      //indicates when the first ram is full
wire start;                      //indicates when a new sample is ready to be sent in transmitter module
wire clk_100;                    //100Mhz clock from pll
wire clk;                        //200Mhz clock from pll-the system clock
wire clk_50;  
wire clk_UART;                   //50Mhz clock from pll
reg start_fft=1'b0;              //start bit for the Fast Fourier Transform module
wire rfd;                        //ready for data- Root Square Module
wire [10:0] index_in;            //FFT module input ram counter
wire [10:0] index_out;           //FFT module output ram counter
wire busy;                       //busy flag for FFT module
wire edone;                      //FFT: indicates when data is ready to be unloaded with a clock before      
wire done;                       //FFT: indicates when data is ready to be unloaded 
wire dv;                         //FFT: flag for data valid
wire [9:0] xk_re;                //output bus from FFT module: real part
wire [9:0] xk_im;                //output bus from FFT module: imaginary part
reg we2;                         //write enable pin for the second ram
reg we3;									//write enable pin for the third ram
wire [20:0] out_fft;             //the processed fft's output: out_fft=xk_re^2+xk_im^2
wire [9:0] data_send;            //the output of the third ram- from here, data is ready to be sent
wire [19:0] in1_s;               //input 1 of the adder
wire [19:0] in2_s;					//input 2 of the adder
wire [20:0] sum;						//the output of the adder
reg sclr;                        //reset pin for square root module
wire sqr_rdy;                    //flag which indicates new data on the root square output
reg [10:0] cnt_s;                //counter for addressing the ram
reg sel;                         //selection bit for a MUX- which changes between two counters- used for memory addressing
wire [10:0] square_out;          //root square module output
wire [10:0] ram_read;            //ram1 read address bus 
reg [10:0] cnt_waveform=11'b00000000000; //index for 
reg sel2;                        //switches between two addresses- ram1 is , at first, read by the FFT module, then by the transmitter module                  
wire [9:0] decoder_out;          //decoder output
reg [7:0] trig_value=8'b1000000000; //trigger level value
reg[7:0]  trig1;                 //buffer 1 for slope evaluation
reg[7:0]  trig2;                 //buffer 2 for slope evaluation
reg slope;           			   //slope indicator
reg slope_adj=1'b1;              //slope_adjustment set pin
reg [3:0] timebase=4'b0000;      //decoder input for clock divider
reg [29:0] trigger_counter;      //counter-waits for trigger a certain period. If it is not found, it goes on.
reg [2:0] conf_index;            //indcator for which adjustment is wanted
reg adc_div_sel=1'b0;            //selection pin for a MUX, which changes the input clock for the adc module  
reg [15:0] divider;              //variable for clock division
wire clock_adc_in;               //input clock for adc module
wire [15:0] out_trans;           //output from a transcoder




//pll module:provides a 200Mhz clock for the system, and other two signals for ADC and FFT
pll_loop clk_mult(   .CLK_IN1(clk_in),      //Nexys board clock
							.CLK_OUT1(clk_100),    //100Mhz clock
							.CLK_OUT2(clk),		  //200Mhz clock
							.CLK_OUT3(clk_50),    //50Mhz clock
							.CLK_OUT4(clk_UART)
							);


//UART receiver block:data from PC is received in FPGA through this block
serial_rx receiver(   .input1(serial_in),     //serial bit
							 .clk(clk_UART),              //clock:by dividing this clock with a certain value, it is obtained the baudrate
							 .d_avail(dserial_avail),//serial pending flag
					       .d_out(dserial_in));    //data byte
								 
//UART transmitter: the data packet is sent to PC via this block						 
serialt transmitter(  .clk(clk_UART),               //clock:by dividing this clock with a certain value, it is obtained the baudrate
							 .en(en), 				     //the module is sending data as long as en is HIGH
							 .status(aggregated), 	  //data to be sent is written here
							 .serial_out(serial_out), //serial bit
							 .flag(flag),             //for debug
							 .start(start),           //signals whenever a new sample has to be load
							 .res(res_serial)       //the serial module sends two bytes(one by one); this pin resets the index
							 ); 
							 
//config	file for ADC : generates the clock, enables the adc, and can set the power down state for adc						 
read_adc adc_conf(   .clk(clock_adc_in),     
						   .adc_enable(adc_state), 
						   .clk_adc(clock_adc_out), 
						   .bites_read(adc_read), 
						   .adc_pwdn(adc_pwdn)
							);
						 
//This memory stores the samples provided by ADC; the ram is read two times every process; first time by the FFT, and second time by serial module						 
SRAM ram_adc(		   .clk(clk), 
							.addr(ADR),         // write address
							.we(we),            //write enable
							.data_in(adc_read), 
							.data_out(buffer), 
							.addr_r(ram_read),  // read address
							.carry(carry));     //signals when memory is full
			
//this ram is the output of the FFT; between this and the output of the FFT are two combinational levels(square and sum)		
SRAM2 ram_fft_20bit(	.clk(clk),          
						   .addr(index_out),  //index_out is automatically incremented when transform is done
						   .addr_r(cnt_s),    
							.data_in(sum),     
						   .data_out(out_fft),
						   .we(we2));        //write_enable
			  
//this ram stores	information about spectral analysis	  
SRAM3 ram_fft_10bit(	.clk(clk),        
						   .addr(cnt_s),
						   .addr_r(ADR_r),
						   .data_in(square_out[9:0]), 
						   .data_out(data_send), 
						   .we(we3));


//Fast Fourier Transform Core: works with signed two's complement numbers									
Fourier FFT(         .clk(clk_100), 
							.start(start_fft),             //signals the start of the transfort
						  	.xn_re(decoder_out),           //real part input
							.xn_im(10'b0000000000),        //imaginary part input
							.fwd_inv(1'b1),                //switch between inverse or forward transform
							.fwd_inv_we(1'b1),
							.scale_sch(12'b001010101011),   //scale number: data is scaled to use less bits
							.scale_sch_we(1'b1),            
							.rfd(rfd),          				  //ready for data							
							.xn_index(index_in),            //for data loading
							.xk_index(index_out),           //for data unloading
							.busy(busy),                    //core is busy
							.edone(edone),                  //done bit(high one clock before)
							.dv(dv), 							  //data valid
							.done(done),                    //transform done
							.xk_re(xk_re),						  //output:real part
							.xk_im(xk_im));					  //output:imaginary part

Square sq_real(      .a(xk_re),                      //in1_s=xk_re^2
							.b(xk_re), 
							.p(in1_s));
					
Square sq_im(        .a(xk_im),                      //in2_s=xk_im^2
						   .b(xk_im),   
						   .p(in2_s)); 
				 
Sum adder(			   .a(in1_s), 
							.b(in2_s), 
							.s(sum));

Root_square  root_square(.x_in(out_fft[19:0]),           
							.x_out(square_out),
							.rdy(sqr_rdy),                 //HIGH when data is outputed
							.clk(clk), 
							.sclr(sclr));                  //reset

MUX      mux_ram3(   .a(cnt),                       //switches the read address for ram3
							.b(cnt_s), 
							.sel(sel), 
							.out(ADR_r));

MUX      mux_ram1(   .a(index_in),                  //switches the read address for ram1
							.b(cnt_waveform), 
							.sel(sel2), 
							.out(ram_read));
							
decoder dec(         .in(buffer),                   //converts the binary offset representation to two's complement, in order to feed the FFT's input
							.out(decoder_out));



ADC_clock_mux ADC_mux(.clk_200(clk),               //selects the input clock for ADC
							 .clk_50(clk_50),  
							 .sel(adc_div_sel),
							 .clk_adc_out(clock_adc_in));

Transcoder  t1(        .in(timebase),               //selects division rates up to 65000, using a input of 4 bites
							 .out(out_trans));

parameter   init_state = 5'b00000, 
            wait_state = 5'b10001,
				acq_state =  5'b00010,
				send_state = 5'b00011, 
				final_state = 5'b00100,
				fft_state = 5'b00101,
				fft_write_state = 5'b00110,
				square_state = 5'b00111,
				square_state2 = 5'b01000,
				square_state3 = 5'b01001,
				square_state4 = 5'b01010,
				square_state5 = 5'b01011,
				send_state2 = 5'b01100,
				send_state3 = 5'b01101,
				trig_state = 5'b10010;
			

parameter   s1 = 2'b00, 
            s2 = 2'b01,
				s3 = 2'b10,
				s4 = 2'b11;
				
parameter   s3_1 = 2'b00, 
            s3_2 = 2'b01,
				s3_3 = 2'b10,
				s3_4 = 2'b11;

reg [1:0] state2=2'b00;
reg [4:0] state=5'b00000;
reg [1:0] state3=2'b00;



//The State Machine
always @(posedge clk ) begin   
 
case(state)
//is executed just one time, when the program is loaded
init_state: begin
			   trig_value<=8'b10000000;
				slope_adj<=1'b0;
				state<=wait_state;
				conf_index<=0;
				adj<=3'b100;
				adc_div_sel<=2'b00; 
				timebase<=4'b0000; 
				adc_div_sel<=1'b1;
				adc_state<=1'b1;
			   end
				
//The process is triggered by the receving of one character on the serial port. If "P" is received, the acquisition starts
//if A,B,C or D is received, the machine sets adjustments for trigger level, slope, time base, gain;
//if the current value is A,B,C or D, the machine expects to receive an adjustment value, according to the previous character			
wait_state: begin 
            if(timebase==4'b0000) adc_div_sel<=1'b1;
				else adc_div_sel<=1'b0;
				trigger_counter<=0;
				sel2<=1'b1;
				sclr<=1'b1;
				we3<=1'b0;
				sel<=1'b0;
				en<=1'b0;
				res_serial<=1'b1;
		
				if (dserial_avail && rx_allowed) 
					 begin
					 if(dserial_in == 8'b01010000) state<=trig_state;  //P
					 else if(dserial_in == 8'b01000001) conf_index<=3'b001;  //A
							else if(dserial_in == 8'b01000010) conf_index<=3'b010;  //B
							  else if(dserial_in ==8'b01000011) conf_index<=3'b011;  //C
							     else if(dserial_in == 8'b01000100) conf_index<=3'b100; //D
										else  begin case(conf_index) 
														 3'b001:  begin //A
																	 timebase<=dserial_in[5:2];     
																	 conf_index<=3'b000;
																	 end
																	 
														 3'b010:  begin  //B
																	 trig_value<=dserial_in;
																	 conf_index<=3'b000;
																	 end
																	 
												       3'b011:  begin  //C
																	 conf_index<=3'b000;
																	 if(dserial_in==8'b01001100) slope_adj<=1'b0;
																	 else if(dserial_in==8'b01001000) slope_adj<=1'b1;
																 	 end
																	 
													    3'b100: begin  //D
															      conf_index<=3'b000;
															      adj<=dserial_in[2:0]; 
															      end
										
									              	endcase
										      end
										
					
					 end
			end
			
//evaluate the difference of the two consecutive samples in order to calculate the slope; When the signal equals a certain value
//on the preffered slope, the acquisition process is started. If the trigger is not found, the system waits a time and starts
//the acquisition anyway		
trig_state: begin
			   if(adc_read[9:2]==trig_value) begin
								                  if(slope==slope_adj) state<=acq_state;
											      	end
				else begin if(trigger_counter==30'b000000000111111111111111111111) begin
																					                trigger_counter<=0;
																					                state<=acq_state;
																				                 	 end
								else trigger_counter<=trigger_counter+1;
					  end
						
			   end
				
//Fill the ram1, until it becomes full			  
acq_state:  begin
			   if(carry==1) begin state<=fft_state;
										 we=1'b0;
									    res_serial<=1'b0;
								 end
			   else we=1'b1;
				end

//starts the FFT core
fft_state: begin
			  we2<=1'b1;
			  start_fft<=1'b1;
			  if(edone==1'b1) state<=fft_write_state;
			  end
			  
//unload the FFT core in ram2
fft_write_state: begin
					  start_fft<=1'b0;
					  if(index_out==10'b1111111110) begin we2<=1'b0;
																	  we3<=1'b1;
																	  state<=square_state;
																	  sclr<=1'b0;
																	  cnt_s<=11'b00000000000;
															   end
					  end
//square_state1, square_state2, square_state3, square_state4 and square_state5 are implemented for root square computation
//During all of these states, a sample is computed.When a sample is outputed, the sqr_rdy bit goes HIGH. This has to be manually reseted
square_state: begin
				  if(cnt_s<11'b1111111111)
						  begin
						  if(sqr_rdy==1'b1) state<=square_state2;	 
							end
							else begin
								  state<=send_state;
								  res_serial<=1'b0;
								  sel<=1'b1;
								  we3<=1'b0;
								  sclr<=1'b1;
								  end
						   
					end

square_state2: begin
					state<=square_state3;
					end

square_state3: begin
					sclr<=1'b1;
				   we3<=1'b0;	
					state<=square_state4;
					end
					
square_state4: begin
					cnt_s<=cnt_s+1;
					state<=square_state5;
					end
					
square_state5: begin
				   sclr<=1'b0;
					we3<=1'b1;
					state<=square_state;
					end
					
//send the samples for FFT
send_state: begin 
				en<=1'b1;
				if(ADR_r==11'b00001111111) state<=final_state;
				end

final_state: begin 
				 if(ADR_r==11'b11111111111) begin state<=send_state2;
															 sel2<=1'b0;
													 end
				 end
//send the samples for waveform
send_state2:begin
				if(ram_read==11'b00011111111) state<=send_state3;
				end

send_state3:begin
				if(ram_read==11'b11111111111) state<=wait_state;	
				end
endcase	
end

//The following block commands the serial transmitter; whenever start goes high, a new sample can be loaded
always @(posedge start ) begin
                         if(state==send_state) 
								 begin
						       state3<=s3_1;		 
								 cnt<=cnt+1;
								 aggregated[9:0]<=data_send;
								 aggregated[15:10]<=6'b000000;
                         end
                         else if(state==final_state) begin
																	  state3<=s3_1;		 
																	  cnt<=cnt+1;
																	  aggregated[9:0]<=data_send;
																	  aggregated[15:10]<=6'b000000;
                                                     end
										else begin
										     case(state3)
													 s3_1:begin
														   aggregated[7:0]<=8'b01000110;
														   aggregated[15:8]<=8'b00000000;
														   state3<=s3_2;
														   end
														  
													 s3_2:begin
														   aggregated[7:0]<=8'b01000110;
														   aggregated[15:8]<=8'b00000000;
														   state3<=s3_3;
														   end
															
													 s3_3:begin
														   aggregated[7:0]<=8'b01010100;
														   aggregated[15:8]<=8'b00000000;
														   state3<=s3_4;
														   end
															
													 s3_4:begin
														   cnt_waveform<=cnt_waveform+1;
														   aggregated[9:0]<=buffer;
														   aggregated[15:10]<=6'b000000;
														   end
										        endcase	      
                                    end	
          end


//This state machine is just for storing data from adc and for slope computation
always @(posedge clock_adc_out) 
							begin 
							case(state2)
								  s1: begin 
										trig1<=adc_read[9:2];
										ADR <=11'b00000000000;
										divider<=0;
									   if(state==acq_state) begin
															      state2<=s2;
																	end
									   else state2<=s3; 
									   end

								   s2: begin
									    if(state!=acq_state) state2<=s1;
									    else if(out_trans==16'b0000000000000000) ADR <= ADR + 1'b1;
											   else  if (divider==out_trans) begin 
																					   ADR <= ADR + 1'b1;
																						divider<=0;
																						end
												   	 else divider<=divider+1;
									    end
										 
							   	s3: begin
									    state2<=s4;
									    trig2<=adc_read[9:2];
									    end
										 
								   s4: begin
									    state2<=s1;
									    if(trig2>trig1) slope<=1'b1;
									    else slope<=1'b0;
									    end
								 endcase	
                         end

//the state indicator
//just for debugging

always @(state) 
begin
case(state)
wait_state :    begin
					 leds[0]<=1'b1;
					 leds[1]<=1'b0;
					 leds[2]<=1'b0;
					 leds[3]<=1'b0;
					 leds[4]<=1'b0;
					 leds[5]<=1'b0;
					 leds[6]<=1'b0;
					 leds[7]<=1'b0;
					 leds[8]<=1'b0;
					 leds[9]<=1'b0;
					 end
	 
trig_state :    begin
			       leds[0]<=1'b0;
		    	    leds[1]<=1'b1;
				    leds[2]<=1'b0;
					 leds[3]<=1'b0;
					 leds[4]<=1'b0;
					 leds[5]<=1'b0;
					 leds[6]<=1'b0;
					 leds[7]<=1'b0;
					 leds[8]<=1'b0;
					 leds[9]<=1'b0;
  				    end
					 
acq_state :     begin
                leds[0]<=1'b0;
		       	 leds[1]<=1'b0;
                leds[2]<=1'b1;
					 leds[3]<=1'b0;
					 leds[4]<=1'b0;
					 leds[5]<=1'b0;
					 leds[6]<=1'b0;
					 leds[7]<=1'b0;
					 leds[8]<=1'b0;
					 leds[9]<=1'b0;
					 end
					 
send_state :    begin
					 leds[0]<=1'b0;
		       	 leds[1]<=1'b0;
                leds[2]<=1'b0;
					 leds[3]<=1'b1;
					 leds[4]<=1'b0;
					 leds[5]<=1'b0;
					 leds[6]<=1'b0;
					 leds[7]<=1'b0;
					 leds[8]<=1'b0;
					 leds[9]<=1'b0;
				    end
					 
final_state:    begin 
		          leds[0]<=1'b0;
		       	 leds[1]<=1'b0;
                leds[2]<=1'b0;
					 leds[3]<=1'b0;
					 leds[4]<=1'b1;
					 leds[5]<=1'b0;
					 leds[6]<=1'b0;
					 leds[7]<=1'b0;
					 leds[8]<=1'b0;
					 leds[9]<=1'b0;
			       end

init_state:     begin 
		          leds[0]<=1'b0;
		       	 leds[1]<=1'b0;
                leds[2]<=1'b0;
					 leds[3]<=1'b0;
					 leds[4]<=1'b0;
					 leds[5]<=1'b1;
					 leds[6]<=1'b0;
					 leds[7]<=1'b0;
					 leds[8]<=1'b0;
					 leds[9]<=1'b0;
					 end				 
endcase
end
endmodule

 

