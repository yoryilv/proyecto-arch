module flopenr (input  clk, reset, enable,
               input  [WIDTH-1:0] d, 
               output reg [WIDTH-1:0] q);

  parameter WIDTH = 8;

  always @(posedge clk or posedge reset) begin 
    if (reset) q <= 0; 
    else if (enable)     q <= d; 
  end
endmodule