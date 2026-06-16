module datapath(input  clk, reset,
                input  [1:0]  ResultSrcW,
                input  PCSrcE, ALUSrcBE,
                input  RegWriteW,
                input  [2:0]  ImmSrcD, 
                input  [3:0]  ALUControlE,
                input  [31:0] InstrF,
                input  [31:0] ReadDataM,
                input [1:0] ForwardAE, ForwardBE,
                input StallF, StallD, FlushD, FlushE,
                output ZeroE, NegE,
                output [31:0] PCF,
                output [31:0] ALUResultM, WriteDataM, InstrD,
                output [4:0] RS1E, RS2E, RDE, RDM, RDW
                );
  
  localparam WIDTH = 32; // Define a local parameter for bus width

  wire [31:0] PCNext, PCPlus4, PCTarget; 
  wire [31:0] ImmExtD; 
  wire [31:0] RD1D, RD2D, SrcAE, SrcBE, SrcBEfwd;
  wire [31:0] Result, ALUResultE;
  
  wire [31:0] PCD, PCPlus4D;
  wire [31:0] RD1E, RD2E, PCE,ImmExtE, PCPlus4E;
  wire [31:0] PCPlus4M;
  wire [31:0] ALUResultW, ReadDataW, PCPlus4W;

  flopenr #(WIDTH) pcreg(
    .clk(clk), 
    .reset(reset),
    .enable(~StallF),
    .d(PCNext), 
    .q(PCF)
  );

  adder pcadd4(
    .a(PCF), 
    .b({WIDTH{1'b0}} + 4), // Using WIDTH parameter for constant 4
    .y(PCPlus4)
  ); 

  flopenrc #(96) FD(
    .clk(clk),
    .reset(reset),
    .enable(~StallD),
    .clear(FlushD),
    .d({PCF, PCPlus4, InstrF}),
    .q({PCD, PCPlus4D, InstrD})
  );

  flopenrc #(175) DE(
    .clk(clk),
    .reset(reset),
    .enable(~StallD),
    .clear(FlushE),
    .d({RD1D, RD2D, PCD, InstrD[19:15], InstrD[24:20], InstrD[11:7], ImmExtD, PCPlus4D}),
    .q({RD1E, RD2E, PCE, RS1E, RS2E, RDE, ImmExtE, PCPlus4E})
  );

  flopr #(101) EM(
    .clk(clk), 
    .reset(reset), 
    .d({ALUResultE, SrcBEfwd, RDE, PCPlus4E}), 
    .q({ALUResultM, WriteDataM, RDM, PCPlus4M})
  );

  flopr #(101) MW(
    .clk(clk), 
    .reset(reset), 
    .d({ALUResultM, ReadDataM, RDM, PCPlus4M}), 
    .q({ALUResultW, ReadDataW, RDW, PCPlus4W})
  );



  adder       pcaddbranch(
    .a(PCE), 
    .b(ImmExtE), 
    .y(PCTarget)
  );

  mux2 #(WIDTH)  pcmux(
    .d0(PCPlus4), 
    .d1(PCTarget), 
    .s(PCSrcE), 
    .y(PCNext)
  ); 
 
  // register file logic
  regfile     rf(
    .clk(clk), 
    .we3(RegWriteW), 
    .a1(InstrD[19:15]), 
    .a2(InstrD[24:20]), 
    .a3(RDW), 
    .wd3(Result), 
    .rd1(RD1D), 
    .rd2(RD2D)
  ); 

  extend      ext(
    .instr(InstrD[31:7]), 
    .immsrc(ImmSrcD), 
    .immext(ImmExtD)
  );

  // mux forwarding para A
  mux3 #(WIDTH) srcamux(
    .d0(RD1E),
    .d1(Result),
    .d2(ALUResultM),
    .s(ForwardAE),
    .y(SrcAEfwd)
  );

  //elige entre el valor y 0 (para lui)
  mux2 #(WIDTH) srca2mux(
    .d0(SrcAEfwd),
    .d1(32'b0),
    .s(ALUSrcAE),
    .y(SrcAE)
  );

  // ALU logic
  mux3 #(WIDTH)  srcbmux(
    .d0(RD2E), 
    .d1(Result), 
    .d2(ALUResultM),
    .s(ForwardBE), 
    .y(SrcBEfwd)
  );

  mux2 #(WIDTH) srcb2mux(
    .d0(SrcBEfwd),
    .d1(ImmExtE),
    .s(ALUSrcBE),
    .y(SrcBE)
  );

  alu         alu(
    .a(SrcAE), 
    .b(SrcBE), 
    .alucontrol(ALUControlE), 
    .result(ALUResultE), 
    .zero(ZeroE),
    .neg(NegE)
  ); 

  mux3 #(WIDTH)  resultmux(
    .d0(ALUResultW), 
    .d1(ReadDataW), 
    .d2(PCPlus4W), 
    .s(ResultSrcW), 
    .y(Result)
  );

endmodule