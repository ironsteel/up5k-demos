/*
The virtual NES cartridge
At the moment this stores the entire cartridge
in SPRAM, in the future it could stream data from
SQI flash, which is more than fast enough
*/

module cart_mem(
  input clock,
  input reset,
  
  input reload,
  input [3:0] index,
  
  output cart_ready,
  output reg [31:0] flags_out,
  //address into a given section - 0 is the start of CHR and PRG,
  //region is selected using the select lines for maximum flexibility
  //in partitioning
  input [20:0] address,
  
  input prg_sel, chr_sel,
  input ram_sel, //for cart SRAM (NYI)
  
  input rden, wren,
  
  input  [7:0] write_data,
  output [7:0] read_data,
  
  //Flash load interface
  output flash_csn,
  output flash_sck,
  output flash_mosi,
  input flash_miso,
  // SRAM interface
  output [17:0] ADR,
  inout [15:0] DAT,
  output RAMOE,
  output RAMWE,
  output RAMCS
);

wire [15:0] data_pins_in;
wire [15:0] data_pins_out;
reg data_pins_out_en;
reg [17:0] in_address;
wire [15:0] data_read;
reg [15:0] data_write;
reg read;
reg write;
wire ready;
    
SB_IO #(
	.PIN_TYPE(6'b 1010_01)
) sram_data_pins [15:0] (
        .PACKAGE_PIN(DAT),
        .OUTPUT_ENABLE(data_pins_out_en),
        .D_OUT_0(data_pins_out),
        .D_IN_0(data_pins_in)
);


sram sram_test(
	.clk(clock),
	.address(in_address),
	.data_read(data_read),
	.data_write(data_write),
	.write(write),
	.read(read),
	.reset(reset),
	.ready(ready),

        .data_pins_in(data_pins_in),
        .data_pins_out(data_pins_out),
        .address_pins(ADR),
        .OE(RAMOE), .WE(RAMWE), .CS(RAMCS));

reg load_done;
initial load_done = 1'b0;

reg [31:0] spram_dout_pre;
wire cart_ready = load_done;
// Does the image use CHR RAM instead of ROM? (i.e. UNROM or some MMC1)
wire is_chram = flags_out[15];
// Work out whether we're in the SPRAM, used for the main ROM, or the extra 8k SRAM
wire spram_en = prg_sel | (!is_chram && chr_sel);
wire sram_en = ram_sel | (is_chram && chr_sel);

wire [16:0] decoded_address;
assign decoded_address = chr_sel ? {1'b1, address[15:0]} : address[16:0];

reg [15:0] load_addr;
wire [14:0] spram_address = load_done ? decoded_address[16:2] : load_addr[14:0];

wire load_wren;
wire spram_wren = load_done ? (spram_en && wren) : load_wren;
wire [3:0] spram_mask = load_done ? (4'b0001 << decoded_address[1:0]) : 4'b1111;
wire [3:0] spram_maskwren = spram_wren ? spram_mask : 4'b0000;

wire [31:0] load_write_data;
wire [31:0] spram_write_data = load_done ? {write_data, write_data, write_data, write_data} : load_write_data;

reg [15:0] spram_read_data;

wire [7:0] csram_read_data;
// Demux the 32-bit memory
assign read_data = sram_en ? csram_read_data : 
    (decoded_address[1] ? (decoded_address[0] ? spram_read_data[15:8] : spram_read_data[7:0]) : (decoded_address[0] ? spram_read_data[15:8] : spram_read_data[7:0]));

//assign read_data = data_write[15:8];
 // The SRAM, used either for PROG_SRAM or CHR_SRAM
generic_ram #(
  .WIDTH(8),
  .WORDS(8192)
) sram_i (
  .clock(clock),
  .reset(reset),
  .address(decoded_address[12:0]), 
  .wren(wren&sram_en), 
  .write_data(write_data), 
  .read_data(csram_read_data)
);

wire flashmem_valid = !load_done;
wire flashmem_ready;
assign load_wren =  flashmem_ready && (load_addr != 16'h8000);
wire [23:0] flashmem_addr = (24'h100000 + (index_lat << 18)) | {load_addr, 2'b00};
reg [3:0] index_lat;
reg load_done_pre;


reg [7:0] wait_ctr;
// Flash memory load interface
always @(posedge clock) 
begin
  if (reset == 1'b1) begin
    load_done_pre <= 1'b0;
    load_done <= 1'b0;
    load_addr <= 16'h0000;
    flags_out <= 32'h00000000;
    wait_ctr <= 8'h00;
    index_lat <= 4'h0;
  end else begin
    if (reload == 1'b1) begin
      load_done_pre <= 1'b0;
      load_done <= 1'b0;
      load_addr <= 16'h0000;
      flags_out <= 32'h00000000;
      wait_ctr <= 8'h00;
      index_lat <= index;
    end else begin
      if(!load_done_pre) begin
        if (flashmem_ready == 1'b1) begin
          if (load_addr == 16'h8000) begin
            load_done_pre <= 1'b1;
            flags_out <= load_write_data; //last word is mapper flags
          end else begin
	    load_addr <= load_addr + 1'b1;
          end;
        end
      end else begin
        if (wait_ctr < 8'hFF)
          wait_ctr <= wait_ctr + 1;
        else
          load_done <= 1'b1;
      end
      
    end
  end
end




localparam [4:0]
	test_init = 5'b000,
	rd_clk1   = 5'b001,
	rd_clk2   = 5'b010,
	rd_clk3   = 5'b011,
	wr_clk1   = 5'b100,
	wr_clk2   = 5'b101,
	wr_clk3   = 5'b110,
	wr_clk4   = 5'b111,
	wr_clk5   = 5'b01000,
	wr_clk6   = 5'b01001,
	rd_clk4   = 5'b01010,
	rd_clk5   = 5'b01100,
	rd_clk6   = 5'b01101,
	rd_clk7   = 5'b01110,
	rd_clk8   = 5'b01111,
	rd_clk9   = 5'b10000,
	rd_clk10   = 5'b10001,
	rd_clk11  = 5'b10010,
	rd_clk12  = 5'b10011,
	rd_clk13  = 5'b10100,
	rd_clk14  = 5'b10101,
	rd_clk15  = 5'b10111,
	wr_clk7   = 5'b11001,
	wr_clk8   = 5'b11011;

reg [4:0] state_reg;


always @(posedge clock)
begin
	if (reset) begin
		state_reg <= test_init;
		write <= 0;
		read <= 0;
		in_address <= 0;
		data_write <= 0;
		data_pins_out_en <= 0;
	end else 
		case (state_reg)
			test_init:
			begin
				if (load_wren) begin
					in_address <= {3'b0, spram_address};
					state_reg <= wr_clk1;
					data_write <= load_write_data[15:0];
					data_pins_out_en <= 1;
				end else if (rden && load_done) begin 
					if (decoded_address[1]) begin 
						in_address <= {18'h10000 ^ {3'b0, spram_address}};
					end else begin
						in_address <= {3'b0, spram_address};
					end
					state_reg <= rd_clk1;
				end else if (spram_wren) begin
					if (decoded_address[1]) begin 
						in_address <= {18'h10000 ^ {3'b0, spram_address}};
					end else begin
						in_address <= {3'b0, spram_address};
					end
					data_write <= spram_write_data[15:0];
					data_pins_out_en <= 1;
					state_reg <= wr_clk7;
				end else begin
					state_reg <= test_init;
					read <= 0;
					write <= 0;
					in_address <= 0;
					data_pins_out_en <= 0;
					data_write <= 0;
				end
			end
			wr_clk1:
			begin
				state_reg <= wr_clk2;
				write <= 1;
			end
			wr_clk2:
			begin
				write <= 0;
				state_reg <= wr_clk3;
			end
			wr_clk3:
			begin
				in_address <= {18'h10000 | in_address};
				data_write <= load_write_data[31:16];
				state_reg <= wr_clk4;
			end
			wr_clk4:
			begin
				write <= 1;
				state_reg <= wr_clk5;
			end
			wr_clk5:
			begin
				write <= 0;
				state_reg <= wr_clk6;
			end
			wr_clk6:
			begin
				data_pins_out_en <= 0;
				state_reg <= test_init;
			end
			wr_clk7:
			begin
				write <= 1;
				state_reg <= wr_clk8;
			end
			wr_clk8:
			begin
				write <= 0;
				state_reg <= rd_clk15;
			end
			rd_clk15:
			begin
			        data_pins_out_en <= 0;	
				state_reg <= test_init;
			end
			rd_clk1:
			begin
				read <= 1;
				state_reg <= rd_clk2;
			end
			rd_clk2:
			begin
				spram_read_data[15:0] <= data_read;
				state_reg <= rd_clk3;
			end
			rd_clk3:
			begin
				read <= 0;
				state_reg <= test_init;
			end
			default:
			begin
				write <= 0;
				read <= 0;
				data_write <= 0;
				state_reg <= 0;
			end
	endcase
end

icosoc_flashmem flash_i (
	.clk(clock),
  .reset(reset),
  .valid(flashmem_valid),
  .ready(flashmem_ready),
  .addr(flashmem_addr),
  .rdata(load_write_data),

	.spi_cs(flash_csn),
	.spi_sclk(flash_sck),
	.spi_mosi(flash_mosi),
	.spi_miso(flash_miso)
);

endmodule
