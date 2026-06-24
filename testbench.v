module testbench();
  reg clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire MemWrite;

  top dut(
    .clk(clk), .reset(reset),
    .WriteData(WriteData), .DataAdr(DataAdr), .MemWrite(MemWrite)
  );

  
  always #5 clk = ~clk;
  

  initial begin
    clk = 0;
    reset = 1;
    #22;
    reset = 0;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    #400;
    $display("RESULTADO (Programa comprimidas):");
    $display("  mem[0]  = %0d (esperado 35)",   dut.dmem.RAM[0]);
    $display("  mem[4]  = %0d (esperado 2)",    dut.dmem.RAM[1]);
    $display("  mem[8]  = %0d (esperado 2)",    dut.dmem.RAM[2]);
    $display("  mem[12] = %0d (esperado 15)",   dut.dmem.RAM[3]);
    $display("  mem[16] = %0d (esperado 42)",   dut.dmem.RAM[4]);
    $display("  mem[20] = %0d (esperado 96)",   dut.dmem.RAM[5]);
    $display("  mem[24] = %h (esperado 2000)",  dut.dmem.RAM[6]);
    if (dut.dmem.RAM[0]===35 && dut.dmem.RAM[1]===2 && dut.dmem.RAM[2]===2 &&
        dut.dmem.RAM[3]===15 && dut.dmem.RAM[4]===42 && dut.dmem.RAM[5]===96 &&
        dut.dmem.RAM[6]===32'h00002000)
      $display("  >> TEST PASSED");
    else
      $display("  >> TEST FAILED");
    $finish;
  end
endmodule