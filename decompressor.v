module decompressor(input [15:0] InstrF,
                    output reg [31:0] InstrD);

    always @ (*) begin
        case ({InstrF[1:0], InstrF[15:13]}) // quadrant & funct3
            
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

            // C.ADD
            5'b10_100: InstrD = {
                7'b0000000,
                InstrF[6:2],
                InstrF[11:7],
                3'b000,
                InstrF[11:7],
                7'b0110011
            };

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
