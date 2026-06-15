module datapath(input  clk, reset,
                input  [1:0]  ResultSrcW, 
                input  PCSrcE, ALUSrcBE, ALUSrcAE,
                input  RegWriteW,
                input  [2:0]  ImmSrcD, 
                input  [3:0]  ALUControlE,
                output ZeroE, NegE
                output [31:0] PCF,
                input  [31:0] InstrF,
                output [31:0] ALUResultM, WriteDataM, InstrD,
                input  [31:0] ReadDataM);
  
  localparam WIDTH = 32; // Define a local parameter for bus width

  wire [31:0] PCNext, PCPlus4, PCTarget; 
  wire [31:0] ImmExtD; 
  wire [31:0] RD1D, RD2D, SrcAE, SrcBE; 
  wire [31:0] Result, ALUResultE;
  
  wire [31:0] PCD, PCPlus4D;
  wire [4:0] RS1E, RS2E, RDE;
  wire [31:0] RD1E, RD2E, PCE,ImmExtE, PCPlus4E;
  wire [31:0] PCPlus4M;
  wire [4:0]  RDM;
  wire [31:0] ALUResultW, ReadDataW, PCPlus4W;
  wire [4:0]  RDW;


  flopr #(WIDTH) pcreg(
    .clk(clk), 
    .reset(reset), 
    .d(PCNext), 
    .q(PCF)
  );

  adder pcadd4(
    .a(PCF), 
    .b({WIDTH{1'b0}} + 4), // Using WIDTH parameter for constant 4
    .y(PCPlus4)
  ); 

  flopr #(96) FD(
    .clk(clk), 
    .reset(reset), 
    .d({PCF, PCPlus4, InstrF}), 
    .q({PCD, PCPlus4D, InstrD})
  );

  flopr #(175) DE(
    .clk(clk), 
    .reset(reset), 
    .d({RD1D, RD2D, PCD, InstrD[19:15], InstrD[24:20], InstrD[11:7], ImmExtD, PCPlus4D}), 
    .q({RD1E, RD2E, PCE, RS1E, RS2E, RDE, ImmExtE, PCPlus4E})
  );

  flopr #(101) EM(
    .clk(clk), 
    .reset(reset), 
    .d({ALUResultE, RD2E, RDE, PCPlus4E}), 
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

  // ALU logic
  mux2 #(WIDTH)  srcamux(
    .d0(RD1E), 
    .d1(32'b0), 
    .s(ALUSrcAE), 
    .y(SrcAE)
  ); 

  // ALU logic
  mux2 #(WIDTH)  srcbmux(
    .d0(RD2E), 
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