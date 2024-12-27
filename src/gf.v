module GF_128_MUL (
    input [127:0] a,        // 128-bit input a
    input [127:0] b,        // 128-bit input b
    output [127:0] result   // 128-bit result
);
    // Reduction polynomial: x^128 + x^7 + x^2 + x + 1
    parameter [127:0] REDUCTION_POLY = 128'h100000000000000000000000000000087;

    wire [255:0] partial_products [0:127]; // Partial products for each bit of b
    wire [255:0] sum_all; // XOR of all partial products

    genvar i;
    generate
        for (i = 0; i < 128; i = i + 1) begin : generate_partial_products
            assign partial_products[i] = b[i] ? (a << i) : 256'd0;
        end
    endgenerate

    // XOR all partial products to compute sum_all
    assign sum_all = partial_products[0] ^ partial_products[1] ^ partial_products[2] ^ partial_products[127];

    // Reduction step
    reg [127:0] reduced_result;
    integer j;
    always @(*) begin
        reduced_result = sum_all[127:0]; // Start with lower 128 bits
        for (j = 255; j >= 128; j = j - 1) begin
            if (sum_all[j]) begin
                reduced_result = reduced_result ^ (REDUCTION_POLY << (j - 128));
            end
        end
    end

    assign result = reduced_result;

endmodule

module TB_GF_128_MUL;

    reg [127:0] A, B;
    wire [127:0] C;

    GF_128_MUL gf128_mul_inst (
        .a(A),
        .b(B),
        .result(C)
    );

    initial begin
        $display("Testing GF(2^128) Multiplier");

        // Test 1
        A = 128'h00000000000000000000000000000001;
        B = 128'h80000000000000000000000000000000;
        #1;
        $display("Test 1");
        $display("A: %h", A);
        $display("B: %h", B);
        $display("C: %h", C);

        // Test 2
        A = 128'h1234567890ABCDEF1234567890ABCDEF;
        B = 128'hFEDCBA0987654321FEDCBA0987654321;
        #1;
        $display("Test 2");
        $display("A: %h", A);
        $display("B: %h", B);
        $display("C: %h", C);

        // Test 3: A or B is zero
        A = 128'h00000000000000000000000000000000;
        B = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        #1;
        $display("Test 3");
        $display("A: %h", A);
        $display("B: %h", B);
        $display("C: %h", C);

        // Test 4: Both inputs random
        A = 128'h1A2B3C4D5E6F708192A3B4C5D6E7F800;
        B = 128'h8F9E0D1C2B3A4958576768594A3B2C1D;
        #1;
        $display("Test 4");
        $display("A: %h", A);
        $display("B: %h", B);
        $display("C: %h", C);

        $stop;
    end
endmodule