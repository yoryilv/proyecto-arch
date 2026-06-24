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