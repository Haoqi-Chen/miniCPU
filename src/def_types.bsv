package def_types;

typedef (32) WordLen;

typedef struct {
    Bit#(WordLen) result;
    Bool  overflow;
} ALUout_t deriving(Bits, Eq, FShow);
//alu的输出, result表示运算结果,overflow表示是否溢出

//算术种类
typedef enum{
    ALUctr_add   ,  ALUctr_sub   ,  ALUctr_addu ,  ALUctr_subu  ,
    ALUctr_and   ,  ALUctr_or    ,  ALUctr_nor  ,  ALUctr_xor   ,
    ALUctr_slt   ,  ALUctr_sltu  ,  ALUctr_eq   ,  ALUctr_neq   ,
    ALUctr_gtz   ,  ALUctr_gez   ,  ALUctr_ltz  ,  ALUctr_lez   ,
    ALUctr_sll   ,  ALUctr_srl   ,  ALUctr_sra  ,  ALUctr_mul   ,
    ALUctr_mult  ,  ALUctr_multu ,  ALUctr_div  ,  ALUctr_divu  ,
    ALUctr_madd  ,  ALUctr_maddu ,  ALUctr_msub ,  ALUctr_msubu ,
    ALUctr_clo   ,  ALUctr_clz   ,  ALUctr_ge   ,  ALUctr_geu   ,
    ALUctr_lt    ,  ALUctr_ltu   
} ALUctr deriving(Bits, FShow, Eq);

typedef Bit#(WordLen) Addr;
typedef Bit#(WordLen) Data;
typedef Bit#(5)  RegName;
typedef Bit#(WordLen) Instr;


Bit#(WordLen) handlerEntry = 'hbfc00380;
Bit#(5) execode_int  =  0  ;
Bit#(5) execode_adel =  4  ;
Bit#(5) execode_ades =  5  ;
Bit#(5) execode_sys  =  8  ;
Bit#(5) execode_bp   =  9  ;
Bit#(5) execode_ri   =  10 ;
Bit#(5) execode_ov   =  12 ;
Bit#(5) execode_tr   =  13 ;


//例外
typedef enum {
    None, 
    BadMAddr, 
    Sys, Brk, Overflow, Trap, DivByZero, 
    RsvInstr,
    BadFAddr,
    SoftInt, Interruption, Loop
} ExcSignal deriving(Bits, FShow, Eq);
//例外信息 分别代表无例外，中断，取值地址错，保留指令例外，
//加法溢出，访存地址错，除以零

// 例外拥有优先级，下面定义优先级。a > b 表示 a 的优先级高于 b
instance Ord#(ExcSignal);
    function Bool \>  (ExcSignal a, ExcSignal b) = pack(a) >  pack(b);
    function Bool \>= (ExcSignal a, ExcSignal b) = pack(a) >= pack(b);
    function Bool \<  (ExcSignal a, ExcSignal b) = pack(a) <  pack(b);
    function Bool \<= (ExcSignal a, ExcSignal b) = pack(a) <= pack(b);
endinstance


typedef struct {
    Bool exception;
    Bool pause;
    Bool bub;
} CtrlUnitInfo deriving(Bits, FShow); 
//控制单元向各级流水发送的控制信息，各域分别表示例外，暂停，气泡

typedef struct {
    Bool fail;
    Bool failB;
    Addr npc;
} Bcheck deriving(Bits, FShow);
//分支检测，fail表示不能顺序执行（这个奇怪的名字来源于“预测失败”）
//failB，由分支指令引起的控制转移
//npc，正确的下一取值地址

typedef struct {
    Bit#(3) arsize;
    Bool en;
    Bit#(4) be;
    Addr addr;
    Data data;
} MemReq deriving(Bits, FShow);
//访存请求（也用于访问指令存储器）

typedef struct {
    Bool wr;
    Bool valid;
    RegName num;
    Data data;
} WbInfo deriving(Bits, FShow);
//写回信息，valid表示所需值是否已经得到

typedef struct {
    Bool hiwr;
    Bool lowr;
    Data hid;
    Data lod;
} HiloWbInfo deriving(Bits, FShow);
//hi，lo的写回信息

typedef struct {
    Data badvaddr;
    Data status;
    Data cause;
    Data epc;
    Data count;
} CP0 deriving(Bits, FShow);
//CP0四个寄存器的值

typedef struct {
    Data badvaddrd;
    Data statusd;
    Data caused;
    Data epcd;
    Data countd;
    Bool badvaddrwr;
    Bool statuswr;
    Bool causewr;
    Bool epcwr;
    Bool countwr;
} CP0wr deriving(Bits, FShow);
//写CP0的信息

typedef struct {
    Bool nop;
    Addr pc;
    ExcSignal exc;
} Data_IF_ID deriving(Bits, FShow);


typedef struct {
    Bool nop;
    Addr pc;
    Instr instr;
    Data busa;
    Data busb;
    Data hid;
    Data lod;
    ALUctr aluctr;
    ExcSignal exc;
} Data_ID_EX deriving(Bits, FShow);

typedef struct {
    Bool nop;
    Addr pc;
    Instr instr;
    WbInfo wbinfo;
    HiloWbInfo hilowb;
    Data aluout;
    Data busa;
    Data busb;
    ExcSignal exc;
} Data_EX_MEM deriving(Bits, FShow);

typedef struct{
    Bool nop;
    Addr pc;
    Instr instr;
    WbInfo wbinfo;
    HiloWbInfo hilowb;
    Data aluout;
    Data busb;
    Bit#(6) ext_int;
    ExcSignal exc;
} Data_MEM_WB deriving(Bits, FShow);

typedef struct {
    Addr pc;
    Bool wen;
    RegName wnum;
    Data wdata;
} Debug_t deriving(Bits, FShow);
//debug信息


typedef struct{
    Bit#(3) arsize;
    Bool en;
    Bool cache_en;   
    Bit#(4) be;
    Addr addr;
    Bit#(32) data;
}MMU_Req deriving(Eq, Bits);



typedef struct {
    Data index;
    Data entrylo0;
    Data entrylo1;
    Data pagemask;
    Data entryhi;
} TLBentry deriving(Bits, FShow);

typedef struct {
    Bit#(5) index; 
    Bit#(1) write_en; 
    Bit#(12) mask; 
    Data entryhi; 
    Data entrylo0; 
    Data entrylo1; 
    Addr va_inst;
    Addr va_data;
} TLBReq deriving(Bits, FShow);


endpackage