// tanh = 2*sig(2x) - 1.0

module tanh_act #(
    parameter data = 16,
    parameter frac = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire signed [data-1:0]  x,
    input  wire in_valid,
    output reg  signed [data-1:0]  y,
    output reg out_valid
);

  localparam one_q8  = 16'sh0100;
  localparam max_pos = 16'sh7FFF;    
  localparam max_neg = 16'sh8000;

  wire signed [data:0]   x2_ext = {x[data-1], x} <<< 1;
  wire signed [data-1:0] x2_sat;

  assign x2_sat = (x2_ext > $signed({1'b0, max_pos})) ? max_pos :(x2_ext < $signed({1'b1, max_neg[data-2:0]})) ? max_neg : x2_ext[data-1:0];

    wire signed [data-1:0] sig_2x;
    wire  sig_valid;

    sigmoid #(.data(data), .frac(frac)) u_sig (
        .clk(clk), .rst_n(rst_n),
        .x(x2_sat), .in_valid(in_valid),
        .y(sig_2x), .out_valid(sig_valid)
    );

    wire signed [data:0] two_sig  = {sig_2x[data-1], sig_2x} <<< 1;
    wire signed [data:0] tanh_ext = two_sig - {1'b0, one_q8};

    wire signed [data-1:0] tanh_sat;
  assign tanh_sat = (tanh_ext > $signed({1'b0, max_pos})) ? max_pos :(tanh_ext < $signed({1'b1, max_neg[data-2:0]})) ? max_neg : tanh_ext[data-1:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 0;
            out_valid <= 0;
        end else begin
            y<= tanh_sat;
            out_valid <= sig_valid;
        end
    end

endmodule
