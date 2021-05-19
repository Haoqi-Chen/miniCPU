package axi_interface;

import def_types :: *;
import Dcache :: *;
import Icache :: *;
import mips_cpu :: *;
import MMU1 :: *;

interface AXI_Cache_ifc;
        method Action step(
            Bit#(6) exc_int,

            
            Awready     ibus_awready   ,
            Wready      ibus_wready    ,
            Bid         ibus_bid       ,
            Bresp       ibus_bresp     ,
            Bvalid      ibus_bvalid    ,
            Arready     ibus_arready   ,
            Rid         ibus_rid       ,
            Rdata       ibus_rdata     ,
            Rresp       ibus_rresp     ,
            Rlast       ibus_rlast     ,
            Rvalid      ibus_rvalid    ,
            
            Awready     dbus_awready   ,
            Wready      dbus_wready    ,
            Bid         dbus_bid       ,
            Bresp       dbus_bresp     ,
            Bvalid      dbus_bvalid    ,
            Arready     dbus_arready   ,
            Rid         dbus_rid       ,
            Rdata       dbus_rdata     ,
            Rresp       dbus_rresp     ,
            Rlast       dbus_rlast     ,
            Rvalid      dbus_rvalid
        );

        method Bit#(4)   ibus_awid        ();
        method Bit#(32)  ibus_awaddr      ();
        method Bit#(4)   ibus_awlen       ();
        method Bit#(3)   ibus_awsize      ();
        method Bit#(2)   ibus_awburst     ();
        method Bit#(2)   ibus_awlock      ();
        method Bit#(4)   ibus_awcache     ();
        method Bit#(3)   ibus_awprot      ();
        method Bool      ibus_awvalid     ();

        method Bit#(4)   ibus_wid         ();
        method Bit#(32)  ibus_wdata       ();
        method Bit#(4)   ibus_wstrb       ();
        method Bool      ibus_wlast       ();
        method Bool      ibus_wvalid      ();

        method Bool      ibus_bready      ();

        method Bit#(4)   ibus_arid        ();
        method Bit#(32)  ibus_araddr      ();
        method Bit#(4)   ibus_arlen       ();
        method Bit#(3)   ibus_arsize      ();
        method Bit#(2)   ibus_arburst     ();
        method Bit#(2)   ibus_arlock      ();
        method Bit#(4)   ibus_arcache     ();
        method Bit#(3)   ibus_arprot      ();
        method Bool      ibus_arvalid     ();
            
        method Bool      ibus_rready      ();

 
        method Bit#(4)   dbus_awid        ();
        method Bit#(32)  dbus_awaddr      ();
        method Bit#(4)   dbus_awlen       ();
        method Bit#(3)   dbus_awsize      ();
        method Bit#(2)   dbus_awburst     ();
        method Bit#(2)   dbus_awlock      ();
        method Bit#(4)   dbus_awcache     ();
        method Bit#(3)   dbus_awprot      ();
        method Bool      dbus_awvalid     ();

        method Bit#(4)   dbus_wid         ();
        method Bit#(32)  dbus_wdata       ();
        method Bool      dbus_wlast       ();
        method Bit#(4)   dbus_wstrb       ();
        method Bool      dbus_wvalid      ();

        method Bool      dbus_bready      ();

        method Bit#(4)   dbus_arid        ();
        method Bit#(32)  dbus_araddr      ();
        method Bit#(4)   dbus_arlen       ();
        method Bit#(3)   dbus_arsize      ();
        method Bit#(2)   dbus_arburst     ();
        method Bit#(2)   dbus_arlock      ();
        method Bit#(4)   dbus_arcache     ();
        method Bit#(3)   dbus_arprot      ();
        method Bool      dbus_arvalid     ();
            
        method Bool      dbus_rready      ();

            
        method Addr      debug_wb_pc      ();
        method Bit#(4)   debug_wb_rf_wen  ();
        method Bit#(5)   debug_wb_rf_wnum ();
        method Bit#(32)  debug_wb_rf_wdata();
       
endinterface

(*synthesize*)
(*always_enabled*)
module mkAXIcache(AXI_Cache_ifc);

    ICache_IFC icache <- mkICache;
    DCache_IFC dcache <- mkDCache;
    Mips_cpu_ifc  cpu <- mkCPU;
    MMU_IFC       mmu <- mkMMU;

    method Action step(
            Bit#(6) exc_int,
            
            Awready     ibus_awready   ,
            Wready      ibus_wready    ,
            Bid         ibus_bid       ,
            Bresp       ibus_bresp     ,
            Bvalid      ibus_bvalid    ,
            Arready     ibus_arready   ,
            Rid         ibus_rid       ,
            Rdata       ibus_rdata     ,
            Rresp       ibus_rresp     ,
            Rlast       ibus_rlast     ,
            Rvalid      ibus_rvalid    ,
            
            Awready     dbus_awready   ,
            Wready      dbus_wready    ,
            Bid         dbus_bid       ,
            Bresp       dbus_bresp     ,
            Bvalid      dbus_bvalid    ,
            Arready     dbus_arready   ,
            Rid         dbus_rid       ,
            Rdata       dbus_rdata     ,
            Rresp       dbus_rresp     ,
            Rlast       dbus_rlast     ,
            Rvalid      dbus_rvalid
        );


        let {cpu_toImem, cpu_toDmem} <- cpu.step(
            icache.get_rdata(ibus_rvalid, ibus_rdata), 
            dcache.get_rdata(dbus_rvalid, dbus_rdata), 
            exc_int, 
            icache.get_pause(ibus_rvalid),
            dcache.get_pause(dbus_rvalid)
        );
        let i_mmu_req = mmu.mmu_reqi(cpu_toImem);
        let d_mmu_req = mmu.mmu_reqd(cpu_toDmem);

        icache.request(
            i_mmu_req      ,
            ibus_awready   ,
            ibus_wready    ,
            ibus_bid       ,
            ibus_bresp     ,
            ibus_bvalid    ,
            ibus_arready   ,
            ibus_rid       ,
            ibus_rdata     ,
            ibus_rresp     ,
            ibus_rlast     ,
            ibus_rvalid
        );
        dcache.request(
            d_mmu_req      ,
            dbus_awready   ,
            dbus_wready    ,
            dbus_bid       ,
            dbus_bresp     ,
            dbus_bvalid    ,
            dbus_arready   ,
            dbus_rid       ,
            dbus_rdata     ,
            dbus_rresp     ,
            dbus_rlast     ,
            dbus_rvalid
        );
    endmethod

    method Bit#(4)   ibus_awid     =       icache.get_AW.i_awid     ;
    method Bit#(32)  ibus_awaddr   =       icache.get_AW.i_awaddr   ;
    method Bit#(4)   ibus_awlen    =       icache.get_AW.i_awlen    ;
    method Bit#(3)   ibus_awsize   =       icache.get_AW.i_awsize   ;
    method Bit#(2)   ibus_awburst  =       icache.get_AW.i_awburst  ;
    method Bit#(2)   ibus_awlock   =       icache.get_AW.i_awlock   ;
    method Bit#(4)   ibus_awcache  =       icache.get_AW.i_awcache  ;
    method Bit#(3)   ibus_awprot   =       icache.get_AW.i_awprot   ;
    method Bool      ibus_awvalid  =       icache.get_AW.i_awvalid  ;

    method Bit#(4)   ibus_wid      =       icache.get_W.i_wid       ;
    method Bit#(32)  ibus_wdata    =       icache.get_W.i_wdata     ;
    method Bool      ibus_wlast    =       icache.get_W.i_wlast     ;
    method Bit#(4)   ibus_wstrb    =       icache.get_W.i_wstrb     ;
    method Bool      ibus_wvalid   =       icache.get_W.i_wvalid    ;

    method Bool      ibus_bready   =       icache.get_bready        ;

    method Bit#(4)   ibus_arid     =       icache.get_AR.i_arid     ;
    method Bit#(32)  ibus_araddr   =       icache.get_AR.i_araddr   ;
    method Bit#(4)   ibus_arlen    =       icache.get_AR.i_arlen    ;
    method Bit#(3)   ibus_arsize   =       icache.get_AR.i_arsize   ;
    method Bit#(2)   ibus_arburst  =       icache.get_AR.i_arburst  ;
    method Bit#(2)   ibus_arlock   =       icache.get_AR.i_arlock   ;
    method Bit#(4)   ibus_arcache  =       icache.get_AR.i_arcache  ;
    method Bit#(3)   ibus_arprot   =       icache.get_AR.i_arprot   ;
    method Bool      ibus_arvalid  =       icache.get_AR.i_arvalid  ;

    method Bool      ibus_rready   =       icache.get_rready        ;

    method Bit#(4)   dbus_awid     =       dcache.get_AW.d_awid     ;
    method Bit#(32)  dbus_awaddr   =       dcache.get_AW.d_awaddr   ;
    method Bit#(4)   dbus_awlen    =       dcache.get_AW.d_awlen    ;
    method Bit#(3)   dbus_awsize   =       dcache.get_AW.d_awsize   ;
    method Bit#(2)   dbus_awburst  =       dcache.get_AW.d_awburst  ;
    method Bit#(2)   dbus_awlock   =       dcache.get_AW.d_awlock   ;
    method Bit#(4)   dbus_awcache  =       dcache.get_AW.d_awcache  ;
    method Bit#(3)   dbus_awprot   =       dcache.get_AW.d_awprot   ;
    method Bool      dbus_awvalid  =       dcache.get_AW.d_awvalid  ;
 
    method Bit#(4)   dbus_wid      =       dcache.get_W.d_wid       ;
    method Bit#(32)  dbus_wdata    =       dcache.get_W.d_wdata     ;
    method Bool      dbus_wlast    =       dcache.get_W.d_wlast     ;
    method Bit#(4)   dbus_wstrb    =       dcache.get_W.d_wstrb     ;
    method Bool      dbus_wvalid   =       dcache.get_W.d_wvalid    ;
 
    method Bool      dbus_bready   =       dcache.get_bready        ;
 
    method Bit#(4)   dbus_arid     =       dcache.get_AR.d_arid     ;
    method Bit#(32)  dbus_araddr   =       dcache.get_AR.d_araddr   ;
    method Bit#(4)   dbus_arlen    =       dcache.get_AR.d_arlen    ;
    method Bit#(3)   dbus_arsize   =       dcache.get_AR.d_arsize   ;
    method Bit#(2)   dbus_arburst  =       dcache.get_AR.d_arburst  ;
    method Bit#(2)   dbus_arlock   =       dcache.get_AR.d_arlock   ;
    method Bit#(4)   dbus_arcache  =       dcache.get_AR.d_arcache  ;
    method Bit#(3)   dbus_arprot   =       dcache.get_AR.d_arprot   ;
    method Bool      dbus_arvalid  =       dcache.get_AR.d_arvalid  ;

    method Bool      dbus_rready   =       dcache.get_rready        ;


    method Addr      debug_wb_pc       =   cpu.getDebugInfo.pc      ;
    method Bit#(4)   debug_wb_rf_wen   =   cpu.getDebugInfo.wen? 4'hf: 4'h0;
    method Bit#(5)   debug_wb_rf_wnum  =   cpu.getDebugInfo.wnum    ;
    method Bit#(32)  debug_wb_rf_wdata =   cpu.getDebugInfo.wdata   ;


endmodule
endpackage