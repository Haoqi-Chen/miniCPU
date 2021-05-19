package stageWB;

import def_types :: *;

interface StageWB_ifc;
    method Action step(
        Data_MEM_WB data_mem_wb,
        CtrlUnitInfo ctrl_info
    );
    method WbInfo getwbinfo(CP0 cp0);
    method HiloWbInfo gethilowb(CP0 cp0);
    method CP0wr getcp0wr(CP0 cp0);
    method Bool getExc(CP0 cp0);
    method Debug_t getDebugInfo(CP0 cp0);
endinterface
(* synthesize *)
module mkStageWB(StageWB_ifc);
    // 时钟计数器和指令计数器，用于计算IPC
    Reg#(Data) cycle_cnt <- mkReg(0);
    Reg#(Data) inst_cnt  <- mkReg(0);

    Reg#(Bool) saved_pause <- mkReg(False);
    //流水线寄存器
    Reg#(Data_MEM_WB) reg_mem_wb <- mkReg(Data_MEM_WB{
        nop: True,
        pc: 'b0,
        instr: 'b0,
        wbinfo: WbInfo{wr: False, valid: False, num:'b0, data: 'b0},
        hilowb: HiloWbInfo{
            hiwr: False, lowr: False, hid: 'b0, lod: 'b0
        },
        aluout: 'b0,
        busb: 'b0,
        ext_int: 'b0,
        exc: None
    });

    //延迟槽
    Reg#(Bool) inbd <- mkReg(False);


    function WbInfo fgetwbinfo(CP0 cp0);
        Bool instrIsMfbadvaddr =
            (reg_mem_wb.instr[31:25] == 7'b0100000
            && !(reg_mem_wb.instr[23] == 'b1)
            && reg_mem_wb.instr[15:11] == 5'd8);            
        Bool instrIsMfcount =
            (reg_mem_wb.instr[31:25] == 7'b0100000
            && !(reg_mem_wb.instr[23] == 'b1)
            && reg_mem_wb.instr[15:11] == 5'd9);
        Bool instrIsMfstatus =
            (reg_mem_wb.instr[31:25] == 7'b0100000
             && !(reg_mem_wb.instr[23] == 'b1)
            && reg_mem_wb.instr[15:11] == 5'd12);
        Bool instrIsMfcause =
            (reg_mem_wb.instr[31:25] == 7'b0100000
             && !(reg_mem_wb.instr[23] == 'b1)
            && reg_mem_wb.instr[15:11] == 5'd13);
        Bool instrIsMfepc =
            (reg_mem_wb.instr[31:25] == 7'b0100000
             && !(reg_mem_wb.instr[23] == 'b1)
            && reg_mem_wb.instr[15:11] == 5'd14);
        Data wbdata = 
            instrIsMfbadvaddr? cp0.badvaddr:
            instrIsMfcount? cp0.count:
            instrIsMfstatus? cp0.status:
            instrIsMfcause? cp0.cause:
            instrIsMfepc? cp0.epc:
            reg_mem_wb.wbinfo.data;
        return WbInfo{
            wr: reg_mem_wb.wbinfo.wr && 
                reg_mem_wb.exc == None &&
                !reg_mem_wb.nop && 
                reg_mem_wb.wbinfo.num != 0 &&
                ((reg_mem_wb.ext_int & cp0.status[15:10]) == 0 || cp0.status[1:0] != 'b01) &&
                !saved_pause,
            valid: True,
            num: reg_mem_wb.wbinfo.num,
            data: wbdata
        };
    endfunction
    
    function CP0wr fgetcp0wr(CP0 cp0);
        Bool instrIsMtbadvaddr =
            (reg_mem_wb.instr[31:23] == 9'b010000001
            && reg_mem_wb.instr[15:11] == 5'd8);
        Bool instrIsMtcount =
            (reg_mem_wb.instr[31:23] == 9'b010000001
            && reg_mem_wb.instr[15:11] == 5'd9);
        Bool instrIsMtstatus =
            (reg_mem_wb.instr[31:23] == 9'b010000001
            && reg_mem_wb.instr[15:11] == 5'd12);
        Bool instrIsMtcause =
            (reg_mem_wb.instr[31:23] == 9'b010000001
            && reg_mem_wb.instr[15:11] == 5'd13);
        Bool instrIsMtepc =
            (reg_mem_wb.instr[31:23] == 9'b010000001
            && reg_mem_wb.instr[15:11] == 5'd14);
        Bool instrIsLoad = reg_mem_wb.instr[31:29] == 'b100;
        Bool instrIsEret = reg_mem_wb.instr[31:25] == 'b0100001;

        let exc = reg_mem_wb.exc;
        Data badvaddrd = 
            (instrIsMtbadvaddr && exc == None)? reg_mem_wb.busb:
            (exc == BadFAddr)? reg_mem_wb.pc:
            (exc == BadMAddr)? reg_mem_wb.aluout:
            cp0.badvaddr;
        Data countd = (instrIsMtcount && exc == None)? reg_mem_wb.busb: cp0.count;
        Data statusd =  {
            /*9'b0,
            1'b1,
            6'b0,
            8'b0, //
            6'b0,*/
            16'h0040,
            (instrIsMtstatus && exc == None)? reg_mem_wb.busb[15:8]: cp0.status[15:8],
            6'h0,
            //cp0.status[31:2],
            (instrIsMtstatus && exc == None)? reg_mem_wb.busb[1]:
            (!reg_mem_wb.nop && instrIsEret)? 1'b0:
            ((!reg_mem_wb.nop && exc != None) || ((reg_mem_wb.ext_int & cp0.status[15:10]) != 0 && cp0.status[1:0] == 'b01))? 1'b1: cp0.status[1],
            (instrIsMtstatus && exc == None)? reg_mem_wb.busb[0]:
            cp0.status[0]
        };
        Data caused = {
            pack((inbd || reg_mem_wb.exc == Loop)),
            1'b0,
            14'b0,
            reg_mem_wb.ext_int & cp0.status[15:10],
            (instrIsMtcause && (exc == None || exc == Loop))?reg_mem_wb.busb[9:8]:cp0.cause[9:8],
            1'b0,
            (((reg_mem_wb.ext_int & cp0.status[15:10]) != 0 && cp0.status[1:0] == 'b01) || exc == Loop)? execode_int:
            (exc == BadFAddr || exc == BadMAddr && instrIsLoad)? execode_adel:
            (exc == BadMAddr)? execode_ades:
            (reg_mem_wb.instr[31:26] == 'b000000 &&
            reg_mem_wb.instr[5:0] == 'b001100)? execode_sys:
            (reg_mem_wb.instr[31:26] == 'b000000 &&
            reg_mem_wb.instr[5:0] == 'b001101)? execode_bp:
            (exc == RsvInstr)? execode_ri:
            (exc == Overflow)? execode_ov:
            (exc == Trap)? execode_tr:
            5'b0,
            2'b0
        };
        Data epcd = 
            (instrIsMtepc && exc == None)? reg_mem_wb.busb:
            (inbd || reg_mem_wb.exc == Loop)? reg_mem_wb.pc - 4: 
            reg_mem_wb.pc;

        return CP0wr{
            badvaddrd: badvaddrd,
            countd: countd,
            statusd: statusd,
            caused: caused,
            epcd: epcd,
            badvaddrwr: (instrIsMtbadvaddr || exc != None) &&
                !reg_mem_wb.nop,
            countwr: (instrIsMtcount || exc != None) &&
                !reg_mem_wb.nop,
            statuswr: (instrIsMtstatus || exc != None || instrIsEret) &&
                !reg_mem_wb.nop,
            causewr: (instrIsMtcause || exc != None) &&
                !reg_mem_wb.nop,
            epcwr: (instrIsMtepc || exc != None) &&
                !reg_mem_wb.nop
        };
    endfunction


    //更新流水线
    method Action step(
            Data_MEM_WB data_mem_wb,
            CtrlUnitInfo ctrl_info
        );


        cycle_cnt <= cycle_cnt + 1;
        if((!reg_mem_wb.nop && reg_mem_wb.exc == None) || (reg_mem_wb.nop && reg_mem_wb.instr == 0) && !ctrl_info.pause)
            inst_cnt <= inst_cnt + 1;

        saved_pause <= ctrl_info.pause;
        Bool instrIsB = (
            reg_mem_wb.instr[31:29]==3'b000 &&
            (reg_mem_wb.instr[28:26]==3'b001 ||
            reg_mem_wb.instr[28]=='b1)
        );
        Bool instrIsJr = reg_mem_wb.instr[31:26]==6'b0 &&
                    reg_mem_wb.instr[5:2]==4'b0010;
        Bool instrIsJnr = reg_mem_wb.instr[31:27] == 'b00001;

        if(!ctrl_info.pause)begin
            inbd <= (reg_mem_wb.nop && reg_mem_wb.instr != 0)?
                inbd: (!reg_mem_wb.nop && (instrIsB || instrIsJr || instrIsJnr));
            reg_mem_wb <= Data_MEM_WB{
                nop: data_mem_wb.nop || ctrl_info.bub,
                pc: data_mem_wb.pc,
                instr: data_mem_wb.instr,
                wbinfo: data_mem_wb.wbinfo,
                hilowb: data_mem_wb.hilowb,
                aluout: data_mem_wb.aluout,
                busb: data_mem_wb.busb,
                ext_int: data_mem_wb.ext_int,
                exc: data_mem_wb.exc
            };
        end
    endmethod

    method WbInfo getwbinfo(CP0 cp0);
        return fgetwbinfo(cp0);
    endmethod

    method CP0wr getcp0wr(CP0 cp0);
	    let cp0wr = fgetcp0wr(cp0);
        if(!reg_mem_wb.nop && (
            reg_mem_wb.exc != None// || fgetcp0wr(cp0).causewr && fgetcp0wr(cp0).caused[9:8] != 0
        ) || ((reg_mem_wb.ext_int & cp0.status[15:10]) != 0 && cp0.status[1:0] == 'b01))
            return CP0wr{
                badvaddrd: cp0wr.badvaddrd,
                countd: cp0wr.countd,
                statusd: cp0wr.statusd,
                caused: {
                    cp0.status[1] == 0? cp0wr.caused[31]: cp0.cause[31],
                    cp0wr.caused[30:0]
                },
                epcd: 
                    //(fgetcp0wr(cp0).causewr && fgetcp0wr(cp0).caused[9:8] != 0)?
                    (reg_mem_wb.exc==Loop)?cp0wr.epcd + 4: cp0wr.epcd,
                badvaddrwr: True,
                countwr: False,
                statuswr: True,
                causewr: True,
                epcwr: (cp0.status[1] == 0)
            };
        else return cp0wr;
    endmethod

    method HiloWbInfo gethilowb(CP0 cp0);
        return (reg_mem_wb.exc == None && !reg_mem_wb.nop && ((reg_mem_wb.ext_int & cp0.status[15:10]) == 0 || cp0.status[1:0] != 'b01))? reg_mem_wb.hilowb: unpack(0);
    endmethod

    method Bool getExc(CP0 cp0);
        return !reg_mem_wb.nop && (
            reg_mem_wb.exc != None
            // || fgetcp0wr(cp0).causewr && fgetcp0wr(cp0).caused[9:8] != 0
        ) || ((reg_mem_wb.ext_int & cp0.status[15:10]) != 0 && cp0.status[1:0] == 'b01);
    endmethod

    method Debug_t getDebugInfo(CP0 cp0);
        return Debug_t{
            pc: reg_mem_wb.pc,
            wen: fgetwbinfo(cp0).wr,
            wnum: fgetwbinfo(cp0).num,
            wdata: fgetwbinfo(cp0).data
        };
    endmethod
    
endmodule

endpackage