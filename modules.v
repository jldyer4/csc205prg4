// modules.v
//
// ALUmod (free-handed)
// RegistersMod
// DataCacheMod
// InstCacheMod
// PCmod (free-handed)
// IRmod
// BEQmod (for "beq" inst, compare two registers, calc branch addr)

module ALUmod(opcode, operand1, operand2, imm_value, ALUout); // free-form ALU here
   input [5:0] opcode;
   input [31:0] operand1, operand2;
   input [15:0] imm_value;
   output [31:0] ALUout;
   
   assign ALUout = (opcode == 1) ? operand1 + operand2 : 
		   (opcode == 2) ? operand1 - operand2 :
                   (opcode == 3) ? operand1 | operand2 :  
		   (opcode == 4) ? operand1 & operand2 :
		   (opcode == 7) ? operand1 + imm_value : 0;  

   // TODO: (1) fix this so that imm_value is treated as signed.
   //       (2) Can we / should we set ALUout to 'z' or some other value
   //           in the error case? (Rather than 0, as I have it now.)
endmodule

// specially-made for branch type of inst, e.g., "beq $0, $1, 20"
module BEQmod(RSout, RTout, BEQout, PCout, imm_value, branch_addr);
   input [31:0] RSout, RTout, PCout;
   input [15:0] imm_value;        // signed 12-bit offset (based on PC)
   output BEQout;
   output [31:0] branch_addr;

   assign BEQout = RSout == RTout; // If RS == RT, branch
   
   assign branch_addr = PCout + imm_value; 
   // Usually we would use the ALU to compute the branch target,
   // but that's not possible given the way the demo wires things.
   // Plus, in the comments at the top of the file it indicates that
   
endmodule

module RegistersMod(opcode, RS, RT, RD, Read, Write,
                    RSout, RTout, ALUout, data, R0, R1, R2, R3);
   input Read, Write;
   input [5:0] opcode;
   input [4:0] RS, RT, RD;
   input [31:0] ALUout, data; // ALU output or data to write back
   output [31:0] RSout, RTout, R0, R1, R2, R3;

   reg [31:0] 	 RSout, RTout;
   
   reg [31:0] 	 registers [31:0];

   assign R0 = registers[0];
   assign R1 = registers[1];
   assign R2 = registers[2];
   assign R3 = registers[3];
   
   always @(posedge Read) begin
      RSout = registers[RS];
      RTout = registers[RT];
   end
   
   wire invMiddleOp;
   not(invMiddleOp, opcode[1]);
   wire bWriteData; // write the "data" input only when using the lw instruction
   and(bWriteData, opcode[2], invMiddleOp, opcode[0]); 
   // The preceding mess could be avoided if we passed in the "T" field
   // but his implementation doesn't do it that way so neither will I.
   
   always @(posedge Write) begin
      registers[RD] = bWriteData ? data : ALUout;
   end
endmodule

module DataCacheMod(Read, Write, addr, input_data, output_buffer);
   input Read, Write;
   input [31:0] addr, input_data;
   output [31:0] output_buffer;
   reg [31:0] 	 output_buffer;
   
   reg [31:0] cache [15:0];

   initial cache[3] = -1;  // only this word initialized

   always @(posedge Read) output_buffer = cache[addr];

   always @(posedge Write) cache[addr] = input_data;
endmodule

module InstCacheMod(Read, addr, output_buffer);
   input Read;
   input [31:0] addr;
   output [31:0] output_buffer;
   reg [31:0] 	 output_buffer;
   
   
   reg [31:0] cache [0:15];

   always @(posedge Read) output_buffer = cache[addr];

   initial $readmemb("MIPS-inst.txt", cache);
endmodule

module PCmod(incr, addr, ld, new_addr);
   input incr;  
   input [31:0] new_addr;
   input 	ld;
   
   output [31:0] addr;  
   reg [31:0] addr;

   initial addr = 0;
   always @(posedge incr) addr = addr + 1;

   always @(posedge ld) addr = new_addr;

endmodule

module IRmod (inst, ld, memory);  // for both AR and IR
   input ld;
   output [31:0] inst, memory;

   reg [31:0] memory;  

   always @(posedge ld) memory = inst; 

endmodule

