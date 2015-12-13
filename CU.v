// CU.v
// Jesse Dyer and Kurt Miller

// given clk, IR, BEQout, CUmod outputs control signals
module CUmod(clk, opcode, RS, RT, RD, BEQout,
             incPC, InstRead, ldIR, ldPC, MemRead, MemWrite, RegRead, RegWrite, S, T);
   input clk;
   input [5:0] opcode;
   input [4:0] RS, RT, RD;
   output incPC, InstRead, ldIR, BEQout, ldPC, MemRead, MemWrite, RegRead, RegWrite;
   output [0:7] S, T;

   wire [0:7] S, T;  // which step and which type of inst

// clocking unary signals S0, S1, S2, ...
   SequencerMod my_sequencer(clk, S);  // S is unary S[0:15]

// from 3 bits in IR, map to unary T0, T1, T2, ..., T7
   DecoderMod my_decoder(opcode, T);       // T is unary T[0:7]
   
// define signals with S and T
   SignalDefinerMod my_signal_definer(S, T, BEQout, incPC, InstRead, ldIR, ldPC, MemRead, MemWrite, RegRead, RegWrite);

endmodule

// carry out signal definitions
module SignalDefinerMod(S, T, BEQout,
             incPC, InstRead, ldIR, ldPC, MemRead, MemWrite, RegRead, RegWrite);
   input [0:7] S, T;
   input BEQout;
   output incPC, InstRead, ldIR, ldPC, MemRead, MemWrite, RegRead, RegWrite;

   wire   regWriteInst;
   or(regWriteInst,T[1],T[2],T[3],T[4],T[5]);
   
   assign InstRead = S[0];    // IF  S0: InstRead    PC has addr 0 initially, read inst
   assign ldIR = S[1];        //     S1: ldIR
   assign RegRead = S[2];     // ID  S2: RegRead     Registers read for getting operands
                              // EX  S3: (nothing)   ALU operates on operands
   and(MemRead,T[5],S[4]);    // MEM S4: MemRead     if "lw" inst
   and(MemWrite,T[6],S[4]);   //     S4: MemWrite    if "sw" inst
   and(RegWrite,S[5],regWriteInst);   // WB  S5:  RegWrite  if inst is T1~T5
   assign incPC = S[5];               // S5: incPC       don't do this too soon or too late
   and(ldPC, BEQout,S[6],T[7]);       // S6: ldPC        if S6, T7 ("beq" inst), and BEQout
endmodule

module SequencerMod(clk, S); // unary sequencer
   input clk;
   output [0:7] S;

   reg [0:7] S;

   initial S = 8'b0000_0001; // S initially

   always @(posedge clk) begin
      S[0] <= S[7];           // ripple '1' thru
      S[1] <= S[0];
      S[2] <= S[1];
      S[3] <= S[2];
      S[4] <= S[3];
      S[5] <= S[4];
      S[6] <= S[5];
      S[7] <= S[6];
   end
   
endmodule

module DecoderMod(opcode, T); // B binary decoded into T unary
   input [5:0] opcode;
   output [0:7] T;

   wire [2:0] B, invB;
   assign B = opcode[2:0]; // trim down to just last 3 bits

   not(invB[2], B[2]);
   not(invB[1], B[1]);
   not(invB[0], B[0]);

   and(T[0], invB[2], invB[1], invB[0]); // T[0] = 000 (B) = nop
   and(T[1], invB[2], invB[1],    B[0]); // T[1] = 001 (B) = add
   and(T[2], invB[2],    B[1], invB[0]); // T[2] = 010 (B) = sub
   and(T[3], invB[2],    B[1],    B[0]); // T[3] = 011 (B) = or
   and(T[4],    B[2], invB[1], invB[0]); // T[4] = 100 (B) = and
   and(T[5],    B[2], invB[1],    B[0]); // T[5] = 101 (B) = lw
   and(T[6],    B[2],    B[1], invB[0]); // T[6] = 110 (B) = sw
   and(T[7],    B[2],    B[1],    B[0]); // T[7] = 111 (B) = beq
   
endmodule

