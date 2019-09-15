ARACHNE = arachne-pnr
#ARACHNE_ARGS = -s 7
ARACHNE_ARGS =
ICEPACK = icepack
ICETIME = icetime
ICEPROG = iceprogduino
SOURCES = $(wildcard *.v)
# ---- iCE40 UP5k Breakout Board ----


up5knes.blif:  $(SOURCES)
	#yosys -ql up5knes.log -p 'synth_ice40 -top NES_ice40 -blif up5knes.blif -abc9' $^
	yosys -l up5knes.log -p 'synth_ice40 -abc9 -top NES_ice40 -json up5knes.blif' $^

up5knes_syn.v: up5knes.blif
	yosys -p 'read_blif -wideports up5knes.blif; write_verilog up5knes_syn.v'

up5knes.asc: up5k.pcf up5knes.blif
	#$(ARACHNE) -d 8k $(ARACHNE_ARGS) -P ct256 -o up5knes.asc -p up5k.pcf up5knes.blif
	nextpnr-ice40 --placer=heap --hx8k --package ct256 --json up5knes.blif --pcf up5k.pcf --asc up5knes.asc 

up5knes.bin: up5knes.asc
	$(ICETIME) -d hx8k -c 12 -r up5knes.rpt up5knes.asc
	$(ICEPACK) -s up5knes.asc up5knes.bin

rom/game%.bin: rom/game%.nes
	rom/nes2bin.py $^ $@

GAMES = $(sort $(wildcard rom/game*.nes))
IMAGES = $(GAMES:.nes=.bin)

rom/games.bin: $(IMAGES)
	cat $^ > $@
	
prog: up5knes.bin 
	$(ICEPROG)  up5knes.bin
	$(ICEPROG) -o 1024k -n rom/games.bin
	

up5kprog_game: rom/games.bin
	$(ICEPROG) -o 1024k -n rom/games.bin



# ---- Clean ----

clean:
	rm -f up5knes.blif up5knes.log up5knes.asc up5knes.rpt up5knes.bin

.PHONY: up5kprog up5kprog_fw  clean

