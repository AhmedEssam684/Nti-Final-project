module parity_generator
#()(
    input  logic [7:0] data_in,
    output logic             even_parity,
    output logic             odd_parity
);
  assign even_parity = ^data_in;
  assign odd_parity  = ~^data_in;
endmodule