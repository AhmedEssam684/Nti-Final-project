module single_port_ram #(

)(
    input clk,we,[3:0] addr,[7:0] din,output reg  [7:0] dout   
);
  reg [7:0] ram [0:(1<<3)];
  always @(posedge clk) begin
    if (we) begin
      ram[addr] <= din;  
    end
    dout <= ram[addr];     
  end

endmodule