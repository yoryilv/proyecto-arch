module testbench();
  reg  [15:0] cinstr;
  wire [31:0] expanded;
  decompressor dut(.InstrF(cinstr), .InstrD(expanded));

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;

    // C.ADDI x8, 1  = 0x00140413
    cinstr = 16'h0405; #10;
    $display("C.ADDI: in=%h out=%h", cinstr, expanded);

    // C.ADD x8, x9 = 0x00940433
    cinstr = 16'h9426; #10;
    $display("C.ADD:  in=%h out=%h", cinstr, expanded);

    // C.SUB x8, x9 = 0x40940433
    cinstr = 16'h8c05; #10;
    $display("C.SUB:  in=%h out=%h", cinstr, expanded);

    // C.XOR x8, x9 = 0x00944433
    cinstr = 16'h8c25; #10;
    $display("C.XOR:  in=%h out=%h", cinstr, expanded);

    // C.AND x8, x9 = 0x00947433
    cinstr = 16'h8c65; #10;
    $display("C.AND:  in=%h out=%h", cinstr, expanded);

    // C.OR x8, x9 = 0x00946433
    cinstr = 16'h8c45; #10;
    $display("C.OR:   in=%h out=%h", cinstr, expanded);

    // C.SLLI x8, 1 = 0x00141413
    cinstr = 16'h0406; #10;
    $display("C.SLLI: in=%h out=%h", cinstr, expanded);

    // C.SRLI x8, 1 = 0x00145413
    cinstr = 16'h8005; #10;
    $display("C.SRLI: in=%h out=%h", cinstr, expanded);

    // C.SRAI x8, 1 = 0x40145413
    cinstr = 16'h8405; #10;
    $display("C.SRAI: in=%h out=%h", cinstr, expanded);

    // C.LUI x8, 1 = 0x00001437
    cinstr = 16'h6405; #10;
    $display("C.LUI:  in=%h out=%h", cinstr, expanded);

    $finish;
  end
endmodule