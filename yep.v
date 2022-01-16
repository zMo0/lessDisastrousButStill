//
// This is the template for Part 2 of Lab 7.
//
// Paul Chow
// November 2021
//

module part2(iResetn,iPlotBox,iBlack,iColour,iLoadX,iXY_Coord,iClock,oX,oY,oColour,oPlot);
   parameter X_SCREEN_PIXELS = 8'd160;
   parameter Y_SCREEN_PIXELS = 7'd120;
   
   input wire iResetn, iPlotBox, iBlack, iLoadX;
   input wire [2:0] iColour;
   input wire [6:0] iXY_Coord;
   input wire 	    iClock;
   output wire [7:0] oX;         // VGA pixel coordinates
   output wire [6:0] oY;
   
   output wire [2:0] oColour;     // VGA pixel colour (0-7)
   output wire 	     oPlot;       // Pixel draw enable

   //
   // Your code goes here
   //
   wire incx, incy, loadx, loady, loadcolour, RE, resetx;
	control c0 (iClock, iResetn, iPlotBox, iBlack, iLoadX, incx, incy,loadx, loady, loadcolour, RE, resetx);
	datapath d0 (iClock, iResetn, incx, incy, loadx, loady, loadcolour, iXY_Coord, iColour, RE, oX, oY, oColour, oPlot, resetx);
endmodule // part2

module control(clk, resetn, plot, black, ldx, incx, incy, loadx, loady, loadcolour, RE, resetx);
	input clk, resetn, plot, black, ldx;
	output reg RE;
	reg [1:0] countX = 2'b01;
	reg [1:0] countY = 2'b00;
	
	output reg loadx, loady, loadcolour, incx, incy, resetx;
	reg [3:0] current_state, next_state; 
	localparam		S_LOAD_X 			= 3'd0,
						S_LOAD_X_WAIT		= 3'd1,
						S_PLOT				= 3'd2,
						S_PLOT_WAIT			= 3'd3,
						S_DRAW_X				= 3'd4,
						S_INC_Y				= 3'd5,
						S_BLACK				= 3'd6,
						S_BLACK_INC_Y		= 3'd7;
	
	always@(posedge clk)begin
		if (incx) begin
			countX = countX + 1;
		end
		if (incy) begin
			countY = countY + 1;
			countX = 2'b0;
			resetx = 1'b0;
		end
		if (current_state == S_LOAD_X) begin
			countX = 2'b00;
			countY = 2'b00;
		end
	end
	always@(*)
    begin: state_table 
            case (current_state)
					S_LOAD_X: begin
							if (black)
								next_state = S_BLACK;
							else if (ldx)
								next_state = S_LOAD_X;
							else
								next_state = S_LOAD_X_WAIT;
						end
					S_LOAD_X_WAIT: next_state = plot ? S_PLOT: S_LOAD_X_WAIT;
					S_PLOT: next_state = S_PLOT_WAIT;
					S_PLOT_WAIT: next_state = plot ? S_PLOT_WAIT : S_DRAW_X;
					S_DRAW_X: begin
						if(countY == 2'b11 && countX == 2'b11)begin 
							next_state = S_LOAD_X;
						end
						else if (countX == 2'b10)begin
							next_state = S_INC_Y;
						end
						else
							next_state = S_DRAW_X;
					end
					S_INC_Y: begin
					if(countY == 2'b11 && countX == 2'b11)begin 
							next_state = S_LOAD_X;
					end
					else
						next_state = S_DRAW_X;
					end
					S_BLACK: begin
//						if (x == X_SCREEN_PIXELS-1 & y == Y_SCREEN_PIXELS-1)
//							next_state = S_LOAD_X;
//						else if (x == x == X_SCREEN_PIXELS-1)
//							next_state = S_BLACK_INC_Y;
//						else
//							next_state = S_BLACK;
					end
					S_BLACK_INC_Y:
						next_state = S_BLACK;
				endcase 
	end
	
	always @(*)
    begin: enable_signals
        // By default make all our signals 0
		  loadx = 1'b0;
		  loady = 1'b0;
		  RE = 1'b1;
		  incx = 1'b0;
		  incy = 1'b0;
		  
		  case(current_state) 
			S_LOAD_X:begin
				loadx = 1'b1;
				incx = 1'b0;
				incy = 1'b0;
				RE = 1'b0;
				end
			S_LOAD_X_WAIT:begin
				loadx = 1'b0;
				end
			S_PLOT: begin
				loady = 1'b1;
				loadcolour = 1'b1;
				incx = 1'b0;
				incy = 1'b0;
				end
			S_PLOT_WAIT:begin
				loady = 1'b0;
				loadcolour = 1'b0;
			end
			S_DRAW_X:begin
				loady = 1'b0;
				loadx = 1'b0; 
				loadcolour = 1'b0;
				RE =1'b1;
				incx = 1'b1;
				incy = 1'b0;
			end
			S_INC_Y: begin
				loady = 1'b0;
				loadx = 1'b0; 
				RE = 1'b1;
				incy = 1'b1;
				incx = 1'b0;
			end
			S_BLACK:begin
				loadx = 0;
				RE = 1'b1;
			end
			S_BLACK_INC_Y:begin
				RE = 1'b0;
			end
		endcase
	end
	
	//current state register
	always @ (posedge clk) begin:state_FFs
		if (!resetn)
			current_state <= S_LOAD_X;
		else
			current_state <= next_state;
	end
	

endmodule

module datapath(clk, resetn, incx, incy, loadx, loady, loadcolour, iXY_Coord, icolour, RE,x, y, colour, plot, resetx);
	input clk;
	input resetn, resetx;
	input loadx, loady, loadcolour, RE, incx, incy;
	input[6:0] iXY_Coord;
	input [2:0] icolour;
	output reg [7:0] x;
	output reg [6:0] y;
	output reg [2:0] colour;
	output reg plot;
	reg [7:0] ini_x;
	reg [6:0] ini_y;
	reg dfy = 1'b1;
	
	always@(posedge clk) begin
		if (!resetn) begin
			x <= 8'b0;
			y <= 8'b0;
			colour <= 3'b0;
		end
		else begin
				if (loadx)begin
					x <= {1'b0, iXY_Coord};
					ini_x  = {1'b0, iXY_Coord};
				end
				if (loady) begin
					ini_y <= iXY_Coord;
					//y <= iXY_Coord;
				end
				if (loadcolour)
					colour <= icolour;
				if (incx)
					x <= x + 1;
					if (dfy) begin
						y <= ini_y;
						dfy = 1'b0;
					end
						
				if(incy) begin
					y <= y + 1;
					x <= ini_x;
				end
   			//if (resetx)
					//x <= ini_x;
					//plot <= 1'b1;
				if (RE)
					plot <= 1'b1;
				if (!RE)
					plot <= 1'b0;
			end
	end
endmodule

