// GF(2^128) multiplier in Verilog
module GF_128_MUL (
    input [127:0] a,        // 128-bit input a
    input [127:0] b,        // 128-bit input b
    output reg [127:0] result   // 128-bit result
);
    // Reduction polynomial: x^128 + x^7 + x^2 + x + 1
    parameter [127:0] REDUCTION_POLY = 128'h87; // (Binary: 10000111)

    reg [255:0] product;  // Intermediate product (256 bits for shifting)
    reg [127:0] temp_a;
    reg [127:0] temp_b;
    integer i;

    always @(*) begin
        // Initialize temporary values
        temp_a = a;
        temp_b = b;
        product = 0;

        // Multiply in GF(2^128) using shift and conditional XOR
        for (i = 0; i < 128; i = i + 1) begin
            if (temp_b[0] == 1'b1) begin
                product[127:0] = product[127:0] ^ temp_a;
            end

            // Shift temp_a left, and reduce if MSB is set
            if (temp_a[127] == 1'b1) begin
                temp_a = (temp_a << 1) ^ REDUCTION_POLY;
            end else begin
                temp_a = temp_a << 1;
            end

            // Shift temp_b right
            temp_b = temp_b >> 1;
        end

        // Final result is the lower 128 bits of the product
        result = product[127:0];
    end
endmodule



module TB_GF128_Mul;

    reg [127:0] A, B;
    wire [127:0] C;

    GF_128_MUL gf128_mul_inst (
        .a(A),
        .b(B),
        .result(C)
    );

    initial begin
        // Test inputs
        A = 128'h00000000000000000000000000000001;
        B = 128'h80000000000000000000000000000000;
        #10; // Wait for computation
        $display("Test 1");
        $display("A: %h", A);
        $display("B: %h", B);
        $display("C (Result): %h", C);

        // Additional test case
        A = 128'h1234567890ABCDEF1234567890ABCDEF;
        B = 128'hFEDCBA0987654321FEDCBA0987654321;
        #10; // Wait for computation
        $display("Test 2");
        $display("A: %h", A);
        $display("B: %h", B);
        $display("C (Result): %h", C);

        $stop;
    end
endmodule
