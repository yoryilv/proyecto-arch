module riscvsingle(input  clk, reset,
                   output [31:0] PCF,
                   input  [31:0] InstrF,
                   output MemWriteM,
                   output [31:0] WriteDataM, ALUResultM, 
                   input  [31:0] ReadDataM);
  
  wire ALUSrcBE, RegWriteW;
  wire BranchE, JumpE, ZeroE, NegE; 
  wire [1:0] ResultSrcW;
  wire [3:0] ALUControlE;
  wire [2:0] ImmSrcD; 
  wire       PCSrcE;
  wire [31:0] InstrD;

  wire [1:0] ForwardAE, ForwardBE;
  wire StallF, StallD, FlushD, FlushE;
  wire [1:0] ResultSrcE, ResultSrcD;
  wire RegWriteM;
  wire [4:0] RS1E, RS2E, RDE, RDM, RDW;

    hazard hu(
      .RS1D(InstrD[19:15]),
      .RS2D(InstrD[24:20]),
      .RS1E(RS1E),
      .RS2E(RS2E),
      .RDE(RDE),
      .RDM(RDM),
      .RDW(RDW),
      .RegWriteM(RegWriteM),
      .RegWriteW(RegWriteW),
      .ResultSrcE(ResultSrcE),
      .PCSrcE(PCSrcE),
      .ForwardAE(ForwardAE),
      .ForwardBE(ForwardBE),
      .StallF(StallF),
      .StallD(StallD),
      .FlushD(FlushD),
      .FlushE(FlushE)
    );
  

  controller c(
    .clk(clk),
    .reset(reset),
    .opD(InstrD[6:0]),
    .funct3D(InstrD[14:12]),
    .funct7b5D(InstrD[30]),
    .ZeroE(ZeroE),
    .ResultSrcW(ResultSrcW),
    .ResultSrcD(ResultSrcD),
    .MemWriteM(MemWriteM),
    .PCSrcE(PCSrcE),
    .ALUSrcBE(ALUSrcBE),
    .RegWriteW(RegWriteW),
    .JumpE(JumpE),
    .BranchE(BranchE),
    .ImmSrcD(ImmSrcD),
    .ALUControlE(ALUControlE),
    .NegE(NegE),
    .ResultSrcE(ResultSrcE),
    .RegWriteM(RegWriteM),
    .StallD(StallD),
    .FlushE(FlushE)
    );

  datapath dp(
    .clk(clk),
    .reset(reset),
    .ResultSrcW(ResultSrcW),
    .PCSrcE(PCSrcE),
    .ALUSrcBE(ALUSrcBE),
    .RegWriteW(RegWriteW),
    .ImmSrcD(ImmSrcD),
    .ALUControlE(ALUControlE),
    .ZeroE(ZeroE),
    .PCF(PCF),
    .InstrF(InstrF),
    .InstrD(InstrD),
    .ALUResultM(ALUResultM),
    .WriteDataM(WriteDataM),
    .ReadDataM(ReadDataM),
    .NegE(NegE),
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE),
    .StallF(StallF),
    .StallD(StallD),
    .FlushD(FlushD),
    .FlushE(FlushE),
    .RS1E(RS1E),
    .RS2E(RS2E),
    .RDE(RDE),
    .RDM(RDM),
    .RDW(RDW)
    );


endmodule