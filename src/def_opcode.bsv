
typedef Bit#(6)  Opcode;

Opcode  r_type = 6'b000000;
Bit#(6) funct_SLL     =  6'b000000;
Bit#(6) funct_SRL     =  6'b000010;
Bit#(6) funct_SRA     =  6'b000011;
Bit#(6) funct_SLLV    =  6'b000100;
Bit#(6) funct_SRLV    =  6'b000110;
Bit#(6) funct_SRAV    =  6'b000111;
Bit#(6) funct_ADD     =  6'b100000;
Bit#(6) funct_ADDU    =  6'b100001;
Bit#(6) funct_SUB     =  6'b100010; 
Bit#(6) funct_SUBU    =  6'b100011; 
Bit#(6) funct_AND     =  6'b100100; 
Bit#(6) funct_OR      =  6'b100101; 
Bit#(6) funct_XOR     =  6'b100110; 
Bit#(6) funct_NOR     =  6'b100111; 
Bit#(6) funct_SLT     =  6'b101010; 
Bit#(6) funct_SLTU    =  6'b101011; 
Bit#(6) funct_MULT    =  6'b011000; 
Bit#(6) funct_MULTU   =  6'b011001; 
Bit#(6) funct_DIV     =  6'b011010; 
Bit#(6) funct_DIVU    =  6'b011011; 
Bit#(6) funct_MFHI    =  6'b010000;
Bit#(6) funct_MTHI    =  6'b010001;
Bit#(6) funct_MFLO    =  6'b010010;
Bit#(6) funct_MTLO    =  6'b010011;
Bit#(6) funct_JR      =  6'b001000;
Bit#(6) funct_JALR    =  6'b001001;
Bit#(6) funct_SYSCALL =  6'b001100;
Bit#(6) funct_BREAK   =  6'b001101;

// 011100
Bit#(6) funct_CLO    =  6'b100001 ;
Bit#(6) funct_CLZ    =  6'b100000 ;
Bit#(6) funct_MADD   =  6'b000000 ;
Bit#(6) funct_MADDU  =  6'b000001 ;
Bit#(6) funct_MSUB   =  6'b000100 ;
Bit#(6) funct_MSUBU  =  6'b000101 ;
Bit#(6) funct_MUL    =  6'b000010 ;

// 000000
Bit#(6) funct_TGE  = 6'b110000 ;
Bit#(6) funct_TGEU = 6'b110001 ;
Bit#(6) funct_TLT  = 6'b110010 ;
Bit#(6) funct_TLTU = 6'b110011 ;
Bit#(6) funct_TEQ  = 6'b110100 ;
Bit#(6) funct_TNE  = 6'b110110 ;

// 000001
Bit#(5) rt_BLTZ   = 5'b00000 ;
Bit#(5) rt_BGEZ   = 5'b00001 ;
Bit#(5) rt_BLTZAL = 5'b10000 ;
Bit#(5) rt_BGEZAL = 5'b10001 ;
Bit#(5) rt_TGEI   = 5'b01000 ;
Bit#(5) rt_TGEIU  = 5'b01001 ;
Bit#(5) rt_TLTI   = 5'b01010 ;
Bit#(5) rt_TLTIU  = 5'b01011 ;
Bit#(5) rt_TEQI   = 5'b01100 ;
Bit#(5) rt_TNEI   = 5'b01110 ;


Opcode opcode_addi  = 6'b001000;
Opcode opcode_addiu = 6'b001001;
Opcode opcode_slti  = 6'b001010;
Opcode opcode_sltiu = 6'b001011;
Opcode opcode_andi  = 6'b001100;
Opcode opcode_ori   = 6'b001101;
Opcode opcode_xori  = 6'b001110;
Opcode opcode_lui   = 6'b001111;

Opcode opcode_lb         = 6'b100000;
Opcode opcode_lh         = 6'b100001;
Opcode opcode_lbu        = 6'b100100;
Opcode opcode_lhu        = 6'b100101;
Opcode opcode_lw         = 6'b100011;

Opcode opcode_sb         = 6'b101000;
Opcode opcode_sh         = 6'b101001;
Opcode opcode_sw         = 6'b101011;

Opcode opcode_beq        = 6'b000100;
Opcode opcode_bne        = 6'b000101;
Opcode opcode_bgez       = 6'b000001;
Opcode opcode_bgtz       = 6'b000111;
Opcode opcode_blez       = 6'b000110;
Opcode opcode_bltz       = 6'b000001;

Opcode opcode_j          = 6'b000010;
Opcode opcode_jal        = 6'b000011;





  
