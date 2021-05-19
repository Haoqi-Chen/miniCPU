package mips_cpu;

  	//`define DEBUG 1
  	`define ShowTrace 1
  	//`define progBar 1
	`define check_start 0
	`define check_end 100
	`define totalCycle 300000
	`define startPoint 32'hbfc34930

import def_types :: *;

import stageIF :: *;
import stageID :: *;
import stageEX :: *;
import stageMEM :: *;
import stageWB :: *;
import ctrlUnit :: *;
import div :: *;

//import IMEM :: *;
//import DMEM :: *;
//import confreg :: *;
//import bridge :: *;


interface Mips_cpu_ifc;
//method Action showRF();
    method ActionValue#(Tuple2#(MemReq,MemReq)) step(Instr instr, Data mdata, Bit#(6) intSig, Bool icache_miss, Bool dcache_miss);
    //method MemReq toImem();
    // method MemReq toDmem();
    method Debug_t getDebugInfo();
endinterface

(* synthesize *)
module mkCPU(Mips_cpu_ifc);
    StageIF_ifc   u_IF   <-  mkStageIF;//(`startPoint);
    StageID_ifc   u_ID   <-  mkStageID;
    StageEX_ifc   u_EX   <-  mkStageEX;
    StageMEM_ifc  u_MEM  <-  mkStageMEM;
    StageWB_ifc   u_WB   <-  mkStageWB;
    CtrlUnit_ifc  u_ctr  <-  mkCtrlUnit;
    MCALU_ifc     mcalu  <-  mkMCALU;

// Reg#(Data) cnt <- mkReg(0);//reg for test
// Reg#(Data) cnt2 <- mkReg(0);//reg for test


    

    method ActionValue#(Tuple2#(MemReq,MemReq)) step(Instr instr, Data mdata, Bit#(6) intSig, Bool icache_miss, Bool dcache_miss);
        let epc = u_ctr.getepc(u_WB.getcp0wr(u_ctr.getcp0()));
        let mcfinish = mcalu.finish();
        let mcout = mcalu.getResult();
        let exout = u_EX.out(mcout, mcfinish);
        let memout = u_MEM.out(mdata, epc);
        let ewb = exout.wbinfo;
        let mwb = memout.wbinfo;
        let wwb = u_WB.getwbinfo(u_ctr.getcp0());
        let dPauseReq = u_ID.getPauseReq(
                instr,
                exout.wbinfo(),
                memout.wbinfo(),
                u_WB.getwbinfo(u_ctr.getcp0())
            );
        let ePauseReq = u_EX.getPauseReq(mcfinish);
        let membcheck = 
            u_MEM.bcheck(u_ctr.getepc(u_WB.getcp0wr(u_ctr.getcp0())));
        let dctr = u_ctr.ctrl_id(
                u_WB.getExc(u_ctr.getcp0()), dPauseReq, 
                ePauseReq, membcheck,
                icache_miss,
                dcache_miss
            );
        let fctr = u_ctr.ctrl_if(
                u_WB.getExc(u_ctr.getcp0()), 
                dPauseReq,
                ePauseReq,
                icache_miss,
                dcache_miss
            );
        let ifout = u_IF.out(fctr.exception);
        let idout = u_ID.out(
                instr, dctr.pause,
                ewb, mwb, wwb,
                exout.hilowb,
                memout.hilowb,
                u_WB.gethilowb(u_ctr.getcp0())
            );
        let toMCalu = u_EX.toMCALU();
        let ectr = u_ctr.ctrl_ex(
            u_WB.getExc(u_ctr.getcp0()), dPauseReq,
            ePauseReq, membcheck,
            icache_miss,
            dcache_miss
        );
        mcalu.step(
            tpl_1(toMCalu), tpl_2(toMCalu), 
            tpl_3(toMCalu), tpl_4(toMCalu), ectr.pause
        );

        u_IF.step(fctr, membcheck, icache_miss || dcache_miss);

        u_ID.step(
            instr,
            ifout,
            dctr,
            wwb,
            u_WB.gethilowb(u_ctr.getcp0()),
            icache_miss
        );

        u_EX.step(
            idout,
            ectr
        );

        u_MEM.step(
            exout,
            u_ctr.ctrl_mem(
                u_WB.getExc(u_ctr.getcp0()), dPauseReq,
                ePauseReq, membcheck,
                icache_miss,
                dcache_miss
            ),
            mdata,
            dcache_miss,
            intSig
        );

        u_WB.step(
            memout,
            u_ctr.ctrl_wb(
                u_WB.getExc(u_ctr.getcp0()), 
                dPauseReq, 
                ePauseReq,
                icache_miss,
                dcache_miss
            )
        );

        u_ctr.step(u_WB.getcp0wr(u_ctr.getcp0()), icache_miss, dcache_miss);

        let imemreq = u_IF.toImem(fctr.pause);
        if(dctr.pause) imemreq.addr = idout.pc;

        let dmemreq = u_EX.toDmem(
            u_MEM.memWrDisable(epc,u_ctr.getcp0.status,intSig), 
            ectr.pause, fctr.exception
        );

        return tuple2(imemreq,dmemreq);

        //cnt <= cnt + 1;
        `ifdef DEBUG
if(cnt >= `check_start && cnt <= `check_end)begin
        $display();
        $display(fshow(ifout));
        $display();
        $display(fshow(dctr));
        $display(fshow(idout));
        $display();
        $display("dPauseReq: ",fshow(dPauseReq));
        $display();
        $display(fshow(exout));
        $display();
        $display("ePauseReq: ",fshow(ePauseReq));
        $display();
        $display(fshow(memout));
        $display();
        $display("exception: ", fshow(u_WB.getExc(u_ctr.getcp0())));
        $display();
        $display(fshow(u_WB.getcp0wr(u_ctr.getcp0())));
        $display(fshow(u_ctr.getcp0()));
        $display();

end
        `endif
//if(u_WB.getcp0wr(u_ctr.getcp0()).epcwr)$display("---- %0d ----",cnt);
    endmethod
/*
//method for test
method Action showRF();
	cnt2 <= cnt2 + 1;
	if(cnt2 < 32)
		u_ID.showRF();
endmethod
*/
    // method MemReq toImem();
    //     let imemreq = u_IF.toImem();
    //     if(w_dpause) imemreq.addr = {3'b0,w_dpc[28:0]};
    //     if(imemreq.addr[31:30] == 'b10) imemreq.addr = {3'b0,imemreq.addr[28:0]};
    //     return imemreq;
    // endmethod

    // method MemReq toDmem();
    //     let epc = u_ctr.getepc(u_WB.getcp0wr(u_ctr.getcp0()));
    //     let dmemreq = u_EX.toDmem(u_MEM.memWrDisable(epc));
    //     return dmemreq;
    // endmethod

    method Debug_t getDebugInfo();
        return u_WB.getDebugInfo(u_ctr.getcp0());
    endmethod

endmodule
/*
module mkTb();
    Mips_cpu_ifc mips <- mkCPU;

    IMEM_IFC imem <- mkIMEM("mem/inst_ram.mif");
    DMEM_IFC dmem <- mkDMEM;
    Confreg_ifc confreg <- mkConfreg;
    Bridge_ifc bridge <- mkBridge;

    Reg#(Data) cnt <- mkReg(0);


    rule runMips (cnt < `totalCycle);
        cnt <= cnt + 1;
        let imemReq = mips.toImem();
        let dmemReq = mips.toDmem();
        let debug = mips.getDebugInfo();
//if(debug.pc[19:0] != 'h34930)begin
        mips.step(
            imem.inst_sram_rdata(),
            bridge.toCPU(
                    dmem.data_sram_rdata(), 
                    confreg.get_confreg_rdata()
                ),
            False, False, False
        );
        imem.inst_request({12'b0,imemReq.addr[19:0]});
        dmem.data_request(
            dmemReq.en, 
            dmemReq.be, 
            dmemReq.addr, 
            dmemReq.data
        );
        bridge.rcvReq(dmemReq);
        confreg.step( 
                dmemReq,
                True,
                'hff,        
                'hf,  
                'b11
            );
//end else mips.showRF();
    endrule


    rule showInfo (cnt < `totalCycle);
        let imemReq = mips.toImem();
        let dmemReq = mips.toDmem();
        let debug = mips.getDebugInfo();
//------------------------
`ifdef progBar
        if(cnt % 500 == 0) $display("---- %0d %8h ----", cnt, debug.pc);
`endif
`ifdef DEBUG 
if(cnt >= `check_start && cnt <= `check_end)begin
        $display("=========================================== cycle %0d", cnt," ===========================================");
        $display("top: dmem request : ",fshow(dmemReq));
        $display("top: bridge response: ",fshow(bridge.toCPU(dmem.data_sram_rdata(),confreg.get_confreg_rdata())));
        $display();
        end
if(cnt >= `check_start && cnt <= `check_end)
`endif
`ifdef ShowTrace
	if(debug.wen)
            $display("1 bfc%5h %2h %8h", debug.pc[19:0], debug.wnum, debug.wdata);
`endif
//----------------
        //if(dmemReq.en && dmemReq.addr[19:2]=='h36f4d)
            //$display("store %8h at addr %8h, cycle: %0d", dmemReq.data, dmemReq.addr, cnt);
        //if(mips.getDebugInfo().pc[19:0] == 'h4f348) $display(cnt);
    endrule


`ifdef DEBUG
    rule endTag(cnt == `totalCycle);
        cnt <= cnt + 1;
        $display("============= end ============");
    endrule
`endif



endmodule
*/
endpackage