`timescale 1 ns / 1 ns
module TEST;

    // Inputs
    reg clk;
    reg rst;
    reg keyReady;
    reg [127:0] key;
    reg txFull;
    reg rxEmpty;
    reg [127:0] rxData;

    // Outputs
    wire keyUsed;
    wire [127:0] txData;
    wire txPush;
    wire finish;
    wire rxPop;

    // Instantiate the Unit Under Test (UUT)
    AesGcmEnc uut (
        .clk(clk), 
        .rst(rst), 
        .keyUsed(keyUsed), 
        .keyReady(keyReady), 
        .key(key), 
        .txFull(txFull), 
        .txData(txData), 
        .txPush(txPush), 
        .finish(finish), 
        .rxEmpty(rxEmpty), 
        .rxData(rxData), 
        .rxPop(rxPop)
    );

    initial begin
        // Initialize Inputs
        $monitor("Time: %0t | txData: %h | finish: %h", $time, txData,finish);
        clk = 0;
        rst = 1;
        keyReady = 0;
        key = 128'hfeffe9928665731c6d6a8f9467308308;
        txFull = 0;
        rxEmpty = 1;
        rxData = 128'hcafebabefacedbaddecaf88800000000;

        // Wait for global reset
        #1000;
        rst = 0;

        // Test sequence
        keyReady = 1; key = 128'hfeffe9928665731c6d6a8f9467308308;
        rxEmpty = 0; rxData = 128'hcafebabefacedbaddecaf88800000000;
        #1000;
        rxEmpty = 0; rxData = 128'h5;
        #1000;
        rxData = 128'h3;
        #1000;
        rxData = 128'hfeedfacedeadbeeffeedfacedeadbeef;
        #1000;
        rxData = 128'habaddad2abaddad2abaddad2abaddad2;
        #1000;
        rxData = 128'hd9313225f88406e5a55909c5aff5269a;
        #1000;
        rxData = 128'h86a7a9531534f7da2e4c303d8a318a72;
        #1000;
        rxData = 128'h1c3c0c95956809532fcf0e2449a6b525;
        wait (finish == 1);
        wait (finish == 0);
        $stop;
    end

    // Clock generation
    always #500 clk = ~clk;

endmodule