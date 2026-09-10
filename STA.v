module sta_circuit (
    input  wire clk,
    input  wire in_1,
    input  wire in_2,
    output wire out_1,
    output wire out_2
);
  reg ff1, ff2;
  assign #1.0 out_2 = in_2;
  always @(posedge clk) begin
    ff1 <= #2.0 in_1;
  end
  always @(posedge clk) begin
    ff2 <= #2.0 ff1;
  end
  assign #2.4 out_1 = ff2;
endmodule