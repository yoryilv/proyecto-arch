module testbench();
  reg clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire MemWrite;
  top dut(.clk(clk), .reset(reset),
          .WriteData(WriteData), .DataAdr(DataAdr), .MemWrite(MemWrite));
  
  always #5 clk = ~clk;
  
  initial begin
    clk = 0; reset = 1; #22; reset = 0;
  end

  initial begin
    $dumpfile("dump.vcd"); $dumpvars;
    #3000;
    $display("RESULTADO (Bubble Sort):");
    $display("  mem[0] = %0d (esperado 1)", dut.dmem.RAM[0]);
    $display("  mem[4] = %0d (esperado 2)", dut.dmem.RAM[1]);
    $display("  mem[8] = %0d (esperado 3)", dut.dmem.RAM[2]);
    $display("  mem[12]= %0d (esperado 4)", dut.dmem.RAM[3]);
    if (dut.dmem.RAM[0]===32'd1 && dut.dmem.RAM[1]===32'd2 &&
        dut.dmem.RAM[2]===32'd3 && dut.dmem.RAM[3]===32'd4)
      $display("  >> TEST PASSED");
    else
      $display("  >> TEST FAILED");
    $finish;
  end

  initial begin
    $monitor("t=%0t PC=%h mem[0]=%0d mem[4]=%0d mem[8]=%0d mem[12]=%0d",
             $time, dut.rvsingle.dp.PCF,
             dut.dmem.RAM[0], dut.dmem.RAM[1],
             dut.dmem.RAM[2], dut.dmem.RAM[3]);
  end
endmodule