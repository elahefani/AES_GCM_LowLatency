module AesGcmEnc (

   input clk,

   input rst,
   

   output reg keyUsed, // GCM tell the key generation module that the current key is no longer needed. Upon receiving this signal, key generator deasserts keyReady and starts generating the next key.

   input keyReady, // Key generator tells GCM that the next key is ready.

   input [127:0] key, // AES-128 key

   input txFull,

   output [127:0] txData,

   output txPush,

   output finish,

   input rxEmpty,

   input [127:0] rxData,

   output reg rxPop

);

reg [2:0] state;
reg [127:0] headerlen;
reg [127:0] payloadlen;
reg [127:0] iv;
reg [127:0] keyrec;


wire [127:0] aes_out [0:99];
reg [127:0] aes_in [0:99];
reg aes_start [0:99];
wire aes_done [0:99];
reg [127:0] headers [0:99];
reg [127:0] payloads [0:99];
reg [7:0] readheaderindex;
reg [7:0] readpayloadindex;
reg [7:0] writeheaderindex;
reg [7:0] writepayloadindex;


// genvar j;
// generate
//    for (j = 0; j < 1; j = j + 1) begin : aes_instances
//         aes aes_inst (
//             .k(keyrec), 
//             .pt(aes_in[j]), 
//             .ct(aes_out[j]), 
//             .kv(aes_start[j]), 
//             .ptv(aes_start[j]), 
//             .ctv(aes_done[j]),
//             .clk(clk), 
//             .rstn(~rst)
//         );
//     end
// endgenerate


aes aes_inst (
            .k(keyrec), 
            .pt(aes_in[0]), 
            .ct(aes_out[0]), 
            .kv(aes_start[0]), 
            .ptv(aes_start[0]), 
            .ctv(aes_done[0]),
            .clk(clk), 
            .rstn(~rst)
        );
wire [127:0] gf_result ;
reg gfreset;

gfmul gf128_mult_inst (
    .clk(clk),
    .rst(gfreset),
    .iCtext(keyrec),
    .iHashkey(iv),
    .oResult(gf_result)
);

reg [4:0]counter = 0;

integer i;

localparam startaes = 3'd0,
           readheaderlen = 3'd1,
           readpayloadlen = 3'd2,
           readheader = 3'd3,
           readpayload = 3'd4,
           waits = 3'd5;

reg switch = 1;
always @(posedge clk or posedge rst)begin
   counter = counter + 1;
   for (i = 0; i < 1; i = i + 1) begin
      aes_start[i] = 0;
   end  
   if(rst)begin
      switch = 1;
      state <= 3'd0;
      gfreset <= 1;
      headerlen <= 128'd0;
      
      payloadlen <= 128'd0;
      
      iv <= 128'd0;
      
      keyrec <= 128'd0;

      readheaderindex <= 0;
      writeheaderindex <= 0;
      
      readpayloadindex <= 0;
      writepayloadindex <= 0;

      for (i = 0; i < 1; i = i + 1) begin
         aes_start[i] <= 0;
      end
   end

   else begin
      rxPop <= 1;
      if(gfreset == 0)begin
         $display("gf_result = %h", gf_result);
         gfreset = 1;
      end

      if(aes_done[0])begin
            $display("aes_out[%d] = %h", 0, aes_out[0]);
            $stop;
      end
      case(state)
         startaes: begin
            iv = rxData;
            keyrec <= key;
            gfreset = 0;
            keyUsed <= 1;
            for (i = 0; i < 1; i = i + 1) begin
               aes_in[i] = iv + i; 
               // $display("%h" , aes_in[i]);
               aes_start[i] = 1;
            end            
            state <= readheaderlen;
         end
         readheaderlen: begin
            headerlen <= rxData - 3;
            state <= readpayloadlen;
         end
         readpayloadlen: begin
            payloadlen <= rxData;
            state <= readheader;
         end
         readheader:begin
            headers[readheaderindex] <= rxData;
            readheaderindex <= readheaderindex + 1;
            if(readheaderindex == headerlen)begin
               state <= readpayload;
            end
         end
         readpayload:begin
            payloads[readpayloadindex] <= rxData;
            readpayloadindex <= readpayloadindex + 1;
            if(readpayloadindex == payloadlen)begin
               state <= waits;
               // finish = 1;
            end
         end
         waits:begin

         end
      endcase
   end
end






endmodule

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
        clk = 0;
        rst = 1;
        keyReady = 0;
        key = 128'hfeffe9928665731c6d6a8f9467308308;
        txFull = 0;
        rxEmpty = 1;
        rxData = 128'hcafebabefacedbaddecaf88800000000;

        // Wait for global reset
        #10;
        rst = 0;

        // Test sequence
        keyReady = 1; key = 128'he7e3c4741a4c0182124d68f8b7e8d256;
        rxEmpty = 0; rxData = 128'h30052e2033024357f4e329a288106c68;
      //   #10 rxData = 128'h0123456789ABCDEF0123456700000000;
        // Add more test vectors as needed

        // Finish simulation
        #10;
      //   $stop;
    end

    // Clock generation
    always #5 clk = ~clk;

endmodule

/*-------------------------------------------------------------------------
 AES (128-bit, table S-box, encryption)

 File name   : aes_table_enc.v
 Version     : 1.0
 Created     : MAY/30/2012
 Last update : MAY/30/2012
 Desgined by : Toshihiro Katashita
 

 Copyright (C) 2012 AIST
 
 By using this code, you agree to the following terms and conditions.
 
 This code is copyrighted by AIST ("us").
 
 Permission is hereby granted to copy, reproduce, redistribute or
 otherwise use this code as long as: there is no monetary profit gained
 specifically from the use or reproduction of this code, it is not sold,
 rented, traded or otherwise marketed, and this copyright notice is
 included prominently in any copy made.
 
 We shall not be liable for any damages, including without limitation
 direct, indirect, incidental, special or consequential damages arising
 from the use of this code.
 
 When you publish any results arising from the use of this code, we will
 appreciate it if you can cite our webpage.
(http://www.risec.aist.go.jp/project/sasebo/)
 -------------------------------------------------------------------------*/


//================================================ aes
module aes
  (k, pt, ct, kv, ptv, ctv, clk, rstn);

   //------------------------------------------------
   input  [127:0] k;  // Key input
   input  [127:0] pt;  // Data input
   output [127:0] ct; // Data output
   input          kv; // Key input ready
   input          ptv; // Data input ready
   output         ctv; // Data output valid

   input          clk;  // System clock
   input          rstn; // Reset (Low active)

   //------------------------------------------------
   wire           EN = 1;   // AES circuit enable
   reg            BSY;  // Busy signal
   reg            Kvld;

   reg [127:0]    dat, key, rkey;
   wire [127:0]   dat_next, rkey_next;
   reg [9:0]      rnd;  
   reg [7:0]      rcon; 
   reg            sel;  // Indicate final round
   reg            ctv;
   wire           rst;
   
   //------------------------------------------------
   assign rst = ~rstn;
     
   always @(posedge clk or posedge rst) begin
      if (rst)     ctv <= 0;
      else if (EN) ctv <= sel;
   end

   always @(posedge clk or posedge rst) begin
      if (rst) Kvld <= 0;
      else if (EN) Kvld <= kv;
   end

   always @(posedge clk or posedge rst) begin
      if (rst) BSY <= 0;
      else if (EN) BSY <= ptv | |rnd[9:1] | sel;
   end
   
   AES_Core aes_core 
     (.din(dat),  .dout(dat_next),  .kin(rkey_next), .sel(sel));
   KeyExpantion keyexpantion 
     (.kin(rkey), .kout(rkey_next), .rcon(rcon));
   
   always @(posedge clk or posedge rst) begin
      if (rst)             rnd <= 10'b0000_0000_01;
      else if (EN) begin
         if (ptv)         rnd <= {rnd[8:0], rnd[9]};
         else if (~rnd[0]) rnd <= {rnd[8:0], rnd[9]};
      end
   end
   
   always @(posedge clk or posedge rst) begin
      if (rst)     sel <= 0;
      else if (EN) sel <= rnd[9];
   end
   
   always @(posedge clk or posedge rst) begin
      if (rst)                 dat <= 128'h0;
      else if (EN) begin
         if (ptv)             dat <= pt ^ (kv == 1 ? k : key);
         else if (~rnd[0]|sel) dat <= dat_next;
      end
   end
   assign ct = dat;
   
   always @(posedge clk or posedge rst) begin
      if (rst)     key <= 128'h0;
      else if (EN)
        if (kv)  key <= k;
   end

   always @(posedge clk or posedge rst) begin
      if (rst)         rkey <= 128'h0;
      else if (EN) begin
         if (kv)   rkey <= k;
         else if (rnd[0]) rkey <= key;
         else             rkey <= rkey_next;
      end
   end
   always @(posedge clk or posedge rst) begin
     if (rst)          rcon <= 8'h01;
     else if (EN) begin
        if (ptv)    rcon <= 8'h01;
        else if (~rnd[0]) rcon <= xtime(rcon);
     end
   end
   
   function [7:0] xtime;
      input [7:0] x;
      xtime = (x[7]==1'b0)? {x[6:0],1'b0} : {x[6:0],1'b0} ^ 8'h1B;
   endfunction

endmodule // aes



//================================================ KeyExpantion
module KeyExpantion (kin, kout, rcon);

   //------------------------------------------------
   input [127:0]  kin;
   output [127:0] kout;
   input [7:0] 	  rcon;

   //------------------------------------------------
   wire [31:0]    ws, wr, w0, w1, w2, w3;

   //------------------------------------------------
   SubBytes SB0 ({kin[23:16], kin[15:8], kin[7:0], kin[31:24]}, ws);
   assign wr = {(ws[31:24] ^ rcon), ws[23:0]};

   assign w0 = wr ^ kin[127:96];
   assign w1 = w0 ^ kin[95:64];
   assign w2 = w1 ^ kin[63:32];
   assign w3 = w2 ^ kin[31:0];

   assign kout = {w0, w1, w2, w3};

endmodule // KeyExpantion



//================================================ AES_Core
module AES_Core (din, dout, kin, sel);

   //------------------------------------------------
   input  [127:0] din, kin;
   input          sel;
   output [127:0] dout;
   
   //------------------------------------------------
   wire [31:0] st0, st1, st2, st3, // state
               sb0, sb1, sb2, sb3, // SubBytes
               sr0, sr1, sr2, sr3, // ShiftRows
               sc0, sc1, sc2, sc3, // MixColumns
               sk0, sk1, sk2, sk3; // AddRoundKey

   //------------------------------------------------
   // din -> state
   assign st0 = din[127:96];
   assign st1 = din[ 95:64];
   assign st2 = din[ 63:32];
   assign st3 = din[ 31: 0];

   // SubBytes
   SubBytes SB0 (st0, sb0);
   SubBytes SB1 (st1, sb1);
   SubBytes SB2 (st2, sb2);
   SubBytes SB3 (st3, sb3);

   // ShiftRows
   assign sr0 = {sb0[31:24], sb1[23:16], sb2[15: 8], sb3[ 7: 0]};
   assign sr1 = {sb1[31:24], sb2[23:16], sb3[15: 8], sb0[ 7: 0]};
   assign sr2 = {sb2[31:24], sb3[23:16], sb0[15: 8], sb1[ 7: 0]};
   assign sr3 = {sb3[31:24], sb0[23:16], sb1[15: 8], sb2[ 7: 0]};

   // MixColumns
   MixColumns MC0 (sr0, sc0);
   MixColumns MC1 (sr1, sc1);
   MixColumns MC2 (sr2, sc2);
   MixColumns MC3 (sr3, sc3);

   // AddRoundKey
   assign sk0 = (sel) ? sr0 ^ kin[127:96] : sc0 ^ kin[127:96];
   assign sk1 = (sel) ? sr1 ^ kin[ 95:64] : sc1 ^ kin[ 95:64];
   assign sk2 = (sel) ? sr2 ^ kin[ 63:32] : sc2 ^ kin[ 63:32];
   assign sk3 = (sel) ? sr3 ^ kin[ 31: 0] : sc3 ^ kin[ 31: 0];

   // state -> dout
   assign dout = {sk0, sk1, sk2, sk3};
endmodule // AES_Core



//================================================ MixColumns
module MixColumns(x, y);

   //------------------------------------------------
   input  [31:0]  x;
   output [31:0]  y;

   //------------------------------------------------
   wire [7:0]    a0, a1, a2, a3;
   wire [7:0]    b0, b1, b2, b3;

   assign a0 = x[31:24];
   assign a1 = x[23:16];
   assign a2 = x[15: 8];
   assign a3 = x[ 7: 0];

   assign b0 = xtime(a0);
   assign b1 = xtime(a1);
   assign b2 = xtime(a2);
   assign b3 = xtime(a3);

   assign y[31:24] =    b0 ^ a1^b1 ^ a2    ^ a3;
   assign y[23:16] = a0        ^b1 ^ a2^b2 ^ a3;
   assign y[15: 8] = a0    ^ a1        ^b2 ^ a3^b3;
   assign y[ 7: 0] = a0^b0 ^ a1    ^ a2        ^b3;
  
   function [7:0] xtime;
      input [7:0] x;
      xtime = (x[7]==1'b0)? {x[6:0],1'b0} : {x[6:0],1'b0} ^ 8'h1B;
   endfunction
   
endmodule // MixColumns



//================================================ SubBytes
module SubBytes (x, y);

   //------------------------------------------------
   input  [31:0] x;
   output [31:0] y;

   //------------------------------------------------
   assign y = {s(x[31:24]), s(x[23:16]), s(x[15:8]), s(x[7:0])};

   function [7:0] s;
      input [7:0] x;
      case (x)
        8'h00: s=8'h63;  8'h01: s=8'h7c;  8'h02: s=8'h77;  8'h03: s=8'h7b;
        8'h04: s=8'hf2;  8'h05: s=8'h6b;  8'h06: s=8'h6f;  8'h07: s=8'hc5;
        8'h08: s=8'h30;  8'h09: s=8'h01;  8'h0A: s=8'h67;  8'h0B: s=8'h2b;
        8'h0C: s=8'hfe;  8'h0D: s=8'hd7;  8'h0E: s=8'hab;  8'h0F: s=8'h76;
        
        8'h10: s=8'hca;  8'h11: s=8'h82;  8'h12: s=8'hc9;  8'h13: s=8'h7d;
        8'h14: s=8'hfa;  8'h15: s=8'h59;  8'h16: s=8'h47;  8'h17: s=8'hf0;
        8'h18: s=8'had;  8'h19: s=8'hd4;  8'h1A: s=8'ha2;  8'h1B: s=8'haf;
        8'h1C: s=8'h9c;  8'h1D: s=8'ha4;  8'h1E: s=8'h72;  8'h1F: s=8'hc0;
        
        8'h20: s=8'hb7;  8'h21: s=8'hfd;  8'h22: s=8'h93;  8'h23: s=8'h26;
        8'h24: s=8'h36;  8'h25: s=8'h3f;  8'h26: s=8'hf7;  8'h27: s=8'hcc;
        8'h28: s=8'h34;  8'h29: s=8'ha5;  8'h2A: s=8'he5;  8'h2B: s=8'hf1;
        8'h2C: s=8'h71;  8'h2D: s=8'hd8;  8'h2E: s=8'h31;  8'h2F: s=8'h15;
        
        8'h30: s=8'h04;  8'h31: s=8'hc7;  8'h32: s=8'h23;  8'h33: s=8'hc3;
        8'h34: s=8'h18;  8'h35: s=8'h96;  8'h36: s=8'h05;  8'h37: s=8'h9a;
        8'h38: s=8'h07;  8'h39: s=8'h12;  8'h3A: s=8'h80;  8'h3B: s=8'he2;
        8'h3C: s=8'heb;  8'h3D: s=8'h27;  8'h3E: s=8'hb2;  8'h3F: s=8'h75;
        
        8'h40: s=8'h09;  8'h41: s=8'h83;  8'h42: s=8'h2c;  8'h43: s=8'h1a;
        8'h44: s=8'h1b;  8'h45: s=8'h6e;  8'h46: s=8'h5a;  8'h47: s=8'ha0;
        8'h48: s=8'h52;  8'h49: s=8'h3b;  8'h4A: s=8'hd6;  8'h4B: s=8'hb3;
        8'h4C: s=8'h29;  8'h4D: s=8'he3;  8'h4E: s=8'h2f;  8'h4F: s=8'h84;
        
        8'h50: s=8'h53;  8'h51: s=8'hd1;  8'h52: s=8'h00;  8'h53: s=8'hed;
        8'h54: s=8'h20;  8'h55: s=8'hfc;  8'h56: s=8'hb1;  8'h57: s=8'h5b;
        8'h58: s=8'h6a;  8'h59: s=8'hcb;  8'h5A: s=8'hbe;  8'h5B: s=8'h39;
        8'h5C: s=8'h4a;  8'h5D: s=8'h4c;  8'h5E: s=8'h58;  8'h5F: s=8'hcf;
        
        8'h60: s=8'hd0;  8'h61: s=8'hef;  8'h62: s=8'haa;  8'h63: s=8'hfb;
        8'h64: s=8'h43;  8'h65: s=8'h4d;  8'h66: s=8'h33;  8'h67: s=8'h85;
        8'h68: s=8'h45;  8'h69: s=8'hf9;  8'h6A: s=8'h02;  8'h6B: s=8'h7f;
        8'h6C: s=8'h50;  8'h6D: s=8'h3c;  8'h6E: s=8'h9f;  8'h6F: s=8'ha8;
        
        8'h70: s=8'h51;  8'h71: s=8'ha3;  8'h72: s=8'h40;  8'h73: s=8'h8f;
        8'h74: s=8'h92;  8'h75: s=8'h9d;  8'h76: s=8'h38;  8'h77: s=8'hf5;
        8'h78: s=8'hbc;  8'h79: s=8'hb6;  8'h7A: s=8'hda;  8'h7B: s=8'h21;
        8'h7C: s=8'h10;  8'h7D: s=8'hff;  8'h7E: s=8'hf3;  8'h7F: s=8'hd2;
        
        8'h80: s=8'hcd;  8'h81: s=8'h0c;  8'h82: s=8'h13;  8'h83: s=8'hec;
        8'h84: s=8'h5f;  8'h85: s=8'h97;  8'h86: s=8'h44;  8'h87: s=8'h17;
        8'h88: s=8'hc4;  8'h89: s=8'ha7;  8'h8A: s=8'h7e;  8'h8B: s=8'h3d;
        8'h8C: s=8'h64;  8'h8D: s=8'h5d;  8'h8E: s=8'h19;  8'h8F: s=8'h73;
        
        8'h90: s=8'h60;  8'h91: s=8'h81;  8'h92: s=8'h4f;  8'h93: s=8'hdc;
        8'h94: s=8'h22;  8'h95: s=8'h2a;  8'h96: s=8'h90;  8'h97: s=8'h88;
        8'h98: s=8'h46;  8'h99: s=8'hee;  8'h9A: s=8'hb8;  8'h9B: s=8'h14;
        8'h9C: s=8'hde;  8'h9D: s=8'h5e;  8'h9E: s=8'h0b;  8'h9F: s=8'hdb;
        
        8'hA0: s=8'he0;  8'hA1: s=8'h32;  8'hA2: s=8'h3a;  8'hA3: s=8'h0a;
        8'hA4: s=8'h49;  8'hA5: s=8'h06;  8'hA6: s=8'h24;  8'hA7: s=8'h5c;
        8'hA8: s=8'hc2;  8'hA9: s=8'hd3;  8'hAA: s=8'hac;  8'hAB: s=8'h62;
        8'hAC: s=8'h91;  8'hAD: s=8'h95;  8'hAE: s=8'he4;  8'hAF: s=8'h79;
        
        8'hB0: s=8'he7;  8'hB1: s=8'hc8;  8'hB2: s=8'h37;  8'hB3: s=8'h6d;
        8'hB4: s=8'h8d;  8'hB5: s=8'hd5;  8'hB6: s=8'h4e;  8'hB7: s=8'ha9;
        8'hB8: s=8'h6c;  8'hB9: s=8'h56;  8'hBA: s=8'hf4;  8'hBB: s=8'hea;
        8'hBC: s=8'h65;  8'hBD: s=8'h7a;  8'hBE: s=8'hae;  8'hBF: s=8'h08;
        
        8'hC0: s=8'hba;  8'hC1: s=8'h78;  8'hC2: s=8'h25;  8'hC3: s=8'h2e;
        8'hC4: s=8'h1c;  8'hC5: s=8'ha6;  8'hC6: s=8'hb4;  8'hC7: s=8'hc6;
        8'hC8: s=8'he8;  8'hC9: s=8'hdd;  8'hCA: s=8'h74;  8'hCB: s=8'h1f;
        8'hCC: s=8'h4b;  8'hCD: s=8'hbd;  8'hCE: s=8'h8b;  8'hCF: s=8'h8a;

        8'hD0: s=8'h70;  8'hD1: s=8'h3e;  8'hD2: s=8'hb5;  8'hD3: s=8'h66;
        8'hD4: s=8'h48;  8'hD5: s=8'h03;  8'hD6: s=8'hf6;  8'hD7: s=8'h0e;
        8'hD8: s=8'h61;  8'hD9: s=8'h35;  8'hDA: s=8'h57;  8'hDB: s=8'hb9;
        8'hDC: s=8'h86;  8'hDD: s=8'hc1;  8'hDE: s=8'h1d;  8'hDF: s=8'h9e;
        
        8'hE0: s=8'he1;  8'hE1: s=8'hf8;  8'hE2: s=8'h98;  8'hE3: s=8'h11;
        8'hE4: s=8'h69;  8'hE5: s=8'hd9;  8'hE6: s=8'h8e;  8'hE7: s=8'h94;
        8'hE8: s=8'h9b;  8'hE9: s=8'h1e;  8'hEA: s=8'h87;  8'hEB: s=8'he9;
        8'hEC: s=8'hce;  8'hED: s=8'h55;  8'hEE: s=8'h28;  8'hEF: s=8'hdf;
        
        8'hF0: s=8'h8c;  8'hF1: s=8'ha1;  8'hF2: s=8'h89;  8'hF3: s=8'h0d;
        8'hF4: s=8'hbf;  8'hF5: s=8'he6;  8'hF6: s=8'h42;  8'hF7: s=8'h68;
        8'hF8: s=8'h41;  8'hF9: s=8'h99;  8'hFA: s=8'h2d;  8'hFB: s=8'h0f;
        8'hFC: s=8'hb0;  8'hFD: s=8'h54;  8'hFE: s=8'hbb;  8'hFF: s=8'h16;
      endcase
   endfunction

endmodule // SubBytes


module gfmul(
input clk,
input rst,
input [0:127] iCtext,
input [0:127] iHashkey,
output reg [0:127] oResult
);


reg [0:127] Z [1:128];
reg [0:127] V [0:127];

reg [0:127] iR = {8'b1110_0001, 120'd0};
always @ (posedge clk or posedge rst)begin
    if(rst)begin
        oResult <= 0;
    end
    else begin
        V[0] = iHashkey;
        V[1] = {1'b0, V[0][0:126]} ^ (iR & {128{V[0][127]}});
        V[2] = {1'b0, V[1][0:126]} ^ (iR & {128{V[1][127]}});
        V[3] = {1'b0, V[2][0:126]} ^ (iR & {128{V[2][127]}});
        V[4] = {1'b0, V[3][0:126]} ^ (iR & {128{V[3][127]}});
        V[5] = {1'b0, V[4][0:126]} ^ (iR & {128{V[4][127]}});
        V[6] = {1'b0, V[5][0:126]} ^ (iR & {128{V[5][127]}});
        V[7] = {1'b0, V[6][0:126]} ^ (iR & {128{V[6][127]}});
        V[8] = {1'b0, V[7][0:126]} ^ (iR & {128{V[7][127]}});
        V[9] = {1'b0, V[8][0:126]} ^ (iR & {128{V[8][127]}});
        V[10] = {1'b0, V[9][0:126]} ^ (iR & {128{V[9][127]}});
        V[11] = {1'b0, V[10][0:126]} ^ (iR & {128{V[10][127]}});
        V[12] = {1'b0, V[11][0:126]} ^ (iR & {128{V[11][127]}});
        V[13] = {1'b0, V[12][0:126]} ^ (iR & {128{V[12][127]}});
        V[14] = {1'b0, V[13][0:126]} ^ (iR & {128{V[13][127]}});
        V[15] = {1'b0, V[14][0:126]} ^ (iR & {128{V[14][127]}});
        V[16] = {1'b0, V[15][0:126]} ^ (iR & {128{V[15][127]}});
        V[17] = {1'b0, V[16][0:126]} ^ (iR & {128{V[16][127]}});
        V[18] = {1'b0, V[17][0:126]} ^ (iR & {128{V[17][127]}});
        V[19] = {1'b0, V[18][0:126]} ^ (iR & {128{V[18][127]}});
        V[20] = {1'b0, V[19][0:126]} ^ (iR & {128{V[19][127]}});
        V[21] = {1'b0, V[20][0:126]} ^ (iR & {128{V[20][127]}});
        V[22] = {1'b0, V[21][0:126]} ^ (iR & {128{V[21][127]}});
        V[23] = {1'b0, V[22][0:126]} ^ (iR & {128{V[22][127]}});
        V[24] = {1'b0, V[23][0:126]} ^ (iR & {128{V[23][127]}});
        V[25] = {1'b0, V[24][0:126]} ^ (iR & {128{V[24][127]}});
        V[26] = {1'b0, V[25][0:126]} ^ (iR & {128{V[25][127]}});
        V[27] = {1'b0, V[26][0:126]} ^ (iR & {128{V[26][127]}});
        V[28] = {1'b0, V[27][0:126]} ^ (iR & {128{V[27][127]}});
        V[29] = {1'b0, V[28][0:126]} ^ (iR & {128{V[28][127]}});
        V[30] = {1'b0, V[29][0:126]} ^ (iR & {128{V[29][127]}});
        V[31] = {1'b0, V[30][0:126]} ^ (iR & {128{V[30][127]}});
        V[32] = {1'b0, V[31][0:126]} ^ (iR & {128{V[31][127]}});
        V[33] = {1'b0, V[32][0:126]} ^ (iR & {128{V[32][127]}});
        V[34] = {1'b0, V[33][0:126]} ^ (iR & {128{V[33][127]}});
        V[35] = {1'b0, V[34][0:126]} ^ (iR & {128{V[34][127]}});
        V[36] = {1'b0, V[35][0:126]} ^ (iR & {128{V[35][127]}});
        V[37] = {1'b0, V[36][0:126]} ^ (iR & {128{V[36][127]}});
        V[38] = {1'b0, V[37][0:126]} ^ (iR & {128{V[37][127]}});
        V[39] = {1'b0, V[38][0:126]} ^ (iR & {128{V[38][127]}});
        V[40] = {1'b0, V[39][0:126]} ^ (iR & {128{V[39][127]}});
        V[41] = {1'b0, V[40][0:126]} ^ (iR & {128{V[40][127]}});
        V[42] = {1'b0, V[41][0:126]} ^ (iR & {128{V[41][127]}});
        V[43] = {1'b0, V[42][0:126]} ^ (iR & {128{V[42][127]}});
        V[44] = {1'b0, V[43][0:126]} ^ (iR & {128{V[43][127]}});
        V[45] = {1'b0, V[44][0:126]} ^ (iR & {128{V[44][127]}});
        V[46] = {1'b0, V[45][0:126]} ^ (iR & {128{V[45][127]}});
        V[47] = {1'b0, V[46][0:126]} ^ (iR & {128{V[46][127]}});
        V[48] = {1'b0, V[47][0:126]} ^ (iR & {128{V[47][127]}});
        V[49] = {1'b0, V[48][0:126]} ^ (iR & {128{V[48][127]}});
        V[50] = {1'b0, V[49][0:126]} ^ (iR & {128{V[49][127]}});
        V[51] = {1'b0, V[50][0:126]} ^ (iR & {128{V[50][127]}});
        V[52] = {1'b0, V[51][0:126]} ^ (iR & {128{V[51][127]}});
        V[53] = {1'b0, V[52][0:126]} ^ (iR & {128{V[52][127]}});
        V[54] = {1'b0, V[53][0:126]} ^ (iR & {128{V[53][127]}});
        V[55] = {1'b0, V[54][0:126]} ^ (iR & {128{V[54][127]}});
        V[56] = {1'b0, V[55][0:126]} ^ (iR & {128{V[55][127]}});
        V[57] = {1'b0, V[56][0:126]} ^ (iR & {128{V[56][127]}});
        V[58] = {1'b0, V[57][0:126]} ^ (iR & {128{V[57][127]}});
        V[59] = {1'b0, V[58][0:126]} ^ (iR & {128{V[58][127]}});
        V[60] = {1'b0, V[59][0:126]} ^ (iR & {128{V[59][127]}});
        V[61] = {1'b0, V[60][0:126]} ^ (iR & {128{V[60][127]}});
        V[62] = {1'b0, V[61][0:126]} ^ (iR & {128{V[61][127]}});
        V[63] = {1'b0, V[62][0:126]} ^ (iR & {128{V[62][127]}});
        V[64] = {1'b0, V[63][0:126]} ^ (iR & {128{V[63][127]}});
        V[65] = {1'b0, V[64][0:126]} ^ (iR & {128{V[64][127]}});
        V[66] = {1'b0, V[65][0:126]} ^ (iR & {128{V[65][127]}});
        V[67] = {1'b0, V[66][0:126]} ^ (iR & {128{V[66][127]}});
        V[68] = {1'b0, V[67][0:126]} ^ (iR & {128{V[67][127]}});
        V[69] = {1'b0, V[68][0:126]} ^ (iR & {128{V[68][127]}});
        V[70] = {1'b0, V[69][0:126]} ^ (iR & {128{V[69][127]}});
        V[71] = {1'b0, V[70][0:126]} ^ (iR & {128{V[70][127]}});
        V[72] = {1'b0, V[71][0:126]} ^ (iR & {128{V[71][127]}});
        V[73] = {1'b0, V[72][0:126]} ^ (iR & {128{V[72][127]}});
        V[74] = {1'b0, V[73][0:126]} ^ (iR & {128{V[73][127]}});
        V[75] = {1'b0, V[74][0:126]} ^ (iR & {128{V[74][127]}});
        V[76] = {1'b0, V[75][0:126]} ^ (iR & {128{V[75][127]}});
        V[77] = {1'b0, V[76][0:126]} ^ (iR & {128{V[76][127]}});
        V[78] = {1'b0, V[77][0:126]} ^ (iR & {128{V[77][127]}});
        V[79] = {1'b0, V[78][0:126]} ^ (iR & {128{V[78][127]}});
        V[80] = {1'b0, V[79][0:126]} ^ (iR & {128{V[79][127]}});
        V[81] = {1'b0, V[80][0:126]} ^ (iR & {128{V[80][127]}});
        V[82] = {1'b0, V[81][0:126]} ^ (iR & {128{V[81][127]}});
        V[83] = {1'b0, V[82][0:126]} ^ (iR & {128{V[82][127]}});
        V[84] = {1'b0, V[83][0:126]} ^ (iR & {128{V[83][127]}});
        V[85] = {1'b0, V[84][0:126]} ^ (iR & {128{V[84][127]}});
        V[86] = {1'b0, V[85][0:126]} ^ (iR & {128{V[85][127]}});
        V[87] = {1'b0, V[86][0:126]} ^ (iR & {128{V[86][127]}});
        V[88] = {1'b0, V[87][0:126]} ^ (iR & {128{V[87][127]}});
        V[89] = {1'b0, V[88][0:126]} ^ (iR & {128{V[88][127]}});
        V[90] = {1'b0, V[89][0:126]} ^ (iR & {128{V[89][127]}});
        V[91] = {1'b0, V[90][0:126]} ^ (iR & {128{V[90][127]}});
        V[92] = {1'b0, V[91][0:126]} ^ (iR & {128{V[91][127]}});
        V[93] = {1'b0, V[92][0:126]} ^ (iR & {128{V[92][127]}});
        V[94] = {1'b0, V[93][0:126]} ^ (iR & {128{V[93][127]}});
        V[95] = {1'b0, V[94][0:126]} ^ (iR & {128{V[94][127]}});
        V[96] = {1'b0, V[95][0:126]} ^ (iR & {128{V[95][127]}});
        V[97] = {1'b0, V[96][0:126]} ^ (iR & {128{V[96][127]}});
        V[98] = {1'b0, V[97][0:126]} ^ (iR & {128{V[97][127]}});
        V[99] = {1'b0, V[98][0:126]} ^ (iR & {128{V[98][127]}});
        V[100] = {1'b0, V[99][0:126]} ^ (iR & {128{V[99][127]}});
        V[101] = {1'b0, V[100][0:126]} ^ (iR & {128{V[100][127]}});
        V[102] = {1'b0, V[101][0:126]} ^ (iR & {128{V[101][127]}});
        V[103] = {1'b0, V[102][0:126]} ^ (iR & {128{V[102][127]}});
        V[104] = {1'b0, V[103][0:126]} ^ (iR & {128{V[103][127]}});
        V[105] = {1'b0, V[104][0:126]} ^ (iR & {128{V[104][127]}});
        V[106] = {1'b0, V[105][0:126]} ^ (iR & {128{V[105][127]}});
        V[107] = {1'b0, V[106][0:126]} ^ (iR & {128{V[106][127]}});
        V[108] = {1'b0, V[107][0:126]} ^ (iR & {128{V[107][127]}});
        V[109] = {1'b0, V[108][0:126]} ^ (iR & {128{V[108][127]}});
        V[110] = {1'b0, V[109][0:126]} ^ (iR & {128{V[109][127]}});
        V[111] = {1'b0, V[110][0:126]} ^ (iR & {128{V[110][127]}});
        V[112] = {1'b0, V[111][0:126]} ^ (iR & {128{V[111][127]}});
        V[113] = {1'b0, V[112][0:126]} ^ (iR & {128{V[112][127]}});
        V[114] = {1'b0, V[113][0:126]} ^ (iR & {128{V[113][127]}});
        V[115] = {1'b0, V[114][0:126]} ^ (iR & {128{V[114][127]}});
        V[116] = {1'b0, V[115][0:126]} ^ (iR & {128{V[115][127]}});
        V[117] = {1'b0, V[116][0:126]} ^ (iR & {128{V[116][127]}});
        V[118] = {1'b0, V[117][0:126]} ^ (iR & {128{V[117][127]}});
        V[119] = {1'b0, V[118][0:126]} ^ (iR & {128{V[118][127]}});
        V[120] = {1'b0, V[119][0:126]} ^ (iR & {128{V[119][127]}});
        V[121] = {1'b0, V[120][0:126]} ^ (iR & {128{V[120][127]}});
        V[122] = {1'b0, V[121][0:126]} ^ (iR & {128{V[121][127]}});
        V[123] = {1'b0, V[122][0:126]} ^ (iR & {128{V[122][127]}});
        V[124] = {1'b0, V[123][0:126]} ^ (iR & {128{V[123][127]}});
        V[125] = {1'b0, V[124][0:126]} ^ (iR & {128{V[124][127]}});
        V[126] = {1'b0, V[125][0:126]} ^ (iR & {128{V[125][127]}});
        V[127] = {1'b0, V[126][0:126]} ^ (iR & {128{V[126][127]}});
        Z[1] =  128'd0 ^ (V[0] & {128{iCtext[0]}});
        Z[2] = Z[1] ^ (V[1] & {128{iCtext[1]}});
        Z[3] = Z[2] ^ (V[2] & {128{iCtext[2]}});
        Z[4] = Z[3] ^ (V[3] & {128{iCtext[3]}});
        Z[5] = Z[4] ^ (V[4] & {128{iCtext[4]}});
        Z[6] = Z[5] ^ (V[5] & {128{iCtext[5]}});
        Z[7] = Z[6] ^ (V[6] & {128{iCtext[6]}});
        Z[8] = Z[7] ^ (V[7] & {128{iCtext[7]}});
        Z[9] = Z[8] ^ (V[8] & {128{iCtext[8]}});
        Z[10] = Z[9] ^ (V[9] & {128{iCtext[9]}});
        Z[11] = Z[10] ^ (V[10] & {128{iCtext[10]}});
        Z[12] = Z[11] ^ (V[11] & {128{iCtext[11]}});
        Z[13] = Z[12] ^ (V[12] & {128{iCtext[12]}});
        Z[14] = Z[13] ^ (V[13] & {128{iCtext[13]}});
        Z[15] = Z[14] ^ (V[14] & {128{iCtext[14]}});
        Z[16] = Z[15] ^ (V[15] & {128{iCtext[15]}});
        Z[17] = Z[16] ^ (V[16] & {128{iCtext[16]}});
        Z[18] = Z[17] ^ (V[17] & {128{iCtext[17]}});
        Z[19] = Z[18] ^ (V[18] & {128{iCtext[18]}});
        Z[20] = Z[19] ^ (V[19] & {128{iCtext[19]}});
        Z[21] = Z[20] ^ (V[20] & {128{iCtext[20]}});
        Z[22] = Z[21] ^ (V[21] & {128{iCtext[21]}});
        Z[23] = Z[22] ^ (V[22] & {128{iCtext[22]}});
        Z[24] = Z[23] ^ (V[23] & {128{iCtext[23]}});
        Z[25] = Z[24] ^ (V[24] & {128{iCtext[24]}});
        Z[26] = Z[25] ^ (V[25] & {128{iCtext[25]}});
        Z[27] = Z[26] ^ (V[26] & {128{iCtext[26]}});
        Z[28] = Z[27] ^ (V[27] & {128{iCtext[27]}});
        Z[29] = Z[28] ^ (V[28] & {128{iCtext[28]}});
        Z[30] = Z[29] ^ (V[29] & {128{iCtext[29]}});
        Z[31] = Z[30] ^ (V[30] & {128{iCtext[30]}});
        Z[32] = Z[31] ^ (V[31] & {128{iCtext[31]}});
        Z[33] = Z[32] ^ (V[32] & {128{iCtext[32]}});
        Z[34] = Z[33] ^ (V[33] & {128{iCtext[33]}});
        Z[35] = Z[34] ^ (V[34] & {128{iCtext[34]}});
        Z[36] = Z[35] ^ (V[35] & {128{iCtext[35]}});
        Z[37] = Z[36] ^ (V[36] & {128{iCtext[36]}});
        Z[38] = Z[37] ^ (V[37] & {128{iCtext[37]}});
        Z[39] = Z[38] ^ (V[38] & {128{iCtext[38]}});
        Z[40] = Z[39] ^ (V[39] & {128{iCtext[39]}});
        Z[41] = Z[40] ^ (V[40] & {128{iCtext[40]}});
        Z[42] = Z[41] ^ (V[41] & {128{iCtext[41]}});
        Z[43] = Z[42] ^ (V[42] & {128{iCtext[42]}});
        Z[44] = Z[43] ^ (V[43] & {128{iCtext[43]}});
        Z[45] = Z[44] ^ (V[44] & {128{iCtext[44]}});
        Z[46] = Z[45] ^ (V[45] & {128{iCtext[45]}});
        Z[47] = Z[46] ^ (V[46] & {128{iCtext[46]}});
        Z[48] = Z[47] ^ (V[47] & {128{iCtext[47]}});
        Z[49] = Z[48] ^ (V[48] & {128{iCtext[48]}});
        Z[50] = Z[49] ^ (V[49] & {128{iCtext[49]}});
        Z[51] = Z[50] ^ (V[50] & {128{iCtext[50]}});
        Z[52] = Z[51] ^ (V[51] & {128{iCtext[51]}});
        Z[53] = Z[52] ^ (V[52] & {128{iCtext[52]}});
        Z[54] = Z[53] ^ (V[53] & {128{iCtext[53]}});
        Z[55] = Z[54] ^ (V[54] & {128{iCtext[54]}});
        Z[56] = Z[55] ^ (V[55] & {128{iCtext[55]}});
        Z[57] = Z[56] ^ (V[56] & {128{iCtext[56]}});
        Z[58] = Z[57] ^ (V[57] & {128{iCtext[57]}});
        Z[59] = Z[58] ^ (V[58] & {128{iCtext[58]}});
        Z[60] = Z[59] ^ (V[59] & {128{iCtext[59]}});
        Z[61] = Z[60] ^ (V[60] & {128{iCtext[60]}});
        Z[62] = Z[61] ^ (V[61] & {128{iCtext[61]}});
        Z[63] = Z[62] ^ (V[62] & {128{iCtext[62]}});
        Z[64] = Z[63] ^ (V[63] & {128{iCtext[63]}});
        Z[65] = Z[64] ^ (V[64] & {128{iCtext[64]}});
        Z[66] = Z[65] ^ (V[65] & {128{iCtext[65]}});
        Z[67] = Z[66] ^ (V[66] & {128{iCtext[66]}});
        Z[68] = Z[67] ^ (V[67] & {128{iCtext[67]}});
        Z[69] = Z[68] ^ (V[68] & {128{iCtext[68]}});
        Z[70] = Z[69] ^ (V[69] & {128{iCtext[69]}});
        Z[71] = Z[70] ^ (V[70] & {128{iCtext[70]}});
        Z[72] = Z[71] ^ (V[71] & {128{iCtext[71]}});
        Z[73] = Z[72] ^ (V[72] & {128{iCtext[72]}});
        Z[74] = Z[73] ^ (V[73] & {128{iCtext[73]}});
        Z[75] = Z[74] ^ (V[74] & {128{iCtext[74]}});
        Z[76] = Z[75] ^ (V[75] & {128{iCtext[75]}});
        Z[77] = Z[76] ^ (V[76] & {128{iCtext[76]}});
        Z[78] = Z[77] ^ (V[77] & {128{iCtext[77]}});
        Z[79] = Z[78] ^ (V[78] & {128{iCtext[78]}});
        Z[80] = Z[79] ^ (V[79] & {128{iCtext[79]}});
        Z[81] = Z[80] ^ (V[80] & {128{iCtext[80]}});
        Z[82] = Z[81] ^ (V[81] & {128{iCtext[81]}});
        Z[83] = Z[82] ^ (V[82] & {128{iCtext[82]}});
        Z[84] = Z[83] ^ (V[83] & {128{iCtext[83]}});
        Z[85] = Z[84] ^ (V[84] & {128{iCtext[84]}});
        Z[86] = Z[85] ^ (V[85] & {128{iCtext[85]}});
        Z[87] = Z[86] ^ (V[86] & {128{iCtext[86]}});
        Z[88] = Z[87] ^ (V[87] & {128{iCtext[87]}});
        Z[89] = Z[88] ^ (V[88] & {128{iCtext[88]}});
        Z[90] = Z[89] ^ (V[89] & {128{iCtext[89]}});
        Z[91] = Z[90] ^ (V[90] & {128{iCtext[90]}});
        Z[92] = Z[91] ^ (V[91] & {128{iCtext[91]}});
        Z[93] = Z[92] ^ (V[92] & {128{iCtext[92]}});
        Z[94] = Z[93] ^ (V[93] & {128{iCtext[93]}});
        Z[95] = Z[94] ^ (V[94] & {128{iCtext[94]}});
        Z[96] = Z[95] ^ (V[95] & {128{iCtext[95]}});
        Z[97] = Z[96] ^ (V[96] & {128{iCtext[96]}});
        Z[98] = Z[97] ^ (V[97] & {128{iCtext[97]}});
        Z[99] = Z[98] ^ (V[98] & {128{iCtext[98]}});
        Z[100] = Z[99] ^ (V[99] & {128{iCtext[99]}});
        Z[101] = Z[100] ^ (V[100] & {128{iCtext[100]}});
        Z[102] = Z[101] ^ (V[101] & {128{iCtext[101]}});
        Z[103] = Z[102] ^ (V[102] & {128{iCtext[102]}});
        Z[104] = Z[103] ^ (V[103] & {128{iCtext[103]}});
        Z[105] = Z[104] ^ (V[104] & {128{iCtext[104]}});
        Z[106] = Z[105] ^ (V[105] & {128{iCtext[105]}});
        Z[107] = Z[106] ^ (V[106] & {128{iCtext[106]}});
        Z[108] = Z[107] ^ (V[107] & {128{iCtext[107]}});
        Z[109] = Z[108] ^ (V[108] & {128{iCtext[108]}});
        Z[110] = Z[109] ^ (V[109] & {128{iCtext[109]}});
        Z[111] = Z[110] ^ (V[110] & {128{iCtext[110]}});
        Z[112] = Z[111] ^ (V[111] & {128{iCtext[111]}});
        Z[113] = Z[112] ^ (V[112] & {128{iCtext[112]}});
        Z[114] = Z[113] ^ (V[113] & {128{iCtext[113]}});
        Z[115] = Z[114] ^ (V[114] & {128{iCtext[114]}});
        Z[116] = Z[115] ^ (V[115] & {128{iCtext[115]}});
        Z[117] = Z[116] ^ (V[116] & {128{iCtext[116]}});
        Z[118] = Z[117] ^ (V[117] & {128{iCtext[117]}});
        Z[119] = Z[118] ^ (V[118] & {128{iCtext[118]}});
        Z[120] = Z[119] ^ (V[119] & {128{iCtext[119]}});
        Z[121] = Z[120] ^ (V[120] & {128{iCtext[120]}});
        Z[122] = Z[121] ^ (V[121] & {128{iCtext[121]}});
        Z[123] = Z[122] ^ (V[122] & {128{iCtext[122]}});
        Z[124] = Z[123] ^ (V[123] & {128{iCtext[123]}});
        Z[125] = Z[124] ^ (V[124] & {128{iCtext[124]}});
        Z[126] = Z[125] ^ (V[125] & {128{iCtext[125]}});
        Z[127] = Z[126] ^ (V[126] & {128{iCtext[126]}});
        Z[128] = Z[127] ^ (V[127] & {128{iCtext[127]}});
        oResult = Z[128];
      end
   end
endmodule


