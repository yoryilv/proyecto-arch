module decompressor(input [15:0] InstrF,
                    output reg [31:0] InstrD);

reg [12:0] imm_b;
reg [20:0] imm_j;

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
            5'b01_110: imm_b = {
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

            // C.JAL
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
