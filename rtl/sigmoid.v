// negative inputs handled via sig(-x) = 1 - sig(x)

module sigmoid #(
    parameter data = 16,
    parameter frac = 8
)(
  
  input  wire clk,
  input  wire rst_n,
  input  wire signed [data-1:0] x,
  input  wire in_valid,
  output reg  signed [data-1:0] y,
  output reg out_valid
);

  localparam one_q8 = 16'h0100;
  
  wire signed [data-1:0]  abs_x  = x[data-1] ? (-x) : x;

  wire sat = abs_x[data-1] | (abs_x >= 16'sh0580); //saturation is at +5.5 and -5.5
  wire [7:0] lut_addr  = sat ? 8'hFF : abs_x[10:3];
  wire [15:0] lut_data;
  
  sigmoid_lut u_sig_lut (
        .clk  (clk),
        .addr (lut_addr),
        .data (lut_data)
    );

    reg is_neg_d1, valid_d1, sat_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_neg_d1    <= 0;
            valid_d1     <= 0;
            sat_d1 <= 0;
        end else begin
            is_neg_d1    <= if_neg;
            valid_d1     <= in_valid;
            sat_d1 <= sat;
        end
    end

    wire [15:0] sig_pos = lut_data;
  wire [15:0] sig_neg = (lut_data > one_q8) ? 16'h0000 : (one_q8 - lut_data);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y         <= 0;
            out_valid <= 0;
        end else begin
            if (sat_d1)
                y <= is_neg_d1 ? 16'h0000 : one_q8;
            else
                y <= is_neg_d1 ? $signed(sig_neg) : $signed(sig_pos);
            out_valid <= valid_d1;
        end
    end

endmodule
