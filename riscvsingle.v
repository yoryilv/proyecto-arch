module riscvsingle(input  clk, reset,
                   output [31:0] PCF,
                   input  [31:0] InstrF,
                   output MemWriteM,
                   output [31:0] WriteDataM, ALUResultM, 
                   input  [31:0] ReadDataM);
  
  wire ALUSrcBE, ALUSrcAE, RegWriteW;
  wire BranchE, JumpE, ZeroE, NegE; 
  wire [1:0] ResultSrcW;
  wire [3:0] ALUControlE;
  wire [2:0] ImmSrcD; 
  wire       PCSrcE;
  wire [31:0] InstrD;
  

  controller c(
    .clk(clk),
    .reset(reset),
    .opD(InstrD[6:0]),
    .funct3D(InstrD[14:12]),
    .funct7b5D(InstrD[30]),
    .ZeroE(ZeroE),
    .ResultSrcW(ResultSrcW),
    .MemWriteM(MemWriteM),
    .PCSrcE(PCSrcE),
    .ALUSrcBE(ALUSrcBE),
    .ALUSrcAE(ALUSrcAE),
    .RegWriteW(RegWriteW),
    .JumpE(JumpE),
    .BranchE(BranchE),
    .ImmSrcD(ImmSrcD),
    .ALUControlE(ALUControlE),
    .NegE(NegE)
  );

  datapath dp(
    .clk(clk),
    .reset(reset),
    .ResultSrcW(ResultSrcW),
    .PCSrcE(PCSrcE),
    .ALUSrcBE(ALUSrcBE),
    .ALUSrcAE(ALUSrcAE),
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
    .NegE(NegE)
    );


endmodule