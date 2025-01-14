`timescale 1ps/1ps
module gfmul_tb;
  // Testbench signals
  reg clk;
  reg [127:0] iCtext;
  reg [127:0] iHashkey;
  wire [127:0] oResult;

  // Instantiate the gfmul module
  gfmul uut (
    .clk(clk),
    .iCtext(iCtext),
    .iHashkey(iHashkey),
    .oResult(oResult)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100 MHz clock
  end

  // Test vector generation
  initial begin
    // Monitor output
    // Initialize inputs
    iCtext = 128'h0;
    iHashkey = 128'h0;

    // Apply test vectors
    #10     iCtext = 128'h00000000000000000000000000000005;
            iHashkey = 128'hb83b533708bf535d0aa6e52980d53b78;

    #100 $display(" clk=%b, iCtext=%h, iHashkey=%h, oResult=%h", clk, iCtext, iHashkey, oResult);
    #20 $stop; // End simulation
  end
endmodule
