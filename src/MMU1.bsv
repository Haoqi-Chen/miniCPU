
typedef Bit#(32) Addr;
typedef Bit#(1)  OP;
import def_types :: *;



// typedef struct {
//     Bool en;
//     Bit#(4) be;
//     Addr addr;
//     Data data;
// } MemReq deriving(Bits, FShow);

// typedef struct{
//     Bool en;
//     Bit#(4) be;
//     Addr addr;
//     Data data;
//     Bool cache_en;//选走不走cache
    
// }MMU_Req deriving(Eq, Bits);





interface MMU_IFC;
    method MMU_Req mmu_reqi( MemReq mem_req);
    method MMU_Req mmu_reqd( MemReq mem_req);
endinterface 

 (*synthesize*)
module mkMMU(MMU_IFC);
    method MMU_Req  mmu_reqi(MemReq mem_req);
        if(mem_req.addr[31:29] == 'b000)
            return MMU_Req {
                arsize: mem_req.arsize,
                en : mem_req.en,
                be : mem_req.be,
                addr : mem_req.addr,
                data : mem_req.data,
                cache_en : True
            };
        else if(mem_req.addr[31:29] == 'b100)
            return MMU_Req {
                arsize: mem_req.arsize,
                en : mem_req.en,
                be : mem_req.be,
                addr : {3'b000,mem_req.addr[28:0]},
                data : mem_req.data,
                cache_en : True
            };
        else if(mem_req.addr[31:29] == 'b101)
            return MMU_Req {
                arsize: mem_req.arsize,
                en : mem_req.en,
                be : mem_req.be,
                addr : {3'b000,mem_req.addr[28:0]},
                data : mem_req.data,
                cache_en : False
            };
        else
            return MMU_Req {
                arsize: mem_req.arsize,
                en : mem_req.en,
                be : mem_req.be,
                addr : mem_req.addr,
                data : mem_req.data,
                cache_en : False
            };
    endmethod
    method MMU_Req  mmu_reqd(MemReq mem_req);
    if(mem_req.addr[31:29] == 'b000)
        return MMU_Req {
            arsize: mem_req.arsize,
            en : mem_req.en,
            be : mem_req.be,
            addr : mem_req.addr,
            data : mem_req.data,
            cache_en : True
        };
    else if(mem_req.addr[31:29] == 'b100)
        return MMU_Req {
            arsize: mem_req.arsize,
            en : mem_req.en,
            be : mem_req.be,
            addr : {3'b000,mem_req.addr[28:0]},
            data : mem_req.data,
            cache_en : True
        };
    else if(mem_req.addr[31:29] == 'b101)
        return MMU_Req {
            arsize: mem_req.arsize,
            en : mem_req.en,
            be : mem_req.be,
            addr : {3'b000,mem_req.addr[28:0]},
            data : mem_req.data,
            cache_en : False
        };
    else
        return MMU_Req {
            arsize: mem_req.arsize,
            en : mem_req.en,
            be : mem_req.be,
            addr : mem_req.addr,
            data : mem_req.data,
            cache_en : False
        };
endmethod
endmodule
       

       

       
     