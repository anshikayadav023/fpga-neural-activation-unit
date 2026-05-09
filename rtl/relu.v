// y = max(0, x)

module relu #(
    parameter data= 16
)(
input  wire signed [data-1:0] x,
input  wire in_valid,
output wire signed [data-1:0] y,
output wire out_valid
);
assign y = x[data-1] ? {data{1'b0}}:x;
assign out_valid = in_valid;

endmodule
