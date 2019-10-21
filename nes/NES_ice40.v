// Copyright (c) 2012-2013 Ludvig Strigeus
// Copyright (c) 2017 David Shah
// This program is GPL Licensed. See COPYING for the full license.

`timescale 1ns / 1ps

module NES_ice40 (  
	// clock input
  input clock,
  input clock2x,
  input reload,
  input sys_reset,
  output LED0, LED1,
  
  // VGA
  output         VGA_HS, // VGA H_SYNC
  output         VGA_VS, // VGA V_SYNC
  output [ 3:0]  VGA_R, // VGA Red[3:0]
  output [ 3:0]  VGA_G, // VGA Green[3:0]
  output [ 3:0]  VGA_B, // VGA Blue[3:0]
                                                                                                    

  // audio
  output           AUDIO_O,
  
  // joystick
  output joy_strobe, joy_clock,
  input joy_data,
  
  // flashmem
  output flash_sck,
  output flash_csn,
  output flash_mosi,
  input flash_miso
);


  wire scandoubler_disable;

  reg clock_locked;
  wire locked_pre;
  always @(posedge clock)
    clock_locked <= locked_pre;
  
	wire sys_rest = !clock_locked;
  wire [8:0] cycle;
  wire [8:0] scanline;
  wire [15:0] sample;
  wire [5:0] color;
  
  wire load_done;
  wire [21:0] memory_addr;
  wire memory_read_cpu, memory_read_ppu;
  wire memory_write;
  wire [7:0] memory_din_cpu, memory_din_ppu;
  wire [7:0] memory_dout;
  
  wire [31:0] mapper_flags;
  
  /*pll pll_i (
  	.clock_in(clock_16),
  	.clock_out(clock),
  	.locked(locked_pre)
  );  */
  
  assign LED0 = memory_addr[0];
  assign LED1 = !load_done;
  
  
  main_mem mem (
    .clock(clock),
    .clock2x(clock2x),
    .reset(sys_reset),
    .reload(reload),
    .index({4'b0000}),
    .load_done(load_done),
    .flags_out(mapper_flags),
    //NES interface
    .mem_addr(memory_addr),
    .mem_rd_cpu(memory_read_cpu),
    .mem_rd_ppu(memory_read_ppu),
    .mem_wr(memory_write),
    .mem_q_cpu(memory_din_cpu),
    .mem_q_ppu(memory_din_ppu),
    .mem_d(memory_dout),
    
    //Flash load interface
    .flash_csn(flash_csn),
    .flash_sck(flash_sck),
    .flash_mosi(flash_mosi),
    .flash_miso(flash_miso)
  );
  
  wire reset_nes = !load_done || sys_reset;
  reg [1:0] nes_ce = 2'b00;
  wire run_nes = (nes_ce == 2'b11);	// keep running even when reset, so that the reset can actually do its job!
  
  
  // NES is clocked at every 4th cycle.
  always @(posedge clock)
    nes_ce <= nes_ce + 1;
  
  wire [31:0] dbgadr;
  wire [1:0] dbgctr;
  
  NES nes(clock, reset_nes, run_nes,
          mapper_flags,
          sample, color,
          joy_strobe, joy_clock, {3'b0,!joy_data},
          5'b11111,  // enable all channels
          memory_addr,
          memory_read_cpu, memory_din_cpu,
          memory_read_ppu, memory_din_ppu,
          memory_write, memory_dout,
          cycle, scanline,
          dbgadr,
          dbgctr);


video video (
	.clk(clock),
		
	.color(color),
	.count_v(scanline),
	.count_h(cycle),
	.mode(1'b0),
	.smoothing(1'b1),
	.scanlines(1'b1),
	.overscan(1'b1),
	.palette(1'b0),
	
	.VGA_HS(VGA_HS),
	.VGA_VS(VGA_VS),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B)
	
);

wire audio;
assign AUDIO_O = audio;
/*sigma_delta_dac sigma_delta_dac (
	.DACout(audio),
	.DACin(sample[15:8]),
	.CLK(clock),
	.RESET(reset_nes),
  .CEN(run_nes)
);*/



endmodule
