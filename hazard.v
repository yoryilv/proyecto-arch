module hazard(input [4:0] RS1D, RS1E, RS2D, RS2E, RDE, RDM, RDW,
              input RegWriteM, RegWriteW, PCSrcE,
              input [1:0] ResultSrcE,
              output StallD, StallF,
              output FlushD, FlushE,
              output reg [1:0] ForwardAE, ForwardBE);

wire lwStall;

//forwarding A logic
always @ * begin
    if ((RS1E == RDM) & RegWriteM & (RS1E != 0)) ForwardAE = 2'b10;
    else if ((RS1E == RDW) & RegWriteW & (RS1E != 0)) ForwardAE = 2'b01;
    else ForwardAE = 2'b00;
end

//forwarding B logic
always @ * begin
    if ((RS2E == RDM) & RegWriteM & (RS2E != 0)) ForwardBE = 2'b10;
    else if ((RS2E == RDW) & RegWriteW & (RS2E != 0)) ForwardBE = 2'b01;
    else ForwardBE = 2'b00;
end


assign lwStall = ResultSrcE[0] & ((RS1D == RDE) | (RS2D == RDE));

assign StallF = lwStall;
assign StallD = lwStall;
assign FlushD = PCSrcE;
assign FlushE = lwStall | PCSrcE;

endmodule