package stageMEM;


import def_types :: *;

interface StageMEM_ifc;
    method Action step(
        Data_EX_MEM data_ex_mem,
        CtrlUnitInfo ctrl_info,
        Data dout,
        Bool dcache_miss,
        Bit#(6) ext_int
    );
    method Bcheck bcheck(Data epc);
    method Data_MEM_WB out(Data dout0, Data epc);
    method Bool memWrDisable(Data epc, Data status, Bit#(6) ext_int );
endinterface
(* synthesize *)
module mkStageMEM(StageMEM_ifc);
    Reg#(Bit#(6))      saved_int  <- mkReg(0);
    Reg#(Maybe#(Data)) saved_data <- mkReg(tagged Invalid);
    //流水线寄存器
    Reg#(Data_EX_MEM) reg_ex_mem <- mkReg(Data_EX_MEM{
        nop: True,
        pc: 'b0,
        instr: 'b0,
        wbinfo: WbInfo{wr: False, valid: False, num:'b0, data: 'b0},
        hilowb: HiloWbInfo{
            hiwr: False, lowr: False, hid: 'b0, lod: 'b0
        },
        aluout: 'b0,
        busa: 'b0,
        busb: 'b0,
        exc: None
    });

    function Data getMemout(Data dout0, Data rt);
        Bool instrIsLwl = reg_ex_mem.instr[31:26] == 'b100010;
        Bool instrIsLwr = reg_ex_mem.instr[31:26] == 'b100110;
        Bool wenIsW = reg_ex_mem.instr[28:26] == 3'b011;
        Bool wenIsH = reg_ex_mem.instr[27:26] == 2'b01;
	Data dout = 
            (wenIsW)? dout0:
            (wenIsH)?(
                (reg_ex_mem.aluout[1:0] == 2'b00)? {16'b0, dout0[15:0]}:
                                                  {16'b0, dout0[31:16]}
            ):(
                (reg_ex_mem.aluout[1:0] == 2'b11)? {24'b0, dout0[31:24]}:
                (reg_ex_mem.aluout[1:0] == 2'b10)? {24'b0, dout0[23:16]}:
                (reg_ex_mem.aluout[1:0] == 2'b01)? {24'b0, dout0[15:8]}:
                                                  {24'b0, dout0[7:0]}
            );
        
        Bool signext = reg_ex_mem.instr[28] == 1'b0;
        Bool ext8 = reg_ex_mem.instr[27:26] == 2'b00;
        Bool ext16 = reg_ex_mem.instr[27:26] == 2'b01;
        Data memaddr = reg_ex_mem.busa + signExtend(reg_ex_mem.instr[15:0]);
        Bit#(4) be = 
            instrIsLwr? (
                case(memaddr[1:0])
                    0: 'b0001;
                    1: 'b0011;
                    2: 'b0111;
                    3: 'b1111;
                endcase) :(
                case(memaddr[1:0])
                    0: 'b1000;
                    1: 'b1100;
                    2: 'b1110;
                    3: 'b1111;
                endcase) ;
        let biten = {
                (be[3] == 1)? 8'hff: 8'h0,
                (be[2] == 1)? 8'hff: 8'h0,
                (be[1] == 1)? 8'hff: 8'h0,
                (be[0] == 1)? 8'hff: 8'h0
            };
        if(instrIsLwl || instrIsLwr) begin
            return (biten & dout0) | (~biten & reg_ex_mem.busb);
        end
        else if(signext) begin
            if(ext8)
                return
                {dout[7]==1?24'hffffff:24'b0, dout[7:0]};
            else if(ext16)
                return
                {dout[15]==1?16'hffff:16'b0, dout[15:0]};
            else
                return dout;
        end
        else begin
            if(ext8)
                return {24'b0, dout[7:0]};
            else if(ext16)
                return {16'b0, dout[15:0]};
            else
                return dout;
        end
    endfunction

    Bool instrIsLoad = reg_ex_mem.instr[31:29] == 3'b100;
    Bool instrIsB = (
            reg_ex_mem.instr[31:29]==3'b000 &&
            (reg_ex_mem.instr[28:26]==3'b001 ||
            reg_ex_mem.instr[28]=='b1)
        );
    Bool instrIsJr = reg_ex_mem.instr[31:26]==6'b0 &&
                    reg_ex_mem.instr[5:2]==4'b0010;
    Bool instrIsEret = reg_ex_mem.instr[31:25]==7'b0100001;
    Bool instrIsJnr = reg_ex_mem.instr[31:27] == 'b00001;
    
    function Tuple2#(Bcheck, Bool) getbcheck(Data epc);
        Addr bDest = reg_ex_mem.pc + 4 + 
            {reg_ex_mem.instr[15]==1?14'h3fff:14'b0,
            reg_ex_mem.instr[15:0], 2'b0};
        Bcheck bc = ?;
        if(!reg_ex_mem.nop && reg_ex_mem.exc == None)
        begin
            if(instrIsB && reg_ex_mem.aluout[0] == 1)
                bc = Bcheck{
                    fail: True, failB: True, npc: bDest
                };
            else if (instrIsEret)
                bc = Bcheck{
                    fail: True, failB: False, npc: epc
                };
            else if (instrIsJr) 
                bc = Bcheck{
                    fail: True, failB: True, 
                    npc: reg_ex_mem.busa
                };
            else if (instrIsJnr)
                bc = Bcheck{
                    fail: True, failB: True,
                    npc: {reg_ex_mem.pc[31:28], reg_ex_mem.instr[25:0], 2'b00}
                 };
            else bc = Bcheck{
                    fail: False, failB: False, 
                    npc: reg_ex_mem.pc + 4
                };
        end else
            bc = Bcheck{
                fail: False, failB: False, 
                npc: reg_ex_mem.pc + 4
            };
        return tuple2(bc, (bc.fail && bc.npc == reg_ex_mem.pc));
    endfunction

    //流水线更新
    method Action step(
            Data_EX_MEM data_ex_mem,
            CtrlUnitInfo ctrl_info,
            Data dout,
            Bool dcache_miss,
            Bit#(6) ext_int
        );


        if(ctrl_info.pause || reg_ex_mem.nop) saved_int <= ext_int | saved_int;
        else                                  saved_int <= ext_int;


        if(ctrl_info.pause && !dcache_miss && saved_data == tagged Invalid)
            saved_data <= tagged Valid dout;
        else if(!ctrl_info.pause)
            saved_data <= tagged Invalid;
        if(!ctrl_info.pause)begin
            reg_ex_mem <= Data_EX_MEM{
                nop: data_ex_mem.nop || ctrl_info.bub,
                pc: data_ex_mem.pc,
                instr: data_ex_mem.instr,
                wbinfo: data_ex_mem.wbinfo,
                hilowb: data_ex_mem.hilowb,
                aluout: data_ex_mem.aluout,
                busa: data_ex_mem.busa,
                busb: data_ex_mem.busb,
                exc: data_ex_mem.exc
            };
        end
    endmethod

    
    


    method Bcheck bcheck(Data epc);
        return tpl_1(getbcheck(epc));
    endmethod


    method Data_MEM_WB out(Data dout, Data epc);
        let dout1 = fromMaybe(dout, saved_data);
        WbInfo wb = WbInfo{
            wr: !reg_ex_mem.nop && reg_ex_mem.wbinfo.wr && reg_ex_mem.wbinfo.num != 0,
            valid: reg_ex_mem.wbinfo.valid || instrIsLoad,
            num: reg_ex_mem.wbinfo.num,
            data: instrIsLoad? getMemout(dout1, reg_ex_mem.busb): 
                reg_ex_mem.wbinfo.data
        };

        ExcSignal exc = reg_ex_mem.exc; 
        Bool instrIsTrap = 
            reg_ex_mem.instr[31:26] == 0 && reg_ex_mem.instr[5:3] == 'b110 || 
            reg_ex_mem.instr[31:26] == 'b000001 && reg_ex_mem.instr[20:18] == 'b010; 

        let loop = tpl_2(getbcheck(epc));
        return Data_MEM_WB{
            nop: reg_ex_mem.nop,
            pc: reg_ex_mem.pc,
            instr: reg_ex_mem.instr,
            wbinfo: wb,
            hilowb: reg_ex_mem.hilowb,
            aluout: reg_ex_mem.aluout,
            busb: reg_ex_mem.busb,
            ext_int: reg_ex_mem.nop? 0: saved_int,
            exc: max((exc == None && loop && !reg_ex_mem.nop)? Loop: None,
                 max((instrIsTrap && (reg_ex_mem.aluout[0] == 1))? Trap: None,
                    exc))
        };
    endmethod

    method Bool memWrDisable(Data epc, Data status, Bit#(6) ext_int);
        let bc = tpl_1(getbcheck(epc));
        return !reg_ex_mem.nop && ((bc.fail && !bc.failB) || reg_ex_mem.exc != None || (((saved_int | ext_int) & status[15:10]) != 0 && status[1:0] == 'b01));
    endmethod
endmodule



endpackage