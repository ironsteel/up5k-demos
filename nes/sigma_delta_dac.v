module sigma_delta_dac(
   output    reg             DACout,   //Average Output feeding analog lowpass
   input          [MSBI:0]    DACin,   //DAC input (excess 2**MSBI)
   input                  CLK,
   input                  CEN,
   input                   RESET
);

parameter MSBI = 15;

(* mem2reg *) reg [MSBI+2:0] DeltaAdder;   //Output of Delta Adder
(* mem2reg *) reg [MSBI+2:0] SigmaAdder;   //Output of Sigma Adder
(* mem2reg *) reg [MSBI+2:0] SigmaLatch;   //Latches output of Sigma Adder
(* mem2reg *) reg [MSBI+2:0] DeltaB;      //B input of Delta Adder

always @ (*)
   DeltaB = {SigmaLatch[MSBI+2], SigmaLatch[MSBI+2]} << (MSBI+1);

always @(*)
   DeltaAdder = DACin + DeltaB;
   
always @(*)
   SigmaAdder = DeltaAdder + SigmaLatch;
   
always @(posedge CLK)
    begin
      SigmaLatch <= SigmaAdder;
      DACout <= SigmaLatch[MSBI+2];
   end
endmodule 
