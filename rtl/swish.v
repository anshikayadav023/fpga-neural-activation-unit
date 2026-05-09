// y = x * sigmoid(x)

module swish #(
    parameter data = 16,
    parameter frac = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire signed [data-1:0]  x,
    input  wire in_valid,
    output wire signed [data-1:0]  y,
    output wire out_valid
);

    wire signed [data-1:0] sig_x;
    wire sig_valid;

    sigmoid #(.data(data), .frac(frac)) u_sig (
        .clk(clk), .rst_n(rst_n),
        .x(x), .in_valid(in_valid),
        .y(sig_x), .out_valid(sig_valid)
    );

    reg signed [data-1:0] x_d1, x_d2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_d1 <= 0;
            x_d2 <= 0;
        end else begin
            x_d1 <= x;
            x_d2 <= x_d1;
        end
    end

    fixed_point_mult #(.data(data), .frac(frac)) u_mult (
        .clk(clk), .rst_n(rst_n),
        .a(x_d2), .b(sig_x),
        .in_valid(sig_valid),
        .result(y), .out_valid(out_valid)
    );

endmodule
