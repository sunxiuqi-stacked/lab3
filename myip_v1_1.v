/* 
----------------------------------------------------------------------------------
--	(c) Rajesh C Panicker, NUS
--  Description : Matrix Multiplication AXI Stream Coprocessor. Based on the orginal AXIS Coprocessor template (c) Xilinx Inc
-- 	Based on the orginal AXIS coprocessor template (c) Xilinx Inc
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
/*
-------------------------------------------------------------------------------
--
-- Definition of Ports
-- ACLK              : Synchronous clock
-- ARESETN           : System reset, active low
-- S_AXIS_TREADY  : Ready to accept data in
-- S_AXIS_TDATA   :  Data in 
-- S_AXIS_TLAST   : Optional data in qualifier
-- S_AXIS_TVALID  : Data in is valid
-- M_AXIS_TVALID  :  Data out is valid
-- M_AXIS_TDATA   : Data Out
-- M_AXIS_TLAST   : Optional data out qualifier
-- M_AXIS_TREADY  : Connected slave device is ready to accept data out
--
-------------------------------------------------------------------------------
*/

module myip_v1_1 
	(
		// DO NOT EDIT BELOW THIS LINE ////////////////////
		ACLK,
		ARESETN,
		S_AXIS_TREADY,
		S_AXIS_TDATA,
		S_AXIS_TLAST,
		S_AXIS_TVALID,
		M_AXIS_TVALID,
		M_AXIS_TDATA,
		M_AXIS_TLAST,
		M_AXIS_TREADY 
		// DO NOT EDIT ABOVE THIS LINE ////////////////////
	);

input                          ACLK;    // Synchronous clock
input                          ARESETN; // System reset, active low
// slave in interface
output                         S_AXIS_TREADY;  // Ready to accept data in
input      [31 : 0]            S_AXIS_TDATA;   // Data in
input                          S_AXIS_TLAST;   // Optional data in qualifier
input                          S_AXIS_TVALID;  // Data in is valid
// master out interface
output                         M_AXIS_TVALID;  // Data out is valid
output    [31 : 0]            M_AXIS_TDATA;   // Data Out
output                         M_AXIS_TLAST;   // Optional data out qualifier
input                          M_AXIS_TREADY;  // Connected slave device is ready to accept data out

//----------------------------------------
// Implementation Section
//----------------------------------------
// In this section, we povide an example implementation of MODULE myip_v1_0
// that does the following:
//
// 1. Read all inputs
// 2. Add each input to the contents of register 'sum' which
//    acts as an accumulator
// 3. After all the inputs have been read, write out the
//    content of 'sum' into the output stream NUMBER_OF_OUTPUT_WORDS times
//
// You will need to modify this example for
// MODULE myip_v1_0 to implement your coprocessor


// RAM parameters for assignment 1
	localparam A_depth_bits = 9;  	// 2 elements (A is a 1x4 matrix)
	localparam B_depth_bits = 3; 	// 4 elements (B is a 4x1 matrix)
	localparam RES_depth_bits = 6;	// 2 elements (RES is a 2x1 matrix)
	localparam width = 8;			// all 8-bit data
	
// wires (or regs) to connect to RAMs and matrix_multiply_0 for assignment 1
// those which are assigned in an always block of myip_v1_0 shoud be changes to reg.
	reg     A_write_en;								// myip_v1_0 -> A_RAM. To be assigned within myip_v1_0. Possibly reg.
	reg	    [A_depth_bits-1:0] A_write_address;		// myip_v1_0 -> A_RAM. To be assigned within myip_v1_0. Possibly reg. 
	reg    	[width-1:0] A_write_data_in;			// myip_v1_0 -> A_RAM. To be assigned within myip_v1_0. Possibly reg.
	wire	A_read_en;								// matrix_multiply_0 -> A_RAM.
	wire	[A_depth_bits-1:0] A_read_address;		// matrix_multiply_0 -> A_RAM.
	wire	[width-1:0] A_read_data_out;			// A_RAM -> matrix_multiply_0.
	reg    	B_write_en;								// myip_v1_0 -> B_RAM. To be assigned within myip_v1_0. Possibly reg.
	reg    	[B_depth_bits-1:0] B_write_address;		// myip_v1_0 -> B_RAM. To be assigned within myip_v1_0. Possibly reg.
	reg    	[width-1:0] B_write_data_in;			// myip_v1_0 -> B_RAM. To be assigned within myip_v1_0. Possibly reg.
	wire 	B_read_en;								// matrix_multiply_0 -> B_RAM.
	wire 	[B_depth_bits-1:0] B_read_address;		// matrix_multiply_0 -> B_RAM.
	wire	[width-1:0] B_read_data_out;			// B_RAM -> matrix_multiply_0.
	wire 	RES_write_en;							// matrix_multiply_0 -> RES_RAM.
	wire 	[RES_depth_bits-1:0] RES_write_address;	// matrix_multiply_0 -> RES_RAM.
	wire 	[width-1:0] RES_write_data_in;			// matrix_multiply_0 -> RES_RAM.
	reg    	RES_read_en;  							// myip_v1_0 -> RES_RAM. To be assigned within myip_v1_0. Possibly reg.
	reg    	[RES_depth_bits+1:0] RES_read_address;	// myip_v1_0 -> RES_RAM. To be assigned within myip_v1_0. Possibly reg.
	wire    [width-1:0] RES_read_data_out;			// RES_RAM -> myip_v1_0
	
	// wires (or regs) to connect to matrix_multiply for assignment 1
	reg		Start = 0; 								// myip_v1_0 -> matrix_multiply_0. To be assigned within myip_v1_0. Possibly reg.
	wire	Done;								// matrix_multiply_0 -> myip_v1_0. 
			
				
   // Total number of input data.
   localparam NUMBER_OF_INPUT_WORDS  = 520; // 2**A_depth_bits + 2**B_depth_bits = 12 for assignment 1

   // Total number of output data
   localparam NUMBER_OF_OUTPUT_WORDS = 64; // 2**RES_depth_bits = 2 for assignment 1

   // Define the states of state machine (one hot encoding)
    localparam Idle  = 4'b1000;
    localparam Read_Inputs = 4'b0100;
    localparam Compute = 4'b0010;		// currently unused, but needed for assignment 1
    localparam Write_Outputs  = 4'b0001;
	
	localparam Read_output = 3'b100;
	localparam Write_output = 3'b010;
	localparam Idle_output = 3'b001;
	
   reg [3:0] state;
   reg [2:0] output_state;
   reg write_done  = 0;

   // Accumulator to hold sum of inputs read at any point in time
   reg [31:0] sum;
   reg [8:0] RES_size;

   // Counters to store the number inputs read & outputs written
   reg [NUMBER_OF_INPUT_WORDS - 1:0] nr_of_reads;   // to do : change it as necessary
   reg [NUMBER_OF_INPUT_WORDS - 1:0] A_of_reads;   // Number of reads of A
   reg [NUMBER_OF_INPUT_WORDS - 1:0] B_of_reads;   // Number of reads of B
   reg [NUMBER_OF_INPUT_WORDS - 1:0] RES_of_reads;   // Number of reads of RES
   reg [NUMBER_OF_OUTPUT_WORDS - 1:0] nr_of_writes; // to do : change it as necessary

   // CAUTION:
   // The sequence in which data are read in should be
   // consistent with the sequence they are written

   assign S_AXIS_TREADY = (state == Read_Inputs);
   assign M_AXIS_TVALID = (output_state == Write_output);
   assign M_AXIS_TLAST = write_done;

   assign M_AXIS_TDATA = sum;
   

   always @(posedge ACLK) 
   begin

      /****** Synchronous reset (active low) ******/
      if (!ARESETN)
        begin
           // CAUTION: make sure your reset polarity is consistent with the
           // system reset polarity
           RES_size = 1<<(RES_depth_bits);
           state        <= Idle;
           nr_of_reads <= NUMBER_OF_INPUT_WORDS;
           //reset the write addresses for A and B
           A_write_address <= 0;
           B_write_address <= 0;
           RES_read_address <= 0;
           //Reset the number of reads in A and B
           A_of_reads <= 1<<(A_depth_bits);
           B_of_reads <= 1<<(B_depth_bits);
           sum         <= 0;
           //set enable bits for read and write
           A_write_en <= 0;
           B_write_en <= 0;
           RES_read_en <= 1;
           Start <= 0;
        end
      /************** state machine **************/
      else
        case (state)

          Idle:
            if (S_AXIS_TVALID == 1)
            begin
            	nr_of_reads <= NUMBER_OF_INPUT_WORDS;
            	RES_size = 1<<(RES_depth_bits);
            	//reset the write addresses for A and B
            	A_write_address <= 0;
            	B_write_address <= 0;
            	RES_read_address <= 0;
            	//Reset the number of reads in A and B
            	A_of_reads <= 1<<(A_depth_bits);
            	B_of_reads <= 1<<(B_depth_bits);
            	A_write_en <= 0;
                B_write_en <= 0;
                RES_read_en <= 0;
            	sum         <= 0;
            	state       = Read_Inputs;
				output_state = Idle_output;
				write_done <= 0;
            end

          Read_Inputs:
            if (nr_of_reads == 0)
                  state <= Compute;
            else if (S_AXIS_TVALID == 1)
            begin
              // --- Coprocessor function happens below --- //
              // sum  <=  sum + S_AXIS_TDATA;
              // --- Coprocessor function happens above --- //
              if (nr_of_reads == 0)
                begin
                  state <= Compute;
                end
              else
                begin
                    //enable writing to A and B
                    //if(S_AXIS_TREADY == 1)
                    //begin
                    if(S_AXIS_TREADY == 1)
                        begin
                            //end
                            //2 states defined by if else, if Aofreads==0, switch to reading B
                            if(A_of_reads == 0)
                                begin
                                    B_write_en <= 1;
                                    B_write_data_in <= S_AXIS_TDATA[width-1:0];
                                    if(B_of_reads != 1<<(B_depth_bits))     //If first try, remain at 0 until valid data is read
                                        B_write_address <= B_write_address + 1;
                                    B_of_reads <= B_of_reads - 1;
                                end
                            else
                                begin
                                    A_write_en <= 1;
                                    A_write_data_in <= S_AXIS_TDATA[width-1:0];
                                    if(A_of_reads != 1<<(A_depth_bits))     //If first try, remain at 0 until valid data is read
                                        A_write_address <= A_write_address + 1;
                                    A_of_reads <= A_of_reads - 1;
                                end
                            nr_of_reads <= nr_of_reads - 1;
                        end
                end
            end
            
          Compute:
				// If multiplication is done, write to outputs, else begin multiplication by bring start bit high
				if(Start == 0)
					begin
						A_write_en <= 0;
						B_write_en <= 0;
						Start <= 1;
					end
				else if(Done == 1)
					begin
						Start = 0;
						write_done <= 0;
						RES_read_en <= 1;
				    	state <= Write_Outputs;
				    end
				
          Write_Outputs:
          	begin
            // If there are writes left, read datat out, else go back to Idle
            if (M_AXIS_TREADY == 1)
                case (output_state)               	
                	Idle_output:
                		begin
                		RES_read_en <= 1;
                		output_state <= Read_output;
                		end
                	
                	Read_output:
                		begin
                    	sum <= RES_read_data_out;
                    	RES_read_address <= RES_read_address + 1;
                    	output_state <= Write_output;
   						end
   					
   					Write_output:
   						begin
   						if(RES_read_address == RES_size)
   						begin
   							write_done <= 1;
   							output_state <= Idle_output;
   							RES_read_address <= 0;
   						end
   						else
   							begin
   							output_state <= Read_output;
   							end
   						end
                 endcase
			else
				begin
				write_done <= 0;
				state <= Idle;
				end
			end
        endcase
   end
	   
	// Connection to sub-modules / components for assignment 1
	
	memory_RAM 
	#(
		.width(width), 
		.depth_bits(A_depth_bits)
	) A_RAM 
	(
		.clk(ACLK),
		.write_en(A_write_en),
		.write_address(A_write_address),
		.write_data_in(A_write_data_in),
		.read_en(A_read_en),    
		.read_address(A_read_address),
		.read_data_out(A_read_data_out)
	);
										
										
	memory_RAM 
	#(
		.width(width), 
		.depth_bits(B_depth_bits)
	) B_RAM 
	(
		.clk(ACLK),
		.write_en(B_write_en),
		.write_address(B_write_address),
		.write_data_in(B_write_data_in),
		.read_en(B_read_en),    
		.read_address(B_read_address),
		.read_data_out(B_read_data_out)
	);
										
										
	memory_RAM 
	#(
		.width(width), 
		.depth_bits(RES_depth_bits)
	) RES_RAM 
	(
		.clk(ACLK),
		.write_en(RES_write_en),
		.write_address(RES_write_address),
		.write_data_in(RES_write_data_in),
		.read_en(RES_read_en),    
		.read_address(RES_read_address),
		.read_data_out(RES_read_data_out)
	);
										
	matrix_multiply_2
	#(
		.width(width), 
		.A_depth_bits(A_depth_bits), 
		.B_depth_bits(B_depth_bits), 
		.RES_depth_bits(RES_depth_bits) 
	) matrix_multiply_2
	(									
		.clk(ACLK),
		.Start(Start),
		.Done(Done),
		
		.A_read_en(A_read_en),
		.A_read_address(A_read_address),
		.A_read_data_out(A_read_data_out),
		
		.B_read_en(B_read_en),
		.B_read_address(B_read_address),
		.B_read_data_out(B_read_data_out),
		
		.RES_write_en(RES_write_en),
		.RES_write_address(RES_write_address),
		.RES_write_data_in(RES_write_data_in)
	);

endmodule






/*
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
*/