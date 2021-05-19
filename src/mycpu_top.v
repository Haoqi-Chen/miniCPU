
module mycpu_top
(
    input  wire         aclk,
    input  wire         aresetn,
    input  wire [ 5: 0] ext_int,

    output wire [ 3: 0] arid,
    output wire [31: 0] araddr,
    output wire [ 3: 0] arlen,
    output wire [ 2: 0] arsize,
    output wire [ 1: 0] arburst,
    output wire [ 1: 0] arlock,
    output wire [ 3: 0] arcache,
    output wire [ 2: 0] arprot,
    output wire         arvalid,
    input  wire         arready,

    input  wire [ 3: 0] rid,
    input  wire [31: 0] rdata,
    input  wire [ 1: 0] rresp,
    input  wire         rlast,
    input  wire         rvalid,
    output wire         rready,

    output wire [ 3: 0] awid,
    output wire [31: 0] awaddr,
    output wire [ 3: 0] awlen,
    output wire [ 2: 0] awsize,
    output wire [ 1: 0] awburst,
    output wire [ 1: 0] awlock,
    output wire [ 3: 0] awcache,
    output wire [ 2: 0] awprot,
    output wire         awvalid,
    input  wire         awready,

    output wire [ 3: 0] wid,
    output wire [31: 0] wdata,
    output wire [ 3: 0] wstrb,
    output wire         wlast,
    output wire         wvalid,
    input  wire         wready,

    input  wire [ 3: 0] bid,
    input  wire [ 1: 0] bresp,
    input  wire         bvalid,
    output wire         bready,

    
    output wire [31: 0] debug_wb_pc      ,
    output wire [ 3: 0] debug_wb_rf_wen  ,
    output wire [ 4: 0] debug_wb_rf_wnum ,
    output wire [31: 0] debug_wb_rf_wdata
);

    wire [ 3: 0] ibus_arid;
    wire [31: 0] ibus_araddr;
    wire [ 3: 0] ibus_arlen;
    wire [ 2: 0] ibus_arsize;
    wire [ 1: 0] ibus_arburst;
    wire [ 1: 0] ibus_arlock;
    wire [ 3: 0] ibus_arcache;
    wire [ 2: 0] ibus_arprot;
    wire         ibus_arvalid;
    wire         ibus_arready;
    wire [ 3: 0] ibus_rid;
    wire [31: 0] ibus_rdata;
    wire [ 1: 0] ibus_rresp;
    wire         ibus_rlast;
    wire         ibus_rvalid;
    wire         ibus_rready;
    wire [ 3: 0] ibus_awid;
    wire [31: 0] ibus_awaddr;
    wire [ 3: 0] ibus_awlen;
    wire [ 2: 0] ibus_awsize;
    wire [ 1: 0] ibus_awburst;
    wire [ 1: 0] ibus_awlock;
    wire [ 3: 0] ibus_awcache;
    wire [ 2: 0] ibus_awprot;
    wire         ibus_awvalid;
    wire         ibus_awready;
    wire [ 3: 0] ibus_wid;
    wire [31: 0] ibus_wdata;
    wire [ 3: 0] ibus_wstrb;
    wire         ibus_wlast;
    wire         ibus_wvalid;
    wire         ibus_wready;
    wire [ 3: 0] ibus_bid;
    wire [ 1: 0] ibus_bresp;
    wire         ibus_bvalid;
    wire         ibus_bready;

    wire [ 3: 0] dbus_arid;
    wire [31: 0] dbus_araddr;
    wire [ 3: 0] dbus_arlen;
    wire [ 2: 0] dbus_arsize;
    wire [ 1: 0] dbus_arburst;
    wire [ 1: 0] dbus_arlock;
    wire [ 3: 0] dbus_arcache;
    wire [ 2: 0] dbus_arprot;
    wire         dbus_arvalid;
    wire         dbus_arready;
    wire [ 3: 0] dbus_rid;
    wire [31: 0] dbus_rdata;
    wire [ 1: 0] dbus_rresp;
    wire         dbus_rlast;
    wire         dbus_rvalid;
    wire         dbus_rready;
    wire [ 3: 0] dbus_awid;
    wire [31: 0] dbus_awaddr;
    wire [ 3: 0] dbus_awlen;
    wire [ 2: 0] dbus_awsize;
    wire [ 1: 0] dbus_awburst;
    wire [ 1: 0] dbus_awlock;
    wire [ 3: 0] dbus_awcache;
    wire [ 2: 0] dbus_awprot;
    wire         dbus_awvalid;
    wire         dbus_awready;
    wire [ 3: 0] dbus_wid;
    wire [31: 0] dbus_wdata;
    wire [ 3: 0] dbus_wstrb;
    wire         dbus_wlast;
    wire         dbus_wvalid;
    wire         dbus_wready;
    wire [ 3: 0] dbus_bid;
    wire [ 1: 0] dbus_bresp;
    wire         dbus_bvalid;
    wire         dbus_bready;

    mkAXIcache axicache(
          .CLK(aclk),
		  .RST_N(aresetn),

		  .step_exc_int             (ext_int),
		  .step_ibus_awready        (ibus_awready),
		  .step_ibus_wready         (ibus_wready),
		  .step_ibus_bid            (ibus_bid    ),
		  .step_ibus_bresp          (ibus_bresp  ),
		  .step_ibus_bvalid         (ibus_bvalid ),
		  .step_ibus_arready        (ibus_arready),
		  .step_ibus_rid            (ibus_rid    ),
		  .step_ibus_rdata          (ibus_rdata  ),
		  .step_ibus_rresp          (ibus_rresp  ),
		  .step_ibus_rlast          (ibus_rlast  ),
		  .step_ibus_rvalid         (ibus_rvalid ),
		  .step_dbus_awready        (dbus_awready),
		  .step_dbus_wready         (dbus_wready ),
		  .step_dbus_bid            (dbus_bid    ),
		  .step_dbus_bresp          (dbus_bresp  ),
		  .step_dbus_bvalid         (dbus_bvalid ),
		  .step_dbus_arready        (dbus_arready),
		  .step_dbus_rid            (dbus_rid    ),
		  .step_dbus_rdata          (dbus_rdata  ),
		  .step_dbus_rresp          (dbus_rresp  ),
		  .step_dbus_rlast          (dbus_rlast  ),
		  .step_dbus_rvalid         (dbus_rvalid ),

		  .ibus_awid                (ibus_awid        ),

		  .ibus_awaddr              (ibus_awaddr      ),

		  .ibus_awlen               (ibus_awlen       ),

		  .ibus_awsize              (ibus_awsize      ),

		  .ibus_awburst             (ibus_awburst     ),

		  .ibus_awlock              (ibus_awlock      ),

		  .ibus_awcache             (ibus_awcache     ),

		  .ibus_awprot              (ibus_awprot      ),

		  .ibus_awvalid             (ibus_awvalid     ),

		  .ibus_wid                 (ibus_wid         ),

		  .ibus_wdata               (ibus_wdata       ),

		  .ibus_wstrb               (ibus_wstrb       ),

		  .ibus_wlast               (ibus_wlast       ),

		  .ibus_wvalid              (ibus_wvalid      ),

		  .ibus_bready              (ibus_bready      ),

		  .ibus_arid                (ibus_arid        ),

		  .ibus_araddr              (ibus_araddr      ),

		  .ibus_arlen               (ibus_arlen       ),

		  .ibus_arsize              (ibus_arsize      ),

		  .ibus_arburst             (ibus_arburst     ),

		  .ibus_arlock              (ibus_arlock      ),

		  .ibus_arcache             (ibus_arcache     ),

		  .ibus_arprot              (ibus_arprot      ),

		  .ibus_arvalid             (ibus_arvalid     ),

		  .ibus_rready              (ibus_rready      ),

		  .dbus_awid                (dbus_awid        ),

		  .dbus_awaddr              (dbus_awaddr      ),

		  .dbus_awlen               (dbus_awlen       ),

		  .dbus_awsize              (dbus_awsize      ),

		  .dbus_awburst             (dbus_awburst     ),

		  .dbus_awlock              (dbus_awlock      ),

		  .dbus_awcache             (dbus_awcache     ),

		  .dbus_awprot              (dbus_awprot      ),

		  .dbus_awvalid             (dbus_awvalid     ),

		  .dbus_wid                 (dbus_wid         ),

		  .dbus_wdata               (dbus_wdata       ),

		  .dbus_wlast               (dbus_wlast       ),

		  .dbus_wstrb               (dbus_wstrb       ),

		  .dbus_wvalid              (dbus_wvalid      ),

		  .dbus_bready              (dbus_bready      ),

		  .dbus_arid                (dbus_arid        ),

		  .dbus_araddr              (dbus_araddr      ),

		  .dbus_arlen               (dbus_arlen       ),

		  .dbus_arsize              (dbus_arsize      ),

		  .dbus_arburst             (dbus_arburst     ),

		  .dbus_arlock              (dbus_arlock      ),

		  .dbus_arcache             (dbus_arcache     ),

		  .dbus_arprot              (dbus_arprot      ),

		  .dbus_arvalid             (dbus_arvalid     ),

		  .dbus_rready              (dbus_rready      ),

		  .debug_wb_pc              (debug_wb_pc      ),

		  .debug_wb_rf_wen          (debug_wb_rf_wen  ),

		  .debug_wb_rf_wnum         (debug_wb_rf_wnum ),

		  .debug_wb_rf_wdata        (debug_wb_rf_wdata));

        // axi_crossbar_1x2 (
        //     .aclk                   (),
        //     .aresetn                (),
        //     .s_axi_awid             ( awid    ),
        //     .s_axi_awaddr           ( awaddr  ),
        //     .s_axi_awlen            ( awlen   ),
        //     .s_axi_awsize           ( awsize  ),
        //     .s_axi_awburst          ( awburst ),
        //     .s_axi_awlock           ( awlock  ),
        //     .s_axi_awcache          ( awcache ),
        //     .s_axi_awprot           ( awprot  ),
        //     .s_axi_awqos            ( awqos   ),
        //     .s_axi_awvalid          ( awvalid ),
        //     .s_axi_awready          ( awready ),
        //     .s_axi_wid              ( wid     ),
        //     .s_axi_wdata            ( wdata   ),
        //     .s_axi_wstrb            ( wstrb   ),
        //     .s_axi_wlast            ( wlast   ),
        //     .s_axi_wvalid           ( wvalid  ),
        //     .s_axi_wready           ( wready  ),
        //     .s_axi_bid              ( bid     ),
        //     .s_axi_bresp            ( bresp   ),
        //     .s_axi_bvalid           ( bvalid  ),
        //     .s_axi_bready           ( bready  ),
        //     .s_axi_arid             ( arid    ),
        //     .s_axi_araddr           ( araddr  ),
        //     .s_axi_arlen            ( arlen   ),
        //     .s_axi_arsize           ( arsize  ),
        //     .s_axi_arburst          ( arburst ),
        //     .s_axi_arlock           ( arlock  ),
        //     .s_axi_arcache          ( arcache ),
        //     .s_axi_arprot           ( arprot  ),
        //     .s_axi_arqos            ( arqos   ),
        //     .s_axi_arvalid          ( arvalid ),
        //     .s_axi_arready          ( arready ),
        //     .s_axi_rid              ( rid     ),
        //     .s_axi_rdata            ( rdata   ),
        //     .s_axi_rresp            ( rresp   ),
        //     .s_axi_rlast            ( rlast   ),
        //     .s_axi_rvalid           ( rvalid  ),
        //     .s_axi_rready           ( rready  ),


        //     .m_axi_awid             ( {ibus_awid   ,dbus_awid   } ),
        //     .m_axi_awaddr           ( {ibus_awaddr ,dbus_awaddr } ),
        //     .m_axi_awlen            ( {ibus_awlen  ,dbus_awlen  } ),
        //     .m_axi_awsize           ( {ibus_awsize ,dbus_awsize } ),
        //     .m_axi_awburst          ( {ibus_awburst,dbus_awburst} ),
        //     .m_axi_awlock           ( {ibus_awlock ,dbus_awlock } ),
        //     .m_axi_awcache          ( {ibus_awcache,dbus_awcache} ),
        //     .m_axi_awprot           ( {ibus_awprot ,dbus_awprot } ),
        //     .m_axi_awqos            ( 0                           ),
        //     .m_axi_awvalid          ( {ibus_awvalid,dbus_awvalid} ),
        //     .m_axi_awready          ( {ibus_awready,dbus_awready} ),
        //     .m_axi_wid              ( {ibus_wid    ,dbus_wid    } ),
        //     .m_axi_wdata            ( {ibus_wdata  ,dbus_wdata  } ),
        //     .m_axi_wstrb            ( {ibus_wstrb  ,dbus_wstrb  } ),
        //     .m_axi_wlast            ( {ibus_wlast  ,dbus_wlast  } ),
        //     .m_axi_wvalid           ( {ibus_wvalid ,dbus_wvalid } ),
        //     .m_axi_wready           ( {ibus_wready ,dbus_wready } ),
        //     .m_axi_bid              ( {ibus_bid    ,dbus_bid    } ),
        //     .m_axi_bresp            ( {ibus_bresp  ,dbus_bresp } ),
        //     .m_axi_bvalid           ( {ibus_bvalid ,dbus_bvalid } ),
        //     .m_axi_bready           ( {ibus_bready ,dbus_bready } ),
        //     .m_axi_arid             ( {ibus_arid   ,dbus_arid   } ),
        //     .m_axi_araddr           ( {ibus_araddr ,dbus_araddr } ),
        //     .m_axi_arlen            ( {ibus_arlen  ,dbus_arlen  } ),
        //     .m_axi_arsize           ( {ibus_arsize ,dbus_arsize } ),
        //     .m_axi_arburst          ( {ibus_arburst,dbus_arburst  ),
        //     .m_axi_arlock           ( {ibus_arlock ,dbus_arlock } ),
        //     .m_axi_arcache          ( {ibus_arcache,dbus_arcache} ),
        //     .m_axi_arprot           ( {ibus_arprot ,dbus_arprot } ),
        //     .m_axi_arqos            ( 0                           ),
        //     .m_axi_arvalid          ( {ibus_arvalid,dbus_arvalid} ),
        //     .m_axi_arready          ( {ibus_arready,dbus_arready} ),
        //     .m_axi_rid              ( {ibus_rid    ,dbus_rid    } ),
        //     .m_axi_rdata            ( {ibus_rdata  ,dbus_rdata  } ),
        //     .m_axi_rresp            ( {ibus_rresp  ,dbus_rresp  } ),
        //     .m_axi_rlast            ( {ibus_rlast  ,dbus_rlast  } ),
        //     .m_axi_rvalid           ( {ibus_rvalid ,dbus_rvalid } ),
        //     .m_axi_rready           ( {ibus_rready ,dbus_rready } )
        // );





    Bus_Interface biu (
        .aclk             ( aclk     ),
        .aresetn          ( aresetn        ),
        
        .s_axi_arid       ( {ibus_arid   ,dbus_arid   } ),
        .s_axi_araddr     ( {ibus_araddr ,dbus_araddr } ),
        .s_axi_arlen      ( {ibus_arlen  ,dbus_arlen  } ),
        .s_axi_arsize     ( {ibus_arsize ,dbus_arsize } ),
        .s_axi_arburst    ( {ibus_arburst,dbus_arburst} ),
        .s_axi_arlock     ( {ibus_arlock ,dbus_arlock } ),
        .s_axi_arcache    ( {ibus_arcache,dbus_arcache} ),
        .s_axi_arprot     ( {ibus_arprot ,dbus_arprot } ),
        .s_axi_arqos      ( 0                           ),
        .s_axi_arvalid    ( {ibus_arvalid,dbus_arvalid} ),
        .s_axi_arready    ( {ibus_arready,dbus_arready} ),
        .s_axi_rid        ( {ibus_rid    ,dbus_rid    } ),
        .s_axi_rdata      ( {ibus_rdata  ,dbus_rdata  } ),
        .s_axi_rresp      ( {ibus_rresp  ,dbus_rresp  } ),
        .s_axi_rlast      ( {ibus_rlast  ,dbus_rlast  } ),
        .s_axi_rvalid     ( {ibus_rvalid ,dbus_rvalid } ),
        .s_axi_rready     ( {ibus_rready ,dbus_rready } ),
        .s_axi_awid       ( {ibus_awid   ,dbus_awid   } ),
        .s_axi_awaddr     ( {ibus_awaddr ,dbus_awaddr } ),
        .s_axi_awlen      ( {ibus_awlen  ,dbus_awlen  } ),
        .s_axi_awsize     ( {ibus_awsize ,dbus_awsize } ),
        .s_axi_awburst    ( {ibus_awburst,dbus_awburst} ),
        .s_axi_awlock     ( {ibus_awlock ,dbus_awlock } ),
        .s_axi_awcache    ( {ibus_awcache,dbus_awcache} ),
        .s_axi_awprot     ( {ibus_awprot ,dbus_awprot } ),
        .s_axi_awqos      ( 0                           ),
        .s_axi_awvalid    ( {ibus_awvalid,dbus_awvalid} ),
        .s_axi_awready    ( {ibus_awready,dbus_awready} ),
        .s_axi_wid        ( {ibus_wid    ,dbus_wid    } ),
        .s_axi_wdata      ( {ibus_wdata  ,dbus_wdata  } ),
        .s_axi_wstrb      ( {ibus_wstrb  ,dbus_wstrb  } ),
        .s_axi_wlast      ( {ibus_wlast  ,dbus_wlast  } ),
        .s_axi_wvalid     ( {ibus_wvalid ,dbus_wvalid } ),
        .s_axi_wready     ( {ibus_wready ,dbus_wready } ),
        .s_axi_bid        ( {ibus_bid    ,dbus_bid    } ),
        .s_axi_bresp      ( {ibus_bresp  ,dbus_bresp  } ),
        .s_axi_bvalid     ( {ibus_bvalid ,dbus_bvalid } ),
        .s_axi_bready     ( {ibus_bready ,dbus_bready } ),
        
        .m_axi_arid       ( arid       ),
        .m_axi_araddr     ( araddr     ),
        .m_axi_arlen      ( arlen[3:0] ),
        .m_axi_arsize     ( arsize     ),
        .m_axi_arburst    ( arburst    ),
        .m_axi_arlock     ( arlock     ),
        .m_axi_arcache    ( arcache    ),
        .m_axi_arprot     ( arprot     ),
        .m_axi_arqos      (            ),
        .m_axi_arvalid    ( arvalid    ),
        .m_axi_arready    ( arready    ),
        .m_axi_rid        ( rid        ),
        .m_axi_rdata      ( rdata      ),
        .m_axi_rresp      ( rresp      ),
        .m_axi_rlast      ( rlast      ),
        .m_axi_rvalid     ( rvalid     ),
        .m_axi_rready     ( rready     ),
        .m_axi_awid       ( awid       ),
        .m_axi_awaddr     ( awaddr     ),
        .m_axi_awlen      ( awlen[3:0] ),
        .m_axi_awsize     ( awsize     ),
        .m_axi_awburst    ( awburst    ),
        .m_axi_awlock     ( awlock     ),
        .m_axi_awcache    ( awcache    ),
        .m_axi_awprot     ( awprot     ),
        .m_axi_awqos      (            ),
        .m_axi_awvalid    ( awvalid    ),
        .m_axi_awready    ( awready    ),
        .m_axi_wid        ( wid        ),
        .m_axi_wdata      ( wdata      ),
        .m_axi_wstrb      ( wstrb      ),
        .m_axi_wlast      ( wlast      ),
        .m_axi_wvalid     ( wvalid     ),
        .m_axi_wready     ( wready     ),
        .m_axi_bid        ( bid        ),
        .m_axi_bresp      ( bresp      ),
        .m_axi_bvalid     ( bvalid     ),
        .m_axi_bready     ( bready     )
    );

endmodule