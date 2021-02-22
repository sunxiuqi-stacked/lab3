`timescale 0.001ns / 1ps

/* 
----------------------------------------------------------------------------------
--	(c) Rajesh C Panicker, NUS
--  Description : Template for the Matrix Multiply unit for the AXI Stream Coprocessor
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post a modified version of this on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of any entity.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course EE4218 at the National University of Singapore);
--		(vi) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------
*/

// those outputs which are assigned in an always block of matrix_multiply shoud be changes to reg (such as output reg Done).

module matrix_multiply_2
	#(	parameter width = 8, 			// width is the number of bits per location
		parameter A_depth_bits = 9, 	// depth is the number of locations (2^number of address bits)
		parameter B_depth_bits = 3, 
		parameter RES_depth_bits = 6
	) 
	(
		input clk,										
		input Start,									// myip_v1_0 -> matrix_multiply_0.
		output reg Done = 0,									// matrix_multiply_0 -> myip_v1_0. Possibly reg.
		
		output reg A_read_en = 0,  								// matrix_multiply_0 -> A_RAM. Possibly reg.
		output reg [A_depth_bits-1:0] A_read_address, 		// matrix_multiply_0 -> A_RAM. Possibly reg.
		input [width-1:0] A_read_data_out,				// A_RAM -> matrix_multiply_0.
		
		output reg B_read_en = 0, 								// matrix_multiply_0 -> B_RAM. Possibly reg.
		output reg [B_depth_bits-1:0] B_read_address, 		// matrix_multiply_0 -> B_RAM. Possibly reg.
		input [width-1:0] B_read_data_out,				// B_RAM -> matrix_multiply_0.
		
		output reg RES_write_en, 							// matrix_multiply_0 -> RES_RAM. Possibly reg.
		output reg [RES_depth_bits-1:0] RES_write_address, 	// matrix_multiply_0 -> RES_RAM. Possibly reg.
		output reg [width-1:0] RES_write_data_in 			// matrix_multiply_0 -> RES_RAM. Possibly reg.
	);
	
	// implement the logic to read A_RAM, read B_RAM, do the multiplication and write the results to RES_RAM
	// Note: A_RAM and B_RAM are to be read synchronously. Read the wiki for more details.
localparam RESET = 6'b100000;
localparam IDLE = 6'b010000;
localparam READ_A = 6'b001000;
localparam READ_B = 6'b000100;
localparam MULTIPLY = 6'b000010;
localparam WRITE_RESULT = 6'b000001;

reg [15:0] total = 0;
reg [7:0] state = RESET;
reg [7:0] A, B;

always@(negedge clk)
begin
	case (state)
		
		RESET:
			begin
			A_read_address <= 0;
			B_read_address <= 0;
			RES_write_en <= 0;
			RES_write_address <= 0;
			RES_write_data_in <= 0;
			Done <= 0;
			state <= IDLE;
			end
		IDLE:
			begin
			if(Start)
				begin
				A_read_en <= 1;
				state <= READ_A;
				end
			end
		READ_A:
			begin
			A_read_en <= 0;
			A = A_read_data_out;
			A_read_address <= A_read_address + 1;
			B_read_en <= 1;
			state <= READ_B;
			end
		READ_B:
			begin
			B_read_en <= 0;
			B = B_read_data_out;
			B_read_address <= B_read_address + 1;
			state <= MULTIPLY;
			end
		MULTIPLY:
			begin
			if(B_read_address == 0)
				begin
				state <= WRITE_RESULT;
				total = total + (A*B);
				A_read_en <= 0;
				end
			else
				begin
				total = total + (A*B);
				A_read_en <= 1;
				B_read_en <= 0;
				state <= READ_A;
				end
			end
		WRITE_RESULT:
			begin
				if(~RES_write_en)
					begin
					RES_write_en <= 1;
					RES_write_data_in = total>>8;
					A_read_en <= 0;
					end
				else
					begin
					if(A_read_address == 0)
						begin
						Done <= 1;
						total <= 0;
						RES_write_en <= 0;
						state <= RESET;
						end
					else
						begin
						RES_write_address <= RES_write_address + 1;
						total <= 0;
						A_read_en <= 1;
						RES_write_en <= 0;
						state <= READ_A;
						end
					end
			end
	endcase
end
endmodule