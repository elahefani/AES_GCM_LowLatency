module gfmul (
    input clk,
    input rst,
    input [0:127] iCtext,
    input [0:127] iHashkey,
    output reg [0:127] oResult
);

    wire [0:127] Z [0:128];
    wire [0:127] V [0:127];
    wire [0:127] iR;
    assign iR = {8'b1110_0001, 120'd0};
    assign V[0] = iHashkey;
    assign Z[0] = 128'd0;

    genvar i, j;
    generate
        for (i = 0; i < 127; i = i + 1)
            assign V[i+1] = {1'b0, V[i][0:126]} ^ (iR & {128{V[i][127]}});
        for (j = 0; j < 128; j = j + 1)
            assign Z[j+1] = Z[j] ^ (V[j] & {128{iCtext[j]}});
    endgenerate


    always @ (posedge clk or posedge rst) begin
        if (rst)
            oResult <= 0;
        else
            oResult = Z[128];
    end

endmodule

