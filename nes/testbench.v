// #### This file is auto-generated from icosoc.py. Do not edit! ####

// ++ 10-header ++

//`timescale 1 ns/ 1 ps 
module testbench;

    wire CLKIN;
    reg clk = 1;
    reg clk2 = 1;
    always #1 clk2 = ~clk2;
    always #4 clk = ~clk;
    assign CLKIN = clk;

    reg reload = 0;
    reg sys_reset = 0;
   wire SPI_FLASH_CS ;
   wire SPI_FLASH_MISO;
   wire SPI_FLASH_MOSI;
   wire SPI_FLASH_SCLK;
   
 NES_ice40  nes(  
	  .clock(clk),
	  .clock2x(clk2),
	  .sys_reset(sys_reset),
	  .reload(reload),
	  // flashmem
	  .flash_sck(SPI_FLASH_SCLK),
	  .flash_csn(SPI_FLASH_CS),
	  .flash_mosi(SPI_FLASH_MOSI),
	  .flash_miso(SPI_FLASH_MISO)
  );

    sim_spiflash spiflash (
        .SPI_FLASH_CS(SPI_FLASH_CS),
        .SPI_FLASH_MOSI(SPI_FLASH_MOSI),
        .SPI_FLASH_MISO(SPI_FLASH_MISO),
        .SPI_FLASH_SCLK(SPI_FLASH_SCLK)
    );

// ++ 90-footer ++



    event appimage_ready;

    initial begin
        @(appimage_ready);

        if ($test$plusargs("vcd")) begin
            $dumpfile("testbench.vcd");
            $dumpvars(0, testbench);
        end

    end

    initial begin
        @(appimage_ready);

	repeat (2) @(posedge clk) begin
		reload <= !reload;
		sys_reset <= !sys_reset;
	end
        repeat (1000000000) @(posedge clk);
        $display("-- CPU Trapped --");
        $finish;
    end

    initial begin:appimgage_init
        reg [7:0] appimage [0:2*1024*1024-1];
        integer i;

        $display("-- Loading appimage --");

        $readmemh("games.hex", appimage);

	for (i = 1*1024*1024; i < 2*1024*1024; i=i+1) begin
	    spiflash.memory[i] = appimage[i];
	end


        -> appimage_ready;
    end
endmodule

