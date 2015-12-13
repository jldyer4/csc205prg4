// main.v
// Jesse Dyer and Kurt Miller

`include "CU.v"            // control unit
`include "modules.v"       // PC, IR, InstCache

module ClockMod(clk);      // clock generator
   output clk;
   reg clk;

   initial #115 $finish;

   initial begin
      #2;
      forever begin
         #1;
         clk = 0;
         #1;
         clk = 1;
      end
   end
endmodule

module main();                    // runtime test here
   wire [31:0] inst_addr, inst, IRout, write_data, data, branch_addr,
               RSout, RTout, ALUout, R0, R1, R2, R3;
   wire [0:7] S, T;               // CU's sequence/inst type (to monitor)
// control signals
   wire InstRead, incPC, ldIR, BEQout, ldPC, MemRead, MemWrite, RegRead, RegWrite;

   wire [5:0] opcode;
   wire [4:0] RS, RT, RD;
   wire [15:0] imm_value;
   assign opcode = inst[31:26];   // parts of an inst
   assign RS = inst[25:21];
   assign RT = inst[20:16];
   assign RD = inst[15:11];
   assign imm_value = inst[15:0];

   PCmod myPC(incPC, inst_addr, ldPC, branch_addr);
   InstCacheMod myInstCache(InstRead, inst_addr, inst);
   IRmod myIR(inst, ldIR, IRout);

   RegistersMod myRegisters(opcode, RS, RT, RD, RegRead, RegWrite,
                            RSout, RTout, ALUout, data, R0, R1, R2, R3);

   ALUmod myALU(opcode, RSout, RTout, imm_value, ALUout);

   DataCacheMod myDataCache(MemRead, MemWrite, ALUout, RTout, data);

   BEQmod myBEQ(RSout, RTout, BEQout, inst_addr, imm_value, branch_addr);

   ClockMod myClk(clk);

   CUmod myCU(clk, opcode, RS, RT, RD, BEQout,
              incPC, InstRead, ldIR, ldPC, MemRead, MemWrite, RegRead, RegWrite, S, T);

   initial begin
$display("                   i   I");
$display("                   m   n     M M R R");
$display("           o       m   s     e e e e");
$display("           p       | i t     m m g g");
$display("           c       v n R l l R W R W");
$display("    c      o       a c e d d e r e r                                                                         B");
$display("    l inst d R R R l P a I P a i a i                                                                         E brnh");
$display("tim k addr e S T D u C d R C d t d t S0~S7    R0       R1       R2       R3       ALUout   data     T0-7     Q addr");
$display("-e- - ---- --------e - - - - - e - e -------- -------- -------- -------- -------- -------- -------- -------- - --------");
$monitor("%3d %b %4d %0d-%0d-%0d-%0d-%0d %b %b %b %b %b %b %b %b %b %x %x %x %x %x %x %b %b %x",
$time, clk, inst_addr, opcode, RS, RT, RD, imm_value,
       incPC, InstRead, ldIR, ldPC, MemRead, MemWrite, RegRead, RegWrite,
       S, R0, R1, R2, R3, ALUout, data, T, BEQout, branch_addr);
   end
endmodule

