testbench: flashmem.v  sim_spiflash.v  MicroCode.v NES_ice40.v  pll.v  scan_double.v up_spram.v  testbench.v apu.v compat.v cart_mem.v  cpu.v     generic_ram.v  main_mem.v  mmu.v        nes.v        ppu.v  sigma_delta_dac.v     video.v 
	iverilog -o testbench $^  $(shell yosys-config --datdir/ice40/cells_sim.v)
testbench_vcd: testbench 
	vvp -N testbench -fst +vcd
# ++ 70-firmware ++
