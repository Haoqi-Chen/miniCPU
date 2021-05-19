package stageID;

import RegFile :: *;

import def_opcode :: *;
import def_types :: *;


interface StageID_ifc;
//method Action showRF ();
    method Action step(
            Instr instr,
            Data_IF_ID data_if_id,
            CtrlUnitInfo ctrl_info,
            WbInfo wwb, HiloWbInfo whilowb,
            Bool icache_miss
        );
    method Bool getPauseReq(
            Instr instr, WbInfo ewb, WbInfo mwb, WbInfo wwb
        );
    method Data_ID_EX out(
            Instr instr, Bool pause,
            WbInfo ewb, 
            WbInfo mwb, 
            WbInfo wwb,
            HiloWbInfo ehilowb,
            HiloWbInfo mhilowb,
            HiloWbInfo whilowb
    );
endinterface
(* synthesize *)
module mkStageID(StageID_ifc);
    //流水线寄存器
    Reg#(Data_IF_ID) reg_if_id <- mkReg(Data_IF_ID{
        nop: True,
        pc: 'b0,
        exc: None
    });
    Reg#(Maybe#(Instr)) saved_inst <- mkReg(tagged Invalid);

    


    //寄存器文件和hilo
    RegFile#(RegName, Data) rf <- mkRegFileFull;//Load("../../../../../../rtl/myCPU/RFinit.txt");

    
        //mkRegFile(0, 31);
    Reg#(Data) reg_hi <- mkReg('h0);
    Reg#(Data) reg_lo <- mkReg(0);

    Reg#(RegName) regname <- mkReg(0);

    //hi lo的转发，返回经过转发的(hi, lo)对
    function Tuple2#(Data, Data) safeReadhilo(
            HiloWbInfo ehilowb,
            HiloWbInfo mhilowb,
            HiloWbInfo whilowb
        );
        let rhi = reg_hi;
        if(ehilowb.hiwr) rhi = ehilowb.hid;
        else if(mhilowb.hiwr) rhi = mhilowb.hid;
        else if(whilowb.hiwr) rhi = whilowb.hid;
        let rlo = reg_lo;
        if(ehilowb.lowr) rlo = ehilowb.lod;
        else if(mhilowb.lowr) rlo = mhilowb.lod;
        else if(whilowb.lowr) rlo = whilowb.lod;
        return tuple2(rhi, rlo);
    endfunction

    function Bool fn_rsvExc(Instr rinstr);
        case(rinstr[31:26])
            // 立即数算术 
            opcode_addi, opcode_addiu, opcode_slti, opcode_sltiu, opcode_andi, opcode_ori, opcode_xori, opcode_lui, opcode_lb, opcode_lh, opcode_lbu, opcode_lhu, opcode_lw, opcode_sb, opcode_sh, opcode_sw, opcode_beq, opcode_bne, opcode_bgtz, opcode_blez, opcode_j, opcode_jal: return False;
            r_type:
            case(rinstr[5:0])
                funct_MFHI, funct_MFLO, funct_MTHI, funct_MTLO, funct_JR, funct_JALR, funct_SYSCALL, funct_BREAK, funct_MULT, funct_MULTU, funct_DIV, funct_DIVU, funct_SLL, funct_SRL, funct_SRA, funct_SLLV, funct_SRLV, funct_SRAV, funct_ADD, funct_ADDU, funct_SUB, funct_SUBU, funct_AND, funct_OR, funct_XOR, funct_NOR, funct_SLT, funct_SLTU, funct_TGE, funct_TGEU, funct_TLT, 
                funct_TLTU, funct_TEQ , funct_TNE : return False;
                default: return True;
            endcase
            6'b000001:
            case(rinstr[20:16])
                // bltzal, bgezal
                rt_BLTZ, rt_BGEZ, rt_BLTZAL, rt_BGEZAL, rt_TGEI, rt_TGEIU, rt_TLTI,
                rt_TLTIU , rt_TEQI, rt_TNEI  : return False;
                default: return True;
            endcase
            6'b010000: begin
                if(rinstr[5:0] == 6'b011000) //eret
                    return False;
                else if(rinstr[25:21] == 'b00000) //mfc0
                    return False;
                else if(rinstr[25:21] == 'b00100) //mtc0
                    return False;
                else return True;
            end
            6'b011100: case(rinstr[5:0])
                funct_CLO, funct_CLZ, funct_MADD, funct_MADDU, funct_MSUB,
                funct_MSUBU, funct_MUL : return False;
                default: return True;
            endcase
            default: return True;
        endcase
    endfunction

    //寄存器文件的读写转发
    //若当前可以读出值val，则返回Just val，否则返回Nothing 
    function Maybe#(Data) safeRead(
            RegName num, WbInfo ewb, WbInfo mwb, WbInfo wwb
        );
        if(ewb.wr && num == ewb.num) begin
            if(ewb.valid) return tagged Valid ewb.data;
            else return tagged Invalid;
        end
        else if(mwb.wr && num == mwb.num) begin
            if(mwb.valid) return tagged Valid mwb.data;
            else return tagged Invalid;
        end
        else if(wwb.wr && num == wwb.num) begin
            if(wwb.valid) return tagged Valid wwb.data;
            else return tagged Invalid;
        end
        else return tagged Valid (num == 0? 0: rf.sub(num));
    endfunction

    function ALUctr getALUctr(Instr rinstr);
        ALUctr aluctr = ?;
        case(rinstr[31:26])
            opcode_addi  : aluctr = ALUctr_add  ;
            opcode_addiu : aluctr = ALUctr_addu ;
            opcode_andi  : aluctr = ALUctr_and  ;
            opcode_ori   : aluctr = ALUctr_or   ;
            opcode_xori  : aluctr = ALUctr_xor  ;
            opcode_lui   : aluctr = ALUctr_sll  ;
            opcode_slti  : aluctr = ALUctr_slt  ;
            opcode_sltiu : aluctr = ALUctr_sltu ;

            opcode_beq   : aluctr = ALUctr_eq   ;
            opcode_bne   : aluctr = ALUctr_neq  ;
            opcode_bgtz  : aluctr = ALUctr_gtz  ;
            opcode_blez  : aluctr = ALUctr_lez  ;


            
            6'b000001: begin
                case(rinstr[20:16])
                    rt_BLTZ, rt_BLTZAL: aluctr = ALUctr_ltz ;
                    rt_BGEZ, rt_BGEZAL: aluctr = ALUctr_gez ;
                    rt_TGEI  : aluctr = ALUctr_ge   ;
                    rt_TGEIU : aluctr = ALUctr_geu  ;
                    rt_TLTI  : aluctr = ALUctr_lt   ;
                    rt_TLTIU : aluctr = ALUctr_ltu  ;
                    rt_TEQI  : aluctr = ALUctr_eq   ;
                    rt_TNEI  : aluctr = ALUctr_neq  ;
                endcase
            end
            
            r_type: case(rinstr[5:0])
                funct_ADD   : aluctr  =  ALUctr_add   ;
                funct_ADDU  : aluctr  =  ALUctr_addu  ;
                funct_SUB   : aluctr  =  ALUctr_sub   ;
                funct_SUBU  : aluctr  =  ALUctr_subu  ;
                funct_AND   : aluctr  =  ALUctr_and   ;
                funct_NOR   : aluctr  =  ALUctr_nor   ;
                funct_OR    : aluctr  =  ALUctr_or    ;
                funct_XOR   : aluctr  =  ALUctr_xor   ;
                funct_SLT   : aluctr  =  ALUctr_slt   ;
                funct_SLTU  : aluctr  =  ALUctr_sltu  ;
                funct_SLL   : aluctr  =  ALUctr_sll   ;
                funct_SRL   : aluctr  =  ALUctr_srl   ;
                funct_SRA   : aluctr  =  ALUctr_sra   ;
                funct_SLLV  : aluctr  =  ALUctr_sll   ;
                funct_SRLV  : aluctr  =  ALUctr_srl   ;
                funct_SRAV  : aluctr  =  ALUctr_sra   ;
                funct_MULT  : aluctr  =  ALUctr_mult  ;
                funct_MULTU : aluctr  =  ALUctr_multu ;
                funct_DIV   : aluctr  =  ALUctr_div   ;
                funct_DIVU  : aluctr  =  ALUctr_divu  ;

                funct_TGE   : aluctr  =  ALUctr_ge    ;
                funct_TGEU  : aluctr  =  ALUctr_geu   ;
                funct_TLT   : aluctr  =  ALUctr_lt    ;
                funct_TLTU  : aluctr  =  ALUctr_ltu   ;
                funct_TEQ   : aluctr  =  ALUctr_eq    ;
                funct_TNE   : aluctr  =  ALUctr_neq   ;

                default     : aluctr  =  ALUctr_addu  ;
            endcase
            
            6'b011100: case(rinstr[5:0])
                funct_CLO   : aluctr = ALUctr_clo   ;
                funct_CLZ   : aluctr = ALUctr_clz   ;
                funct_MADD  : aluctr = ALUctr_madd  ;
                funct_MADDU : aluctr = ALUctr_maddu ;
                funct_MSUB  : aluctr = ALUctr_msub  ;
                funct_MSUBU : aluctr = ALUctr_msubu ;
                funct_MUL   : aluctr = ALUctr_mul   ;
            endcase
            default: aluctr = ALUctr_addu;
        endcase
        return aluctr;
    endfunction
    

    //流水线寄存器，寄存器文件，hilo的更新
    method Action step(
            Instr instr,
            Data_IF_ID data_if_id,
            CtrlUnitInfo ctrl_info,
            WbInfo wwb, HiloWbInfo whilowb,
            Bool icache_miss
        );
        if(ctrl_info.pause && !icache_miss && saved_inst == tagged Invalid)
            saved_inst <= tagged Valid instr;
        else if(!ctrl_info.pause)
            saved_inst <= tagged Invalid;
        //流水线寄存器

        if(!ctrl_info.pause)begin
            reg_if_id <= Data_IF_ID{
                nop: data_if_id.nop || ctrl_info.bub,
                pc: data_if_id.pc,
                exc: data_if_id.exc
            };
        end
	else reg_if_id <= Data_IF_ID{
                nop: reg_if_id.nop || ctrl_info.bub,
                pc: reg_if_id.pc,
                exc: reg_if_id.exc
            };
        //寄存器文件
        if(wwb.wr) rf.upd(wwb.num, wwb.data);
        //hi & lo
        if(whilowb.hiwr) reg_hi <= whilowb.hid;
        if(whilowb.lowr) reg_lo <= whilowb.lod;
    endmethod
/*
method Action showRF ();
	regname <= regname + 1;
	if(regname == 0) $display("hi: %0h, lo: %0h", reg_hi, reg_lo);
	$display(fshow(regname), ": ", fshow(rf.sub(regname)));
endmethod
*/
    

    //向下一级
    method Data_ID_EX out(
            Instr instr, Bool pause,
            WbInfo ewb, WbInfo mwb, WbInfo wwb,
            HiloWbInfo ehilowb,
            HiloWbInfo mhilowb,
            HiloWbInfo whilowb
        );
        let rinstr = fromMaybe(instr, saved_inst);
        let rs = rinstr[25:21];
        let rt = rinstr[20:16];
        let maybebusa = safeRead(rs, ewb, mwb, wwb);
        let maybebusb = safeRead(rt, ewb, mwb, wwb);
        let hilod = safeReadhilo(ehilowb, mhilowb, whilowb);
        // let rsvExc = (
        //         rinstr[31:29] == 3'b011
        // ||    rinstr[31:30] == 2'b11
        // ||(   rinstr[31:29] == 3'b010
        //     && rinstr[28:26] != 3'b000)
        // ||(   rinstr[31:29] == 3'b100
        //     && (rinstr[27:26] == 2'b10
        //     || rinstr[28:26] == 3'b111) )
        // ||(   rinstr[31:29] == 3'b101
        //     && rinstr[28:26]== 3'b010
        //     && rinstr[28]    == 1'b1  )
        // );
        let rsvExc = fn_rsvExc(rinstr);
        Bool instrIsSyscall = (rinstr[31:26] == 'b000000 &&
            rinstr[5:0] == 'b001100);
        Bool instrIsBreak = (rinstr[31:26] == 'b000000 &&
            rinstr[5:0] == 'b001101);
        ExcSignal exc = 
	    (reg_if_id.exc == BadFAddr)? BadFAddr:
            (rsvExc)? RsvInstr: 
            (instrIsSyscall)? Sys:
            (instrIsBreak)? Brk: reg_if_id.exc;

        return Data_ID_EX{
            nop: reg_if_id.nop,// && (rinstr == 'b0 || reg_if_id.nop),
            pc: reg_if_id.pc,
            instr: rinstr,
            busa: fromMaybe(rf.sub(rs), maybebusa),
            busb: fromMaybe(rf.sub(rt), maybebusb),
            hid: tpl_1(hilod),
            lod: tpl_2(hilod),
            aluctr: getALUctr(rinstr),
            exc: exc
        };
    endmethod

    

    method Bool getPauseReq(
            Instr instr, WbInfo ewb, WbInfo mwb, WbInfo wwb
        );
        let rinstr = fromMaybe(instr, saved_inst);
        let needRs = 
                rinstr[31:29] == 'b001 &&
                rinstr[28:26] != 'b111 //立即数算术
            ||  rinstr[31:26] == 'b0 &&
                (   rinstr[5:3] == 'b100 //加减与或等
                ||  rinstr[5:1] == 'b10101 //条件置位
                ||  rinstr[5:2] == 'b0001 //寄存器移位
                ||  rinstr[5:2] == 'b0110 //乘除
                ||  rinstr[5:1] =='b00100 // 寄存器跳转
                ||  rinstr[5:1] == 'b01001) //mfhilo指令
            ||  rinstr[31] == 'b1 //存取指令
            ||  rinstr[31:28] == 'b0001 //分支
            ||  rinstr[31:26] == 'b000010; //链接分支
        let needRt = 
                rinstr[31:26] == 'b0 &&
                (   rinstr[5:3] == 'b100 //加减与或等
                ||  rinstr[5:1] == 'b10101 //条件置位
                ||  rinstr[5:2] == 'b000 //移位
                ||  rinstr[5:2] == 'b0110) //乘除
            ||  rinstr[31:29] == 'b101 //存值
            ||  rinstr[31:27] == 'b00010 //beq, bne
            ||  rinstr[31:26] == 'b010000 &&
                rinstr[23] == 'b1; //mtc0
        let rsvExc = fn_rsvExc(rinstr);
        
        RegName rs = rinstr[25:21];
        RegName rt = rinstr[20:16];

        let x = safeRead(rs, ewb, mwb, wwb);
        let y = safeRead(rt, ewb, mwb, wwb);
        return !reg_if_id.nop && reg_if_id.exc == None && !rsvExc && (
            (needRs && x == tagged Invalid) ||
            (needRt && y == tagged Invalid)
        );
    endmethod
endmodule

endpackage