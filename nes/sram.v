`default_nettype none
module sram (
    input wire reset,
    // 50ns max for data read/write. at 12MHz, each clock cycle is 83ns, so write in 1 cycle
	input wire clk,
    input wire write,
    input wire read,
    input wire [15:0] data_write,       // the data to write
    output wire [15:0] data_read,       // the data that's been read
    input wire [17:0] address,          // address to write to
    output wire ready,                  // high when ready for next operation

    // SRAM pins
    output wire [17:0] address_pins,    // address pins of the SRAM
    input  wire [15:0] data_pins_in,
    output wire [15:0] data_pins_out,
    output wire OE,                     // output enable - low to enable
    output wire WE,                     // write enable - low to enable
    output wire CS                      // chip select - low to enable
);


    assign address_pins = address;
    assign data_pins_out = data_write;
    assign data_read = data_pins_in;
    assign OE = (read == 1) ? 0 : 1;
    assign WE = (write == 1) ? 0 : 1;
    //assign CS = (read == 1 || write == 1) ? 0 : 1;
    assign CS = 0;

    assign ready = 0; 

endmodule
