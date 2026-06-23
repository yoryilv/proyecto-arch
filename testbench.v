module testbench();
  reg  [15:0] cinstr;
  wire [31:0] expanded;

  decompressor dut(.InstrF(cinstr), .InstrD(expanded));

  initial begin
    // C.ADDI x8, 1  -> esperado addi x8,x8,1 = 0x00140413
    cinstr = 16'h0405; #10;
    $display("C.ADDI: in=%h out=%h", cinstr, expanded);

    // C.ADD x8, x9  -> esperado add x8,x8,x9 = 0x00940433
    cinstr = 16'h9426; #10;
    $display("C.ADD:  in=%h out=%h", cinstr, expanded);
    
    // C.SUB x8, x9 -> sub x8,x8,x9 = 0x40940433
    cinstr = 16'h8c05; #10;  // verifica el encoding de c.sub
    $display("C.SUB:  in=%h out=%h", cinstr, expanded);

    // C.AND x8, x9 -> and x8,x8,x9 = 0x0094f433
    cinstr = 16'h8c65; #10;
    $display("C.AND:  in=%h out=%h", cinstr, expanded);

    // C.OR x8, x9 -> or x8,x8,x9 = 0x0094e433
    cinstr = 16'h8c45; #10;
    $display("C.OR:   in=%h out=%h", cinstr, expanded);

    $finish;
  end
endmodule