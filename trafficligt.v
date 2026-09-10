module traffic_light_simple (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [2:0] lights  
);
  localparam RED    = 3'b100,
             YELLOW = 3'b010,
             GREEN  = 3'b001;
  reg [3:0] count;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      lights <= RED;
      count  <= 0;
    end else begin
      count <= count + 1'b1;
      case (lights)
        GREEN: if (count == 9) begin  
          lights <= YELLOW;
          count  <= 0;
        end
        YELLOW: if (count == 2) begin 
          lights <= RED;
          count  <= 0;
        end
        RED: if (count == 11) begin   
          lights <= GREEN;
          count  <= 0;
        end
        default: begin
          lights <= RED;
          count  <= 0;
        end
      endcase
    end
  end

endmodule