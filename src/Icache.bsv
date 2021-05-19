package Icache;
import RegFile::*;
import BRAMCore :: *;
import def_types :: *;
typedef struct {
    Bit#(20) tag;
    Bit#(512) data;
    Bool dirty;
    Bool valid;
    MMU_Req mmureq;
} Cacheline deriving(Eq,Bits);
//类型定义
//地址类型定义
typedef Bit#(32) Addr;
//32位数据定义
typedef Bit#(32) SData;
//512位数据定义
typedef Bit#(512) Data;
//参考axi中的信号进行定义，这部分是读地址
typedef Bit#(4)     Arid;
typedef Bit#(32)    Araddr;
typedef Bit#(4)     Arlen;
typedef Bit#(3)     Arsize;
typedef Bit#(2)     Arburst;
typedef Bit#(2)     Arlock;
typedef Bit#(4)     Arcache;
typedef Bit#(3)     Arprot;
typedef Bool        Arvalid;
typedef Bool        Arready;
//读数据相关信号
typedef Bit#(4)     Rid ;
typedef Bit#(32)    Rdata;
typedef Bit#(2)     Rresp; 
typedef Bool        Rlast;
typedef Bool        Rvalid;
typedef Bool        Rready;
 //写地址相关信号
typedef Bit#(4)     Awid;
typedef Bit#(32)    Awaddr;
typedef Bit#(4)     Awlen;
typedef Bit#(3)     Awsize;
typedef Bit#(2)     Awburst;
typedef Bit#(2)     Awlock;
typedef Bit#(4)     Awcache;
typedef Bit#(3)     Awprot;
typedef Bool        Awvalid;
typedef Bool        Awready;
//写数据相关信号定义
typedef Bit#(4)     Wid;
typedef Bit#(32)    Wdata;
typedef Bit#(4)     Wstrb;
typedef Bool        Wlast;
typedef Bool        Wvalid;
typedef Bool        Wready;



//写返回相关数据
typedef Bit#(4)     Bid;
typedef Bit#(2)     Bresp;
typedef Bool        Bvalid;
typedef Bool        Bready;


//字节使能信号定义，以及计数信号定义
typedef Bit#(4)     Str;
typedef Bit#(4)    CNT;
//结构体定义
//axi读地址结构体定义
typedef struct{
    Arid       i_arid      ;              
    Araddr     i_araddr    ;
    Arlen      i_arlen     ;
    Arsize     i_arsize    ;
    Arburst    i_arburst   ;
    Arlock     i_arlock    ;
    Arcache    i_arcache   ;
    Arprot     i_arprot    ;
    Arvalid    i_arvalid   ;   
}AXI_Read_Addr deriving(Eq,Bits);
//axi读数据
// typedef struct{
//     Rid             i_rid         ;
//     Rresp           i_rresp       ;
//     Rlast           i_rlast       ;
//     Rvalid          i_rvalid      ;
//     Rready          i_rready      ;
// }AXI_Read_Data  deriving(Eq,Bits);
//axi写数据定义
typedef struct{
    Wid         i_wid      ;              
    Wdata       i_wdata    ;
    Wstrb       i_wstrb    ;
    Wvalid      i_wvalid   ;
    Bool        i_wlast ;
}AXI_Write_Data deriving(Eq,Bits);
//axi写地址
typedef struct{
    Awid       i_awid      ;              
    Awaddr     i_awaddr    ;
    Awlen      i_awlen     ;
    Awsize     i_awsize    ;
    Awburst    i_awburst   ;
    Awlock     i_awlock    ;
    Awcache    i_awcache   ;
    Awprot     i_awprot    ;
    Awvalid    i_awvalid   ;
}AXI_Write_Addr deriving(Eq,Bits);

//axi反回，这部分是超标量相关的，这里并不用

//ld模块的输入
//typedef struct{
//    Str  str;
//    Addr addr;
//    Bool en;
//    Data data;
//    Bool badaddr;
//    Bool typ;
//    
//}LD_Req deriving(Eq, Bits);
////st模块的输入
//typedef struct{
//    Str  str;
//    Addr addr;
//    Bool en;
//    Data data;
//    Bool badaddr;
//    Bool typ;
//    
//}ST_Req deriving(Eq, Bits);
//
//
////cache给rob的输出
//typedef struct{
//    Data hit_data;
//    Str  str;
//    Addr ld_addr;
//    Addr st_addr;
//}   Cache_Req deriving(Eq,Bits);
//接口定义


// //mmu传过来的一些信号，包括使能信号。字节使能信号，4个0表示读，剩下的表示写
// typedef struct{
//     Bool en;
//     Bit#(4) be;
//     Addr addr;
//     Bit#(32) data;
//     Bool cache_en;   
// }MMU_Req deriving(Eq, Bits);


//接口定义
interface ICache_IFC;
    method Action request(      
        MMU_Req     mmu_req     ,
        Awready     i_awready   ,
        Wready      i_wready    ,
        Bid         i_bid       ,
        Bresp       i_bresp     ,
        Bvalid      i_bvalid    ,
        Arready     i_arready   ,
        Rid         i_rid       ,
        Rdata       i_rdata     ,
        Rresp       i_rresp     ,
        Rlast       i_rlast     ,
        Rvalid      i_rvalid
    );
    method  Bit#(32)        get_rdata(Bool i_rvalid, Bit#(32) i_rdata)  ;
    method  Bool            get_pause(Bool i_rvalid)                    ;
    method  AXI_Write_Addr  get_AW                                      ;
    method  AXI_Write_Data  get_W                                       ;
    method  Bool            get_bready                                  ;
    method  AXI_Read_Addr   get_AR                                      ;
    method  Bool            get_rready                                  ;
endinterface


    //状态定义
    typedef enum {  IDLE                        ,
                    CACHE_WRITEBACK_PREPARED    ,
                    CACHE_WRITEBACK_TRANSFER    ,
                    CACHE_MISS_W_PREPARE        ,
                    CACHE_MISS_W_TRANSFER       ,
                    CACHE_MISS_R_FINISH         ,
                    UNCACHE_R_PREPARE           ,
                    UNCACHE_R_TRANSFER          ,
                    UNCACHE_W_PREPARE           ,
                    UNCACHE_W_TRANSFER
    } CacheStatus deriving (Bits, Eq);

   //cache输出
   (*synthesize*)
    module mkICache(ICache_IFC);
   
        Reg#(MMU_Req) saved_mmureq <- mkReg(unpack(0));
        Reg#(Cacheline) saved_cacheline <- mkReg(unpack(0));
      
        Reg#(CacheStatus) saved_status <- mkReg(IDLE);
        Reg#(Bool)        saved_specialcase <- mkReg(False);

       //   });

//定义了一个tag域和data域，6位索引，data每一个字32位，共512字

        BRAM_PORT#(Bit#(6),Bit#(20))        icache_tag  <- mkBRAMCore1(64,False);//定义了一个tag域，6位索引，共20字
        BRAM_PORT_BE#(Bit#(6),Bit#(512),64) icache_data <- mkBRAMCore1BE(64,False);//定义了data域，6位索引，512字，64行

        RegFile#(Bit#(6),Bool) dirtyArray <-mkRegFileFull;//用寄存器堆定义了脏域

        Reg#(Bool) validArray[64];//用寄存器堆定义了有效位 
        for(Integer i = 0; i < 64; i = i + 1)
            validArray[i] <- mkReg(False);

       // Reg#(WB_Req)wb_req<-mkReg(WB_Req{data:0,
       //                                  addr:0
       // });
        Reg#(CNT)               cnt         <- mkReg(0);//定义的数寄存器，也就是传写数据的时候来数每一个数哪个是最后一个
        Reg#(CacheStatus)       status      <- mkReg(IDLE);//状态寄存器
        Reg#(Bool)              saved_dirty <- mkReg(False);
        Reg#(Bool)              saved_valid <- mkReg(False);
       

      
        function Bit#(20) getTag(Addr addr)     =addr[31:12];//函数定义，得到tag
        function Bit#(6) getIdx(Addr addr)      =addr[11:6];//函数定义，得到idx
        function Bit#(4) getOffset(Addr addr)   =addr[5:2];//函数定义，得到offset


//======================================================================


method Bit#(32) get_rdata(Bool i_rvalid, Bit#(32) i_rdata);
    let data = icache_data.read;
    let offset = getOffset((saved_status == CACHE_MISS_R_FINISH)? saved_cacheline.mmureq.addr: saved_mmureq.addr);
    let least = {offset, 5'b0};
    let significant = {offset, 5'h1f};
    if(status == UNCACHE_R_TRANSFER && i_rvalid) return i_rdata;
    else                                         return data[significant:least];
endmethod


method Bool get_pause(Bool i_rvalid);
    let en      = saved_mmureq.en;
    let tag     = getTag(saved_mmureq.addr);
    let lastTag = icache_tag.read;
    let hit     = (tag==lastTag && saved_valid);
    if(status == UNCACHE_R_TRANSFER && i_rvalid)
        return False;
    else if(status == IDLE) begin
        if(saved_status != IDLE && !saved_specialcase) return False;
        else if((en && !hit) || (en && !saved_mmureq.cache_en))
            return True;
        else 
            return False;
    end
    else return True;
endmethod

method Bool get_bready = True;

method AXI_Write_Addr get_AW();
    if(status == CACHE_WRITEBACK_PREPARED)
        return AXI_Write_Addr {
            i_awid:    0,
            i_awaddr:  {saved_cacheline.tag, getIdx(saved_cacheline.mmureq.addr), 6'b0},//{saved_cacheline.mmureq.addr[31:7], 7'b0},
            i_awlen:   15,
            i_awsize:  3'b010,
            i_awburst: 2'b01,
            i_awlock:  2'b00,
            i_awcache: 4'b0,
            i_awprot:  3'b000,
            i_awvalid: True
        };
    else if(status == UNCACHE_W_PREPARE)
        return AXI_Write_Addr {
            i_awid:    0,
            i_awaddr:  saved_cacheline.mmureq.addr,//{saved_mmureq.addr[31:7], 7'b0},
            i_awlen:   0,
            i_awsize:  3'b010,
            i_awburst: 2'b01,
            i_awlock:  2'b00,
            i_awcache: 4'b0,
            i_awprot:  3'b000,
            i_awvalid: True
        };
    else
        return unpack(0);
endmethod

method AXI_Write_Data get_W();
    if(status == CACHE_WRITEBACK_TRANSFER) begin
        let least = {cnt[3:0], 5'b0};
        let significant = {cnt[3:0], 5'h1f};
        return AXI_Write_Data {
            i_wid:    0,
            i_wdata:  saved_cacheline.data[significant:least],
            i_wstrb:  'hf,
            i_wvalid: True,
            i_wlast:   (cnt == 15)
        };
    end
    else if(status == UNCACHE_W_TRANSFER)
        return AXI_Write_Data {
            i_wid:    0,
            i_wdata:  saved_cacheline.mmureq.data,
            i_wstrb:  saved_cacheline.mmureq.be,
            i_wvalid: True,
            i_wlast:  True
        };
    else
        return unpack(0);
endmethod

method AXI_Read_Addr get_AR();
    if(status == CACHE_MISS_W_PREPARE) begin
        return AXI_Read_Addr{
            i_arid:    0,
            i_araddr:  {saved_cacheline.mmureq.addr[31:6], 6'b0},
            i_arlen:   15,
            i_arsize:  3'b010,
            i_arburst: 2'b01,
            i_arlock:  2'b00,
            i_arcache: 4'b0,
            i_arprot:  3'b000,
            i_arvalid: True
        };
    end
    else if(status == UNCACHE_R_PREPARE) begin
        return AXI_Read_Addr{
            i_arid:    0,
            i_araddr:  saved_cacheline.mmureq.addr,//{saved_cacheline.mmureq.addr[31:7], 7'b0},
            i_arlen:   0,
            i_arsize:  3'b010,
            i_arburst: 2'b01,
            i_arlock:  2'b00,
            i_arcache: 4'b0,
            i_arprot:  3'b000,
            i_arvalid: True
        };
    end
    else return unpack(0);
endmethod

method Bool get_rready();
    return (status == CACHE_MISS_W_TRANSFER || status == UNCACHE_R_TRANSFER);
endmethod

//主体部分，包括状态转换
method Action request(      
                            MMU_Req     mmu_req     ,
                            Awready     i_awready   ,
                            Wready      i_wready    ,
                            Bid         i_bid       ,
                            Bresp       i_bresp     ,
                            Bvalid      i_bvalid    ,
                            Arready     i_arready   ,
                            Rid         i_rid       ,
                            Rdata       i_rdata     ,
                            Rresp       i_rresp     ,
                            Rlast       i_rlast     ,
                            Rvalid      i_rvalid
                            );
    saved_status <= status;
    let en      = saved_mmureq.en;
    let idx     = getIdx(mmu_req.addr);
    let dirty   = dirtyArray.sub(idx);//读dirty
    let valid   = validArray[idx];
    let tag     = getTag(saved_mmureq.addr);
    let offset  = getOffset(mmu_req.addr);
    let lastTag = icache_tag.read;
    // let offset_hi  = {offset,5'b00000};
    // let offset_low = {offset,5'b11111};
    let data       = icache_data.read;
    

    saved_specialcase <= status == UNCACHE_R_TRANSFER && i_rvalid;
    saved_dirty <= dirty;
    saved_valid <= valid;
    saved_mmureq <= mmu_req;

    let hit     = en && (tag==lastTag) && saved_valid && saved_mmureq.cache_en;//判断命中

    Bool icache_tag_en = False;
    Bit#(6) icache_tag_idx = idx;
    Bit#(20) icache_tag_data = 0;

    Bit#(64) icache_data_be = 0;
    Bit#(6) icache_data_idx = 0;
    Bit#(512) icache_data_dataline = 0;

    Bool will_wr_dirtyArray = False;
    Bit#(6) dirtyArray_idx = 0;
    Bool dirtyArray_data = False;

    Bool will_wr_validArray = False;
    Bit#(6) validArray_idx = 0;
    Bool validArray_data = False;

    let staged_mmureq = saved_mmureq;

    let be = (!mmu_req.en || mmu_req.be == 4'b0 || (!hit && dirty) || !mmu_req.cache_en)? 64'b0: ({60'b0,mmu_req.be} << {getOffset(mmu_req.addr), 2'b0});
    let line_data = {480'b0,mmu_req.data} << {getOffset(mmu_req.addr), 5'b0};

    if(status == IDLE) begin
        
        icache_tag_en = False;
        icache_tag_idx = idx;
        icache_tag_data = 0;

        icache_data_be = be;
        icache_data_idx = idx;
        icache_data_dataline = line_data;
        
        will_wr_dirtyArray = (be != 'b0);
        dirtyArray_idx = idx;
        dirtyArray_data = (be != 'b0);
        
        if(mmu_req.en && !mmu_req.cache_en) begin
            icache_data_be = 0;
            staged_mmureq = mmu_req;
            if(mmu_req.be == 0) status <= UNCACHE_R_PREPARE;
            else                status <= UNCACHE_W_PREPARE;
        end
        else if(en && !hit && saved_dirty && saved_valid) begin
        icache_data_be = 0;
            status <= CACHE_WRITEBACK_PREPARED;
        end
        else if(en && ((!hit && !saved_dirty) || !saved_valid)) begin
        icache_data_be = 0;
            status <= CACHE_MISS_W_PREPARE;
        end
        saved_cacheline <= Cacheline {
            tag: lastTag,
            valid: saved_valid,
            data: data,
            dirty: saved_dirty,
            mmureq: staged_mmureq
        };
    end


    // 写回准备
    else if(status == CACHE_WRITEBACK_PREPARED) begin
        if(i_awready) status <= CACHE_WRITEBACK_TRANSFER;

        will_wr_validArray = True;
        validArray_idx = getIdx(saved_cacheline.mmureq.addr);
        validArray_data = False;

        cnt <= 0;
    end


    // 写回传输
    else if(status == CACHE_WRITEBACK_TRANSFER) begin
        if(i_wready) begin
            cnt <= cnt + 1;
            if(cnt == 15) status <= CACHE_MISS_W_PREPARE;
        end
    end

    // 读取准备
    else if(status == CACHE_MISS_W_PREPARE) begin
        if(i_arready) status <= CACHE_MISS_W_TRANSFER;
        cnt <= 0;
        
        icache_tag_en = True;
        icache_tag_idx = getIdx(saved_cacheline.mmureq.addr);
        icache_tag_data = getTag(saved_cacheline.mmureq.addr);
        
        will_wr_validArray = True;
        validArray_idx = getIdx(saved_cacheline.mmureq.addr);
        validArray_data = True;

        will_wr_dirtyArray = True;
        dirtyArray_idx = getIdx(saved_cacheline.mmureq.addr);
        dirtyArray_data = (saved_cacheline.mmureq.be != 4'b0);
        
    end


    // 读取传输
    else if(status == CACHE_MISS_W_TRANSFER) begin
        if(i_rvalid) begin
            let word_be = saved_cacheline.mmureq.be;
            Bit#(32) word_data = i_rdata;
            if(word_be[0] == 1) word_data[7 : 0] = saved_cacheline.mmureq.data[7 : 0];
            if(word_be[1] == 1) word_data[15: 8] = saved_cacheline.mmureq.data[15: 8];
            if(word_be[2] == 1) word_data[23:16] = saved_cacheline.mmureq.data[23:16];
            if(word_be[3] == 1) word_data[31:24] = saved_cacheline.mmureq.data[31:24];
            let be = 64'b1111 << {cnt, 2'b0};
            let data1 =((saved_cacheline.mmureq.be != 4'b0) && (cnt == getOffset(saved_cacheline.mmureq.addr)))?
                        word_data:
                        i_rdata;
            let line_data = {480'b0, data1} << {cnt, 5'b0};
            
            icache_data_be = be;
            icache_data_idx = getIdx(saved_cacheline.mmureq.addr);
            icache_data_dataline = line_data;

            cnt <= cnt + 1;
            if(i_rlast) begin
                status <= (saved_cacheline.mmureq.be != 4'b0)? IDLE: CACHE_MISS_R_FINISH;
            end
        end
    end

    // 读取完成
    else if(status == CACHE_MISS_R_FINISH) begin
        icache_data_be = 64'b0;
        icache_data_idx = getIdx(saved_cacheline.mmureq.addr);
        icache_data_dataline = 0;

        status <= IDLE;
    end

    // uncache读准备
    else if(status == UNCACHE_R_PREPARE) begin
        if(i_arready) status <= UNCACHE_R_TRANSFER;
    end
    // uncache读传输
    else if(status == UNCACHE_R_TRANSFER) begin
        if(i_rvalid) begin
            if(mmu_req.en && !mmu_req.cache_en) begin
                staged_mmureq = mmu_req;
                if(mmu_req.be == 0) status <= UNCACHE_R_PREPARE;
                else                status <= UNCACHE_W_PREPARE;
            end
            else if(saved_mmureq.cache_en && en && !hit && saved_dirty)
                status <= CACHE_WRITEBACK_PREPARED;
            else if(saved_mmureq.cache_en && en && !hit && !saved_dirty)
                status <= CACHE_MISS_W_PREPARE;
            else
                status <= IDLE;

            saved_cacheline <= Cacheline {
                tag: lastTag,
                valid: saved_valid,
                data: data,
                dirty: saved_dirty,
                mmureq: staged_mmureq
            };

            
            icache_data_be = be;
            icache_data_idx = idx;
            icache_data_dataline = line_data;
        end
    end

    // uncache写准备
    else if(status == UNCACHE_W_PREPARE) begin
        if(i_awready) status <= UNCACHE_W_TRANSFER;
    end
    // uncache写传输
    else if(status == UNCACHE_W_TRANSFER) begin
        if(i_wready)  status <= IDLE;
    end


    icache_tag.put(icache_tag_en,icache_tag_idx,icache_tag_data);
    icache_data.put(icache_data_be, icache_data_idx, icache_data_dataline);
    if(will_wr_dirtyArray) dirtyArray.upd(dirtyArray_idx, dirtyArray_data);
    if(will_wr_validArray) validArray[validArray_idx] <= validArray_data;

endmethod


//======================================================================




endmodule

endpackage
