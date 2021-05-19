package stageIF;

import def_types :: *;

interface StageIF_ifc;
    method Data_IF_ID out(Bool exc);
    method MemReq toImem(Bool pause);
    method Action step(CtrlUnitInfo ctrl_info, Bcheck bc, Bool icache_miss);
endinterface

(* synthesize *)
module mkStageIF(StageIF_ifc);

    Reg#(Addr) reg_pc <- mkReg('hbfc00000);//('hbfc34930);

    method Data_IF_ID out(Bool exc);
        return Data_IF_ID{
            nop: exc,
            pc: reg_pc,
            exc: (reg_pc[1:0] == 2'b0 || exc)? None: BadFAddr
        };
    endmethod

    method Action step(
            CtrlUnitInfo ctrl_info, Bcheck bc,
            Bool icache_miss
        );
        if(icache_miss) reg_pc <= reg_pc;
        else if(ctrl_info.exception)begin
            reg_pc <= handlerEntry;
        end
        else if(bc.fail)
            reg_pc <= bc.npc;
        else if(!ctrl_info.pause)
            reg_pc <= reg_pc + 4;
        //$display(fshow(bc));
    endmethod


    method MemReq toImem(Bool pause);
        return MemReq{arsize: 0, en:pause? False: True, be:4'b0000, addr:{reg_pc[31:2], 2'b0}, data:'b0};
    endmethod
endmodule


endpackage