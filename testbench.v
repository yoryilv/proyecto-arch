module testbench();
  reg  clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire        MemWrite;
  top dut(
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite)
  );
  always #5 clk=~clk;
  initial begin
    clk = 0;
    reset = 1;
    #50;
    reset = 0;
  end
  initial begin
    $dumpfile("test.vcd");
    $dumpvars();
  end
  
  initial begin
    #500;
    if (dut.dmem.RAM[1] === 32'd12)
  $display("TEST PASSED: bge funcionó, mem[4] = %0d", dut.dmem.RAM[1]);
else
  $display("TEST FAILED: mem[4] = %0d", dut.dmem.RAM[1]);
    $finish;
  end
endmodule