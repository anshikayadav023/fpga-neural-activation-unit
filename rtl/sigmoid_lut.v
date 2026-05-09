// sigmoid_lut.v - 256-entry synchronous ROM for sigmoid(x)
// Q8.8 unsigned, covers x in [0, 8.0)
// negative half handled externally via symmetry

module sigmoid_lut (
    input  wire        clk,
    input  wire [7:0]  addr,
    output reg  [15:0] data
);

    reg [15:0] rom [0:255];

    initial begin
        $readmemh("sigmoid_lut.hex", rom);
    end

    always @(posedge clk) begin
        data <= rom[addr];
    end

endmodule
