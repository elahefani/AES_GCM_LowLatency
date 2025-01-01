`timescale 1ns / 1ps

module gfmul_tb;

// Declare inputs as regs and outputs as wires
reg [0:127] iCtext;
reg [0:127] iHashkey;
wire [0:127] oResult;

// Instantiate the Unit Under Test (UUT)
gfmul uut (
    .iCtext(iCtext),
    .iHashkey(iHashkey),
    .oResult(oResult)
);

initial begin
    // Test vectors
    // Apply the first test case
    iCtext = 128'hfeedfacedeadbeeffeedfacedeadbeef;
    iHashkey = 128'h466923ec9ae682214f2c082badb39249;
    #100; // Wait for 10 ns

    // Display the result
    $display("Test 1: iCtext = %h, iHashkey = %h, oResult = %h", iCtext, iHashkey, oResult);
    $stop;
end

endmodule