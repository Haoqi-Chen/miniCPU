package ctrlUnit;

import def_types :: *;

interface CtrlUnit_ifc;
    method Action step(CP0wr cp0wr, Bool icache_miss, Bool dcache_miss);
    method CP0 getcp0();
    method Data getepc(CP0wr cp0wr);
    method CtrlUnitInfo ctrl_if( 
            Bool exc, Bool dPauseReq, Bool ePauseReq,
            Bool icache_miss, Bool dcache_miss
        );
    method CtrlUnitInfo ctrl_id(
            Bool exc, Bool dPauseReq, Bool ePauseReq,
            Bcheck bc, Bool icache_miss, Bool dcache_miss
        );
    method CtrlUnitInfo ctrl_ex(
            Bool exc, Bool dPauseReq, Bool ePauseReq,
            Bcheck bc, Bool icache_miss, Bool dcache_miss
        );
    method CtrlUnitInfo ctrl_mem(
            Bool exc, Bool dPauseReq, Bool ePauseReq,
            Bcheck bc, Bool icache_miss, Bool dcache_miss
        );
    method CtrlUnitInfo ctrl_wb(
            Bool exc, Bool dPauseReq, Bool ePauseReq, 
            Bool icache_miss, Bool dcache_miss
        );
endinterface
(* synthesize *)
module mkCtrlUnit(CtrlUnit_ifc);

    Reg#(Data) reg_badvaddr <- mkReg(0)          ;
    Reg#(Data) reg_status   <- mkReg('h00400000) ;
    Reg#(Data) reg_cause    <- mkReg(0)          ;
    Reg#(Data) reg_epc      <- mkReg(0)          ;
    Reg#(Data) reg_count    <- mkReg(0)          ;

    // Reg#(Data) reg_index     <-  mkReg(0)  ;
    // Reg#(Data) reg_random    <-  mkReg(31) ;
    // Reg#(Data) reg_entrylo0  <-  mkReg(0)  ;
    // Reg#(Data) reg_entrylo1  <-  mkReg(0)  ;
    // Reg#(Data) reg_context   <-  mkReg(0)  ;
    // Reg#(Data) reg_pagemask  <-  mkReg(0)  ;
    // Reg#(Data) reg_entryhi   <-  mkReg(0)  ;

    Reg#(Bool) reg_incr <- mkReg(False);


    method Action step(CP0wr cp0wr, Bool icache_miss, Bool dcache_miss);
        if(cp0wr.badvaddrwr) reg_badvaddr <= cp0wr.badvaddrd;
        if(cp0wr.statuswr) reg_status <= cp0wr.statusd;
        if(cp0wr.causewr) reg_cause <= cp0wr.caused;
        if(cp0wr.epcwr) reg_epc <= cp0wr.epcd;

        reg_incr <= !reg_incr;
        if(cp0wr.countwr) reg_count <= cp0wr.countd;
        else if(reg_incr) reg_count <= reg_count + 1;
    endmethod

    method CP0 getcp0();
        return CP0{
            badvaddr: reg_badvaddr,
            count: reg_count,
            status: reg_status,
            cause: reg_cause,
            epc: reg_epc
        };
    endmethod

    method CtrlUnitInfo ctrl_if(
            Bool exc, Bool dPauseReq, Bool ePauseReq, 
            Bool icache_miss, Bool dcache_miss
        );
        return CtrlUnitInfo{
            exception: exc,
            pause: dPauseReq || ePauseReq || icache_miss || dcache_miss,
            bub: False
        };
    endmethod

    method CtrlUnitInfo ctrl_id(
            Bool exc, Bool dPauseReq, Bool ePauseReq,
            Bcheck bc, Bool icache_miss, Bool dcache_miss
        );
        return CtrlUnitInfo{
            exception: exc,
            pause: dPauseReq || ePauseReq || icache_miss || dcache_miss,
            bub: exc || bc.fail
        };
    endmethod

    method CtrlUnitInfo ctrl_ex(
            Bool exc, Bool dPauseReq, Bool ePauseReq,
            Bcheck bc, Bool icache_miss, Bool dcache_miss
        );
        return CtrlUnitInfo{
            exception: exc,
            pause: ePauseReq || icache_miss || dcache_miss,
            bub: exc || (bc.fail || dPauseReq) && !ePauseReq
        };
    endmethod

    method CtrlUnitInfo ctrl_mem(
            Bool exc, Bool dPauseReq, Bool ePauseReq,
            Bcheck bc, Bool icache_miss, Bool dcache_miss
        );
        return CtrlUnitInfo{
            exception: exc,
            pause: dcache_miss || icache_miss,
            bub: exc || ePauseReq || (bc.fail && !bc.failB)
        };
    endmethod

    method CtrlUnitInfo ctrl_wb(
            Bool exc, Bool dPauseReq, Bool ePauseReq, 
            Bool icache_miss, Bool dcache_miss
        );
        return CtrlUnitInfo{
            exception: exc,
            pause: icache_miss || dcache_miss,
            bub: exc
        };
    endmethod

    method Data getepc(CP0wr cp0wr);
        return cp0wr.epcwr? cp0wr.epcd: reg_epc;
    endmethod

endmodule


endpackage