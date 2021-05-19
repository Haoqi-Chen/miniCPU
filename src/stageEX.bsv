package stageEX;

import def_opcode :: *;
import def_types :: *;
import alu :: *;

interface StageEX_ifc;
    method Action step(
            Data_ID_EX data_id_ex,
            CtrlUnitInfo ctrl_info
        );
    method Tuple4#(Bool, ALUctr, Data, Data) toMCALU();
    method MemReq toDmem(Bool wrn, Bool pause, Bool exc);
    method Data_EX_MEM out(Bit#(64) mcResult, Bool mcfinish);
    method Bool getPauseReq(Bool mcfinish);
endinterface
(* synthesize *)
module mkStageEX(StageEX_ifc);
    //流水线寄存器
    Reg#(Data_ID_EX) reg_id_ex <- mkReg(Data_ID_EX{
        nop: True,
        pc: 'b0,
        instr: 32'b0,
        busa: 'b0,
        busb: 'b0,
        hid: 'b0,
        lod: 'b0,
        aluctr: ALUctr_addu,
        exc: None
    });

    //ALU
    ALU_ifc alu <- mkALU;

    //Reg#(Data) cnt <- mkReg(0);

    Bool signExt = reg_id_ex.instr[31:28] != 4'b0011;
    Bit#(32) imm = 
        signExt?
        {(reg_id_ex.instr[15]==1?16'hffff:16'b0), reg_id_ex.instr[15:0]}:
        {16'b0, reg_id_ex.instr[15:0]};
    Bool aluaIs16 = (reg_id_ex.instr[31:26] == 6'b001111);
    Bool aluaIsSa = reg_id_ex.instr[31:26] == r_type && 
        reg_id_ex.instr[5:2] == 4'b0000;
    Bool alubIsImm = 
        reg_id_ex.instr[31:29] == 'b001 ||
        reg_id_ex.instr[31] == 'b1;
    Data alua = 
        aluaIs16?
            32'd16:
        aluaIsSa?
            {27'b0, reg_id_ex.instr[10:6]}:
        //otherwise?
            reg_id_ex.busa;
    Data alub = alubIsImm? imm: reg_id_ex.busb;

    Bool rwIs31 = (
                    reg_id_ex.instr[31:26]=='b000001
                ||  reg_id_ex.instr[31:26]=='b000011
            );
    Bool rwIsRt = (
                reg_id_ex.instr[31:29]=='b001
            ||  reg_id_ex.instr[31:29]=='b100
            ||      reg_id_ex.instr[31:25] == 'b0100000
                && !(reg_id_ex.instr[23] == 'b1)
        );
    Bool buswIsPc8 = (
                reg_id_ex.instr[31:26] ==  6'b000001
                && reg_id_ex.instr[20] == 'b1
            ||  reg_id_ex.instr[31:26] == 6'b000011
            ||      reg_id_ex.instr[31:26] == 6'b000000
                &&  reg_id_ex.instr[5:0] == 6'b001001
        );
    Bool instrIsMfhi = 
        (reg_id_ex.instr[31:26]==6'b000000 &&
        reg_id_ex.instr[5:0]==6'b010000);
    Bool instrIsMflo = 
        (reg_id_ex.instr[31:26]==6'b000000 &&
        reg_id_ex.instr[5:0]==6'b010010);
    Bool instrIsMfc0 = 
        (reg_id_ex.instr[31:26]==6'b010000 &&
        reg_id_ex.instr[25:23]==3'b000);
    Bool instrIsStore = reg_id_ex.instr[31:29] == 3'b101;
    Bool instrIsLoad = reg_id_ex.instr[31:29] == 3'b100;
    Bool wenIsW = reg_id_ex.instr[28:26] == 3'b011;
    Bool wenIsH = reg_id_ex.instr[27:26] == 2'b01;
    
    
    


    let ctr = reg_id_ex.aluctr;
    Bool start = !reg_id_ex.nop && reg_id_ex.exc == None && (
        ctr == ALUctr_mult ||
        ctr == ALUctr_multu||
        (ctr == ALUctr_div ||
        ctr == ALUctr_divu) && reg_id_ex.busb != 0);

    

    function ALUout_t aluout();
        return alu.calc(ctr, alua, alub);
    endfunction

    Data memaddr = reg_id_ex.busa + signExtend(reg_id_ex.instr[15:0]);
    Bool mAddrExc = (!reg_id_ex.nop) && (
            instrIsStore || instrIsLoad) && (
            (wenIsH && memaddr[0] != 1'b0) ||
            (wenIsW && memaddr[1:0] != 2'b00)
        );
    Bool instrIsSwl = reg_id_ex.instr[31:26] == 'b101010;
    Bool instrIsSwr = reg_id_ex.instr[31:26] == 'b101110;
    Bit#(4) be = 
        instrIsSwr? (
            case(memaddr[1:0])
                0: 'b0001;
                1: 'b0011;
                2: 'b0111;
                3: 'b1111;
            endcase) :
        instrIsSwl? (
            case(memaddr[1:0])
                0: 'b1000;
                1: 'b1100;
                2: 'b1110;
                3: 'b1111;
            endcase) :
        wenIsW? 4'b1111:
        wenIsH? 4'b0011 << memaddr[1:0]:
        4'b0001 << memaddr[1:0];



    function WbInfo getwbinfo(Bit#(64) mcResult);
        Bool instrIsMul = ctr == ALUctr_mul;
        Bool instrIsMovz = reg_id_ex.instr[31:26] == 'b011100 && reg_id_ex.instr[5:0] == 'b001011;
        Bool instrIsMovn = reg_id_ex.instr[31:26] == 'b011100 && reg_id_ex.instr[5:0] == 'b001010;
        Bool mov = instrIsMovz && reg_id_ex.busb == 0 || instrIsMovn && reg_id_ex.busb != 0;
        
        Bool wr = !reg_id_ex.nop && (
                    reg_id_ex.instr[31:29]==3'b001 //立即数算术
                ||  reg_id_ex.instr[31:29]==3'b100 //load指令
                ||  (reg_id_ex.instr[31:26]==6'b000000 //R型算术
                    &&      (reg_id_ex.instr[5:3]==3'b000 //移位
                        ||  reg_id_ex.instr[5:3]==3'b100 //加减
                        ||  reg_id_ex.instr[5:3]==3'b101)) //条件置位
                ||  reg_id_ex.instr[31:29]=='b100 //取值
                ||  instrIsMfc0
                ||  buswIsPc8
                ||  instrIsMfhi
                ||  instrIsMflo
                ||  instrIsMul
                ||  mov
            );
        RegName num = 
            rwIsRt? reg_id_ex.instr[20:16]:
            rwIs31? 5'd31:
            reg_id_ex.instr[15:11];
        Data wbdata = 
            mov         ?   reg_id_ex.busb:
            buswIsPc8   ?  (reg_id_ex.pc + 8):
            instrIsMfhi ?   reg_id_ex.hid:
            instrIsMflo ?   reg_id_ex.lod:
            instrIsMul  ?   mcResult[31:0]:
                           aluout().result;
        Bool wbvalid = !(reg_id_ex.instr[31:29]=='b100 || instrIsMfc0);

        return WbInfo{
            wr: wr && num != 0,
            valid: wbvalid,
            num: num,
            data: wbdata
        };
    endfunction

    

    //todo: mcalu
    method Bool getPauseReq(Bool mcfinish);
        return !reg_id_ex.nop && reg_id_ex.exc==None && start && !mcfinish();
    endmethod

    method Tuple4#(Bool, ALUctr, Data, Data) toMCALU();
        return tuple4(start, ctr, reg_id_ex.busa, reg_id_ex.busb);
    endmethod

    //访存
    method MemReq toDmem(Bool wrn, Bool pause, Bool exc);
        Bool instrIsLwl = reg_id_ex.instr[31:26] == 'b100010;
        Bool instrIsLwr = reg_id_ex.instr[31:26] == 'b100110;

        let dmemreq =  MemReq{
            arsize: wenIsH? 3'b001: wenIsW? 3'b010: 3'b000,
            en: (instrIsStore || instrIsSwl || instrIsSwr) && !reg_id_ex.nop && !wrn &&
                reg_id_ex.exc == None && !mAddrExc && !exc,
            be: be,
            addr: (memaddr[31:29] == 'b101)? memaddr: {memaddr[31:2],2'b0},
            data: reg_id_ex.busb << ({3'b0,memaddr[1:0]} << 3)
        };
        return MemReq{
            arsize: dmemreq.arsize,
            en: pause? False: !reg_id_ex.nop && !wrn && reg_id_ex.exc == None && !mAddrExc && 
                (instrIsStore || instrIsLoad || instrIsSwl || instrIsSwr || instrIsLwl || instrIsLwr),
            be: dmemreq.en? dmemreq.be: 4'b0,
            addr: dmemreq.addr,
            data: dmemreq.data
        };
    endmethod


    //流水线的更新
    method Action step(
            Data_ID_EX data_id_ex,
            CtrlUnitInfo ctrl_info
        );
        if(!ctrl_info.pause)begin
            reg_id_ex <= Data_ID_EX{
                nop: data_id_ex.nop || ctrl_info.bub,// data_id_ex.exc != None,
                pc: data_id_ex.pc,
                instr: data_id_ex.instr,
                busa: data_id_ex.busa,
                busb: data_id_ex.busb,
                hid: data_id_ex.hid,
                lod: data_id_ex.lod,
                aluctr: data_id_ex.aluctr,
                exc: data_id_ex.exc
            };
        end
        else begin
            reg_id_ex <= Data_ID_EX{
                nop: reg_id_ex.nop || ctrl_info.exception,
                pc: reg_id_ex.pc,
                instr: reg_id_ex.instr,
                busa: reg_id_ex.busa,
                busb: reg_id_ex.busb,
                hid: reg_id_ex.hid,
                lod: reg_id_ex.lod,
                aluctr: reg_id_ex.aluctr,
                exc: reg_id_ex.exc
            };
        end
        //mcalu.step(start, ctr, reg_id_ex.busa, reg_id_ex.busb);
        //if(mcalu.finish()) $display("mcalu complete, result: ", fshow(mcalu.getResult()));
        //$display("------");
        // // $display("||       ", reg_id_ex.instr[31:29]==3'b001); //立即数算术
        // // $display("||       ", reg_id_ex.instr[31:29]==3'b100);
        // // $display("|| &&    ", reg_id_ex.instr[31:26]==6'b000000);
        // // $display("   && || ", reg_id_ex.instr[5:3]==3'b000);
        // // $display("      || ", reg_id_ex.instr[5:3]==3'b100);
        // // $display("      || ", reg_id_ex.instr[5:3]==3'b101);
        // // $display("||       ", reg_id_ex.instr[31:29]=='b100);
        // // $display("||       ", instrIsMfc0);
        // // $display("||       ", buswIsPc8);
        // // $display("||       ", instrIsMfhi);
        // // $display("||       ", instrIsMflo);
        //if(cnt >= 15660 && cnt <= 15690)begin
        //$display("alu: %0h %0h ", alua, alub, fshow(ctr));
        //$display("alu: ",fshow(alu.calc(ctr, alua, alub)));
        //end
        // // $display(fshow(aluout()));
        //$display("------");
        //$display("start:",fshow(start));
    endmethod

    method Data_EX_MEM out(Bit#(64) mcResult, Bool mcfinish);
        //todo:  hilowb and exc
        Bool instrIsMtlo = (
            reg_id_ex.instr[31:26] == 6'b000000 &&
            reg_id_ex.instr[5:0] == 6'b010011
        );
        Bool instrIsMthi = (
            reg_id_ex.instr[31:26] == 6'b000000 && 
            reg_id_ex.instr[5:0] == 6'b010001
        );

        Bool instrIsMadd = (ctr == ALUctr_madd) || (ctr == ALUctr_maddu);
        Bool instrIsMsub = (ctr == ALUctr_msub) || (ctr == ALUctr_msubu);
        Bit#(64) madd = instrIsMadd? mcResult + {reg_id_ex.hid, reg_id_ex.lod}:
                                     mcResult - {reg_id_ex.hid, reg_id_ex.lod};

        return Data_EX_MEM{
            nop: reg_id_ex.nop,
            pc : reg_id_ex.pc,
            instr : reg_id_ex.instr,
            wbinfo : getwbinfo(mcResult),
            hilowb : HiloWbInfo{
                hiwr: (mcfinish && (ctr == ALUctr_div || ctr == ALUctr_divu || (ctr == 
                    ALUctr_mult || ctr == ALUctr_multu)) || instrIsMthi),
                lowr: (mcfinish && (ctr == ALUctr_div || ctr == ALUctr_divu || (ctr == 
                    ALUctr_mult || ctr == ALUctr_multu)) || instrIsMtlo),
                hid: (mcfinish && ((ctr == ALUctr_div || ctr == ALUctr_divu) || (ctr == 
                ALUctr_mult || ctr == ALUctr_multu)))?
                    mcResult()[63:32]:
                    (instrIsMadd || instrIsMsub)? madd[63:32]: 
                    reg_id_ex.busa,
                lod: (mcfinish && ((ctr == ALUctr_div || ctr == ALUctr_divu) || (ctr == 
                ALUctr_mult || ctr == ALUctr_multu)))? 
                mcResult[31:0]:
                (instrIsMadd || instrIsMsub)? madd[31:0]: 
                reg_id_ex.busa
            },
            aluout : aluout().result,
            busa : reg_id_ex.busa,
            busb : reg_id_ex.busb,
            exc : 
            max((reg_id_ex.exc == None && aluout().overflow)? Overflow: None,
            max(mAddrExc? BadMAddr: None,
            max(((ctr == ALUctr_div || ctr == ALUctr_divu) && reg_id_ex.busb == 0)? DivByZero: None,
                reg_id_ex.exc)))
        };
    endmethod



endmodule

endpackage