module controller(input clk, reset,
                  input  [6:0] opD,
                  input  [2:0] funct3D,
                  input        funct7b5D,
                  input        ZeroE, NegE,
                  input StallD, FlushE,
                  output [1:0] ResultSrcW, 
                  output MemWriteM, RegWriteM,
                  output PCSrcE, ALUSrcBE, ALUSrcAE,
                  output RegWriteW, JumpE, BranchE,
                  output [1:0] ResultSrcE, ResultSrcD,
                  output [2:0] ImmSrcD, 
                  output [3:0] ALUControlE);
  
  wire [1:0] ALUOpD;
  wire       BranchD, JumpD;
  wire ALUSrcAD, ALUSrcBD;
  wire RegWriteD, MemWriteD;
  wire [3:0] ALUControlD;

  wire RegWriteE, MemWriteE;
  wire [1:0] ResultSrcM;

  wire [2:0] funct3E;
  reg BranchCondE;
  
  maindec md(
    .op(opD),
    .ResultSrc(ResultSrcD),
    .MemWrite(MemWriteD), 
    .Branch(BranchD),
    .ALUSrcB(ALUSrcBD),
    .ALUSrcA(ALUSrcAD),
    .RegWrite(RegWriteD), 
    .Jump(JumpD), 
    .ImmSrc(ImmSrcD), 
    .ALUOp(ALUOpD)
  ); 

  aludec  ad(
    .opb5(opD[5]), 
    .funct3(funct3D), 
    .funct7b5(funct7b5D), 
    .ALUOp(ALUOpD), 
    .ALUControl(ALUControlD)
  );


  flopenrc #(15) DE_cu (
    .clk(clk),
    .reset(reset),
    .enable(~StallD),
    .clear(FlushE),
    .d({RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD, ALUControlD, ALUSrcAD, ALUSrcBD, funct3D}),
    .q({RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE, ALUControlE, ALUSrcAE, ALUSrcBE, funct3E})
  );

  flopr #(4) EM_cu (
    .clk(clk),
    .reset(reset),
    .d({RegWriteE, ResultSrcE, MemWriteE}),
    .q({RegWriteM, ResultSrcM, MemWriteM})
  );

  flopr #(3) MW_cu (
    .clk(clk),
    .reset(reset),
    .d({RegWriteM, ResultSrcM}),
    .q({RegWriteW, ResultSrcW})
  );

  always @ * begin
  BranchCondE = 1'b0;
  if (BranchE) case(funct3E)
    3'b000: BranchCondE = ZeroE;
    3'b001: BranchCondE = ~ZeroE;
    3'b100: BranchCondE = NegE;
    3'b101: BranchCondE = ~NegE;
    default: BranchCondE = 1'b0;
    endcase
    end

  assign PCSrcE = (BranchE & BranchCondE) | JumpE;

endmodule