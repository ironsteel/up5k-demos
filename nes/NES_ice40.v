// Copyright (c) 2012-2013 Ludvig Strigeus
// Copyright (c) 2017 David Shah
// This program is GPL Licensed. See COPYING for the full license.

`timescale 1ns / 1ps

module NES_ice40 (  
	// clock input
  input clock_in,
  
  // VGA
  output         VGA_HS, // VGA H_SYNC
  output         VGA_VS, // VGA V_SYNC
  output [ 2:0]  VGA_R, // VGA Red[3:0]
  output [ 2:0]  VGA_G, // VGA Green[3:0]
  output [ 2:0]  VGA_B, // VGA Blue[3:0]
                                                                                                    
  // flashmem
  output flash_sck,
  output flash_csn,
  output flash_mosi,
  input flash_miso,
  
  // SRAM interface
  output [17:0] ADR,
  inout [15:0] DAT,
  output RAMOE,
  output RAMWE,
  output RAMCS,

  input btn1,
  output LED0,
  output LED1,

  input joy_data,
  output joy_strobe,
  output joy_clock,

  output AUDIO_O
);

  wire clock_out;
  wire clock;

  always @(posedge clock)
    clock_locked <= locked_pre;
  
  reg joy_data_sync = 0;
  reg last_joypad_clock;

  always @(posedge clock) begin
    if (joy_strobe) begin
      joy_data_sync <= joy_data;
    end
    if (!joy_clock && last_joypad_clock) begin
      joy_data_sync <= joy_data;
    end
    last_joypad_clock <= joy_clock;
  end

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

  reg clock_locked;
  wire locked_pre;
  pll pll_i (
    .clock_in(clock_in),
    .clock_out(clock_out),
    .locked(locked_pre)
  ); 

  assign LED0 = memory_addr[0];
  assign LED1 = !load_done;
  
  wire sys_reset = !clock_locked;

  reg reload = 0;
  always @(posedge clock) begin
	  reload <= !btn1;
  end
  
  main_mem mem (
    .clock(clock),
    .clock2x(clock_in),
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
    .flash_miso(flash_miso),
   // SRAM
   .DAT(DAT),
   .ADR(ADR),
   .RAMOE(RAMOE),
   .RAMWE(RAMWE),
   .RAMCS(RAMCS)
  );
  
  wire reset_nes = !load_done || sys_reset;
  reg [1:0] nes_ce;
  wire run_nes = (nes_ce == 3);
    wire run_nes_g;
  SB_GB ce_buf (
    .USER_SIGNAL_TO_GLOBAL_BUFFER(run_nes),
    .GLOBAL_BUFFER_OUTPUT(run_nes_g)
  );
  
  SB_GB ce_buf1 (
    .USER_SIGNAL_TO_GLOBAL_BUFFER(clock_out),
    .GLOBAL_BUFFER_OUTPUT(clock)
  );
  
  // NES is clocked at every 4th cycle.
  always @(posedge clock)
    nes_ce <= nes_ce + 1;
  
  wire [31:0] dbgadr;
  wire [1:0] dbgctr;
  
  NES nes(clock, reset_nes, run_nes_g,
          mapper_flags,
          sample, color,
          joy_strobe, joy_clock, {3'b0, !joy_data_sync},
          5'b11111,  // enable all channels
          memory_addr,
          memory_read_cpu, memory_din_cpu,
          memory_read_ppu, memory_din_ppu,
          memory_write, memory_dout,
          cycle, scanline,
          dbgadr,
          dbgctr);

  wire [3:0] r;
  wire [3:0] g;
  wire [3:0] b;


  assign VGA_R[0] = r[3];
  assign VGA_R[1] = r[2];
  assign VGA_G[2] = r[1];
  assign VGA_G[0] = g[3];
  assign VGA_G[1] = g[2];
  assign VGA_R[2] = g[1];
  assign VGA_B[0] = b[3];
  assign VGA_B[1] = b[2];
  assign VGA_B[2] = b[1];

video video (
	.clk(clock),
	.color(color),
	.count_v(scanline),
	.count_h(cycle),
	.mode(1'b0),
	.smoothing(1'b1),
	.scanlines(1'b0),
	.overscan(1'b0),
	.palette(1'b1),
	
	.VGA_HS(VGA_HS),
	.VGA_VS(VGA_VS),
	.VGA_R(r),
	.VGA_G(g),
	.VGA_B(b)
	
);

wire audio;
assign AUDIO_O = audio;
sigma_delta_dac sigma_delta_dac (
	.DACout(audio),
	.DACin(sample[15:0]),
	.CLK(clock),
	.RESET(reset_nes),
	.CEN(run_nes)
);

endmodule
