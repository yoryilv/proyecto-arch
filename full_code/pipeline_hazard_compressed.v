module adder(input  [31:0] a, b,
             output [31:0] y);
  
  assign y = a + b; 
endmodule

module alu(input  [31:0] a, b,
           input  [3:0]  alucontrol,
           output [31:0] result,
           output zero, neg);
  
  wire [31:0] condinvb, sum; 
  wire        v; // overflow
  wire        isAddSub; 

  reg [31:0] result_reg; 
  assign result = result_reg;

  assign condinvb = alucontrol[0] ? ~b : b; 
  assign sum = a + condinvb + alucontrol[0]; 
  assign isAddSub = ~alucontrol[2] & ~alucontrol[1] |
                    ~alucontrol[1] & alucontrol[0]; 

  always @* case (alucontrol)
      4'b0000:  result_reg = sum; // add
      4'b0001:  result_reg = sum; // subtract
      4'b0010:  result_reg = a & b; // and
      4'b0011:  result_reg = a | b; // or
      4'b0100:  result_reg = a ^ b; // xor
      4'b0101:  result_reg = sum[31] ^ v; // slt
      4'b0110:  result_reg = a << b[4:0]; // sll
      4'b0111:  result_reg = a >> b[4:0]; // srl
      4'b1000:  result_reg = $signed(a) >>> b[4:0]; //sra
      default:  result_reg = 32'bx;
    endcase

  assign zero = (result == 32'b0); 
  assign v = ~(alucontrol[0] ^ a[31] ^ b[31]) & (a[31] ^ sum[31]) & isAddSub;
  assign neg = result[31];
  
endmodule

module aludec(input  opb5,
              input  [2:0] funct3,
              input  funct7b5, 
              input  [1:0] ALUOp,
              output [3:0] ALUControl);
  
  wire  RtypeSub; 
  reg [3:0] ALUControl_reg; 

  assign RtypeSub = funct7b5 & opb5;  // TRUE for R-type subtract instruction
  assign ALUControl = ALUControl_reg;

  always @* case(ALUOp)
      2'b00:                ALUControl_reg = 4'b0000; // addition
      2'b01:                ALUControl_reg = 4'b0001; // subtraction
      default: case(funct3) // R-type or I-type ALU
                 3'b000:  if (RtypeSub) ALUControl_reg = 4'b0001; // sub
                          else ALUControl_reg = 4'b0000; // add, addi
                 3'b010:    ALUControl_reg = 4'b0101; // slt, slti
                 3'b110:    ALUControl_reg = 4'b0011; // or, ori
                 3'b111:    ALUControl_reg = 4'b0010; // and, andi
                 3'b100:    ALUControl_reg = 4'b0100; // xor, xori
                 3'b001:    ALUControl_reg = 4'b0110; // sll, slli
                 3'b101:    if(funct7b5) ALUControl_reg = 4'b1000; // sra srai
                            else ALUControl_reg = 4'b0111; //srl srli
                 default:   ALUControl_reg = 4'bxxxx; // ???
               endcase
    endcase
endmodule

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

module datapath(input  clk, reset,
                input  [1:0]  ResultSrcW,
                input  PCSrcE, ALUSrcBE, ALUSrcAE,
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
  wire [31:0] RD1D, RD2D, SrcAE, SrcAEfwd, SrcBE, SrcBEfwd;
  wire [31:0] Result, ALUResultE;
  
  wire [31:0] PCD, PCPlus4D;
  wire [31:0] RD1E, RD2E, PCE,ImmExtE, PCPlus4E;
  wire [31:0] PCPlus4M;
  wire [31:0] ALUResultW, ReadDataW, PCPlus4W;

  wire IsCompressed = (InstrF[1:0] != 2'b11);
  wire [31:0] PCIncr = IsCompressed ? 32'd2 : 32'd4;
  wire [31:0] InstrDecomp, InstrFinal;

  decompressor dec(
    .InstrF(InstrF[15:0]),
    .InstrD(InstrDecomp)  
  );


  mux2 #(32) instrmux(
    .d0(InstrF), //pasa normal
    .d1(InstrDecomp), //pasa expandida
    .s(IsCompressed),
    .y(InstrFinal)
  );


  flopenr #(WIDTH) pcreg(
    .clk(clk), 
    .reset(reset),
    .enable(~StallF),
    .d(PCNext), 
    .q(PCF)
  );

  adder pcadd4(
    .a(PCF), 
    .b(PCIncr), // suma 2 IsCompressed, 4 
    .y(PCPlus4)
  ); 

  flopenrc #(96) FD(
    .clk(clk),
    .reset(reset),
    .enable(~StallD),
    .clear(FlushD),
    .d({PCF, PCPlus4, InstrFinal}),
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

module decompressor(input [15:0] InstrF,
                    output reg [31:0] InstrD);

reg [12:0] imm_b;
reg [20:0] imm_j;

    always @ (*) begin
        case ({InstrF[1:0], InstrF[15:13]}) // quadrant & funct3
            5'b01_010: InstrD = {
                {6{InstrF[12]}}, InstrF[12], InstrF[6:2],
                5'b00000,
                3'b000,
                InstrF[11:7],
                7'b0010011
            };

            // C.ADDI
            5'b01_000: InstrD = {
                {6{InstrF[12]}},
                InstrF[12],
                InstrF[6:2],
                InstrF[11:7],
                3'b000,
                InstrF[11:7],
                7'b0010011
            };

            // C.ADD, C.JR, C.JALR
            5'b10_100: begin
                if(InstrF[6:2] == 5'b00000) begin
                    if(InstrF[12] == 1'b0) InstrD = {
                        12'b000000000000,
                        InstrF[11:7],
                        3'b000,
                        5'b00000,
                        7'b1100111  
                    };
                    else InstrD = {
                        12'b000000000000,
                        InstrF[11:7],
                        3'b000,
                        5'b00001,
                        7'b1100111
                    };
                end else begin
                    if (InstrF[12] == 1'b1) InstrD = {
                        7'b0000000,
                        InstrF[6:2],
                        InstrF[11:7],
                        3'b000,
                        InstrF[11:7],
                        7'b0110011
                    };
                    else
                        InstrD = 32'h00000013;
                end
            end

            // C.SLLI
            5'b10_000: InstrD = {
                7'b0000000,
                InstrF[6:2],
                InstrF[11:7],
                3'b001,
                InstrF[11:7],
                7'b0010011
            };

            // C.LUI
            5'b01_011: InstrD = {
                {14{InstrF[12]}},
                InstrF[12],
                InstrF[6:2],
                InstrF[11:7],
                7'b0110111
            };

            // C.LW
            5'b00_010: InstrD = {
                5'b00000, InstrF[5], InstrF[12:10], InstrF[6], 2'b00,
                {2'b01, InstrF[9:7]},
                3'b010,
                {2'b01, InstrF[4:2]},
                7'b0000011
            };

            // C.SW
            5'b00_110: InstrD = {
                5'b00000, InstrF[5], InstrF[12],
                {2'b01, InstrF[4:2]},
                {2'b01, InstrF[9:7]},
                3'b010,
                InstrF[11:10], InstrF[6], 2'b00,
                7'b0100011
            };


            // C.LWSP
            5'b10_010: InstrD = {
                4'b0000, InstrF[3:2], InstrF[12], InstrF[6:4], 2'b00,
                5'b00010,
                3'b010,
                InstrF[11:7],
                7'b0000011
            };

            // C.SWSP
            5'b10_110: InstrD = {
                4'b0000, InstrF[8:7], InstrF[12],
                InstrF[6:2],
                5'b00010,
                3'b010,
                InstrF[11:9], 2'b00,
                7'b0100011
            };

            // C.BEQZ
            5'b01_110: begin
            imm_b = {
                {4{InstrF[12]}},
                InstrF[12],
                InstrF[6:5],
                InstrF[2],
                InstrF[11:10],
                InstrF[4:3],
                1'b0
            };
            InstrD = {
                imm_b[12], imm_b[10:5],
                5'b00000,
                {2'b01, InstrF[9:7]},
                3'b000,
                imm_b[4:1], imm_b[11],
                7'b1100011
            };
            end

            // C.BNEZ
            5'b01_111: begin
                imm_b = {
                    {4{InstrF[12]}},
                    InstrF[12],
                    InstrF[6:5],
                    InstrF[2],
                    InstrF[11:10],
                    InstrF[4:3],
                    1'b0
                };
                InstrD = {
                    imm_b[12], imm_b[10:5],
                    5'b00000,
                    {2'b01, InstrF[9:7]},
                    3'b001,
                    imm_b[4:1], imm_b[11],
                    7'b1100011
                };
            end

            // C.J
            5'b01_101: begin
                imm_j = {
                    {10{InstrF[12]}},
                    InstrF[8],
                    InstrF[10:9],
                    InstrF[7],
                    InstrF[6],
                    InstrF[2],
                    InstrF[11],
                    InstrF[5:3],
                    1'b0
                };
                InstrD = {
                    imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12],
                    5'b00000,
                    7'b1101111
                };
            end

            5'b01_001: begin
                imm_j = {
                    {10{InstrF[12]}},
                    InstrF[8],
                    InstrF[10:9],
                    InstrF[7],
                    InstrF[6],
                    InstrF[2],
                    InstrF[11],
                    InstrF[5:3],
                    1'b0
                };
                InstrD = {
                    imm_j[20], imm_j[10:1], imm_j[11], imm_j[19:12],
                    5'b00001,
                    7'b1101111
                };
            end

            // C.SUB C.XOR C.OR C.AND C.SRLI C.srai
            5'b01_100: begin
                case (InstrF[11:10])
                2'b00: // C.SRLI
                    InstrD = {
                        7'b0000000,
                        InstrF[6:2],
                        {2'b01, InstrF[9:7]},
                        3'b101,
                        {2'b01, InstrF[9:7]},
                        7'b0010011
                    };

                2'b01: // C.SRAI
                    InstrD = {
                        7'b0100000,
                        InstrF[6:2],
                        {2'b01, InstrF[9:7]},
                        3'b101,
                        {2'b01, InstrF[9:7]},
                        7'b0010011
                    };

                2'b11: begin
                    case(InstrF[6:5])
                        2'b00: InstrD = {
                            7'b0100000,
                            {2'b01, InstrF[4:2]},
                            {2'b01, InstrF[9:7]},
                            3'b000,
                            {2'b01, InstrF[9:7]},
                            7'b0110011
                        }; // C.SUB

                        2'b01: InstrD = {
                            7'b0000000,
                            {2'b01, InstrF[4:2]},
                            {2'b01, InstrF[9:7]},
                            3'b100,
                            {2'b01, InstrF[9:7]},
                            7'b0110011
                        }; // C.XOR

                        2'b10: InstrD = {
                            7'b0000000,
                            {2'b01, InstrF[4:2]},
                            {2'b01, InstrF[9:7]},
                            3'b110,
                            {2'b01, InstrF[9:7]},
                            7'b0110011
                        }; // C.OR


                        2'b11: InstrD = {
                            7'b0000000,
                            {2'b01, InstrF[4:2]},
                            {2'b01, InstrF[9:7]},
                            3'b111,
                            {2'b01, InstrF[9:7]},
                            7'b0110011
                        }; // C.AND

                        default: InstrD = 32'h00000013; // nop
                      endcase
                    end

                    default: InstrD = 32'h00000013; // nop
                  endcase
                end

            default: InstrD = 32'h00000013; // nop
        endcase
    end

endmodule



module dmem(input  clk, we,
            input  [31:0] a, wd,
            output [31:0] rd);
  
  reg [31:0] RAM[63:0]; 

  assign rd = RAM[a[31:2]]; // word aligned

  always @(posedge clk) begin 
    if (we) RAM[a[31:2]] <= wd; 
  end
endmodule


module extend(input  [31:7] instr,
              input  [2:0]  immsrc,
              output [31:0] immext);
  
  reg [31:0] immext_reg; 
  assign immext = immext_reg;

  always @* case(immsrc) 
               // I-type 
      3'b000:   immext_reg = {{20{instr[31]}}, instr[31:20]}; 
               // S-type (stores)
      3'b001:   immext_reg = {{20{instr[31]}}, instr[31:25], instr[11:7]}; 
               // B-type (branches)
      3'b010:   immext_reg = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; 
               // J-type (jal)
      3'b011:   immext_reg = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
               // U-type (lui)
      3'b100:   immext_reg = {instr[31:12], 12'b0};
      default: immext_reg = 32'bx; // undefined
    endcase             
endmodule


module flopenr (input  clk, reset, enable,
               input  [WIDTH-1:0] d, 
               output reg [WIDTH-1:0] q);

  parameter WIDTH = 8;

  always @(posedge clk or posedge reset) begin 
    if (reset) q <= 0; 
    else if (enable)     q <= d; 
  end
endmodule

module flopenrc (input  clk, reset, enable, clear,
               input  [WIDTH-1:0] d, 
               output reg [WIDTH-1:0] q);

  parameter WIDTH = 8;

  always @(posedge clk or posedge reset) begin 
    if (reset) q <= 0; 
    else if (clear) q <=0;
    else if (enable)     q <= d; 
  end
endmodule

module flopr (input  clk, reset,
               input  [WIDTH-1:0] d, 
               output reg [WIDTH-1:0] q);

  parameter WIDTH = 8;

  always @(posedge clk or posedge reset) begin 
    if (reset) q <= 0; 
    else       q <= d; 
  end
endmodule

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

module imem(input  [31:0] a,
            output [31:0] rd);
  
  reg [31:0] RAM[63:0]; // RAM[64:0] opcion de ampliar para leer la ultima instruccion 

  initial begin
    $readmemh("riscvtest.mem", RAM);
  end

  wire [31:0] wordIdx = a[31:2];

  wire [31:0] wordCurr = RAM[wordIdx];
  wire [31:0] wordNext = RAM[wordIdx+1];

  wire [63:0] doble = {wordNext, wordCurr};

  assign rd = a[1] ? doble[47:16] : doble[31:0];

endmodule

module maindec(input  [6:0] op,
               output [1:0] ResultSrc,
               output MemWrite,
               output Branch, ALUSrcB, ALUSrcA,
               output RegWrite, Jump,
               output [2:0] ImmSrc, 
               output [1:0] ALUOp); 
  
  reg [12:0] controls; 

  assign {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemWrite,
          ResultSrc, Branch, ALUOp, Jump} = controls; 

  always @* case(op)
    // RegWrite_ImmSrc_ALUSrcA_ALUSrcB_MemWrite_ResultSrc_Branch_ALUOp_Jump
      7'b0000011: controls = 13'b1_000_0_1_0_01_0_00_0; // lw
      7'b0100011: controls = 13'b0_001_0_1_1_00_0_00_0; // sw
      7'b0110011: controls = 13'b1_xxx_0_0_0_00_0_10_0; // R-type
      7'b1100011: controls = 13'b0_010_0_0_0_00_1_01_0; // beq
      7'b0010011: controls = 13'b1_000_0_1_0_00_0_10_0; // I-type ALU
      7'b1101111: controls = 13'b1_011_0_0_0_10_0_00_1; // jal
      7'b1100111: controls = 13'b1_000_0_1_0_10_0_00_1; // jalr
      7'b0110111: controls = 13'b1_100_1_1_0_00_0_00_0; // lui
      7'b0000000: controls = 13'b0_000_0_1_0_00_0_00_0; // NOP
      default:    controls = 13'bx_xxx_x_x_xx_x_xx_x; // non-implemented instruction
    endcase
endmodule

module mux2 (input  [WIDTH-1:0] d0, d1, 
              input  s, 
              output [WIDTH-1:0] y);

  parameter WIDTH = 8;

  assign y = s ? d1 : d0; 
endmodule

module mux3 (input  [WIDTH-1:0] d0, d1, d2,
              input  [1:0]       s, 
              output [WIDTH-1:0] y);

  parameter WIDTH = 8;

  assign y = s[1] ? d2 : (s[0] ? d1 : d0); 
endmodule

module regfile(input  clk, 
               input  we3, 
               input  [ 4:0] a1, a2, a3, 
               input  [31:0] wd3, 
               output [31:0] rd1, rd2); 

  reg [31:0] rf[31:0]; 

  // write third port on rising edge of clock (A3/WD3/WE3)
  always @(negedge clk) begin 
    if (we3) rf[a3] <= wd3; 
  end
  
  // read two ports combinationally (A1/RD1, A2/RD2)
  // register 0 hardwired to 0
  assign rd1 = (a1 != 0) ? rf[a1] : 0; 
  assign rd2 = (a2 != 0) ? rf[a2] : 0; 
endmodule

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
    .ALUSrcAE(ALUSrcAE),
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

module top(input  clk, reset, 
           output [31:0] WriteData, DataAdr, 
           output MemWrite);
  
  wire [31:0] PCF, InstrF, ReadDataM; 
  
  // instantiate processor and memories
  riscvsingle rvsingle(
    .clk(clk), 
    .reset(reset), 
    .PCF(PCF), 
    .InstrF(InstrF), 
    .MemWriteM(MemWrite), 
    .ALUResultM(DataAdr), 
    .WriteDataM(WriteData), 
    .ReadDataM(ReadDataM)
  ); 

  imem imem(
    .a(PCF), 
    .rd(InstrF)
  ); 

  dmem dmem(
    .clk(clk), 
    .we(MemWrite), 
    .a(DataAdr), 
    .wd(WriteData), 
    .rd(ReadDataM)
  ); 
endmodule

