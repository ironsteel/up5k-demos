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
   
    wire SRAM_A0;
    wire SRAM_A1;
    wire SRAM_A2;
    wire SRAM_A3;
    wire SRAM_A4;
    wire SRAM_A5;
    wire SRAM_A6;
    wire SRAM_A7;
    wire SRAM_A8;
    wire SRAM_A9;
    wire SRAM_A10;
    wire SRAM_A11;
    wire SRAM_A12;
    wire SRAM_A13;
    wire SRAM_A14;
    wire SRAM_A15;
    wire SRAM_A16;
    wire SRAM_A17;

    wire SRAM_D0;
    wire SRAM_D1;
    wire SRAM_D2;
    wire SRAM_D3;
    wire SRAM_D4;
    wire SRAM_D5;
    wire SRAM_D6;
    wire SRAM_D7;
    wire SRAM_D8;
    wire SRAM_D9;
    wire SRAM_D10;
    wire SRAM_D11;
    wire SRAM_D12;
    wire SRAM_D13;
    wire SRAM_D14;
    wire SRAM_D15;

    wire SRAM_CE;
    wire SRAM_OE;
    wire SRAM_WE;

    sim_sram sram (
        .SRAM_A0(SRAM_A0),
        .SRAM_A1(SRAM_A1),
        .SRAM_A2(SRAM_A2),
        .SRAM_A3(SRAM_A3),
        .SRAM_A4(SRAM_A4),
        .SRAM_A5(SRAM_A5),
        .SRAM_A6(SRAM_A6),
        .SRAM_A7(SRAM_A7),
        .SRAM_A8(SRAM_A8),
        .SRAM_A9(SRAM_A9),
        .SRAM_A10(SRAM_A10),
        .SRAM_A11(SRAM_A11),
        .SRAM_A12(SRAM_A12),
        .SRAM_A13(SRAM_A13),
        .SRAM_A14(SRAM_A14),
        .SRAM_A15(SRAM_A15),
        .SRAM_A16(SRAM_A16),
        .SRAM_A17(SRAM_A17),
        .SRAM_CE(SRAM_CE),
        .SRAM_D0(SRAM_D0),
        .SRAM_D1(SRAM_D1),
        .SRAM_D10(SRAM_D10),
        .SRAM_D11(SRAM_D11),
        .SRAM_D12(SRAM_D12),
        .SRAM_D13(SRAM_D13),
        .SRAM_D14(SRAM_D14),
        .SRAM_D15(SRAM_D15),
        .SRAM_D2(SRAM_D2),
        .SRAM_D3(SRAM_D3),
        .SRAM_D4(SRAM_D4),
        .SRAM_D5(SRAM_D5),
        .SRAM_D6(SRAM_D6),
        .SRAM_D7(SRAM_D7),
        .SRAM_D8(SRAM_D8),
        .SRAM_D9(SRAM_D9),
        .SRAM_OE(SRAM_OE),
        .SRAM_WE(SRAM_WE),
	.SRAM_LB(0),
	.SRAM_UB(0)
    );

 NES_ice40  nes(  
	  .clock(clk),
	  .clock2x(clk2),
	  .sys_reset(sys_reset),
	  .reload(reload),
	  // flashmem
	  .flash_sck(SPI_FLASH_SCLK),
	  .flash_csn(SPI_FLASH_CS),
	  .flash_mosi(SPI_FLASH_MOSI),
	  .flash_miso(SPI_FLASH_MISO),
	   // SRAM
	   .ADR({SRAM_A17, SRAM_A16, SRAM_A15, SRAM_A14, SRAM_A13, SRAM_A12, SRAM_A11, SRAM_A10, SRAM_A9, SRAM_A8,
			SRAM_A7, SRAM_A6, SRAM_A5, SRAM_A4, SRAM_A3, SRAM_A2, SRAM_A1, SRAM_A0}),
	    .DAT({SRAM_D15, SRAM_D14, SRAM_D13, SRAM_D12, SRAM_D11, SRAM_D10, SRAM_D9, SRAM_D8,
			SRAM_D7, SRAM_D6, SRAM_D5, SRAM_D4, SRAM_D3, SRAM_D2, SRAM_D1, SRAM_D0}),
           .RAMOE(SRAM_OE),
           .RAMWE(SRAM_WE),
	   .RAMCS(SRAM_CE)
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

