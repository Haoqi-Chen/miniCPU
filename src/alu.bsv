package alu;

import def_types :: *;


interface ALU_ifc;
    method ALUout_t calc(ALUctr aluctr, Bit#(32) a, Bit#(32) b);
endinterface

module mkALU(ALU_ifc);
    method ALUout_t calc(ALUctr aluctr, Bit#(32) a, Bit#(32) b);
        let bb = (aluctr == ALUctr_sub || aluctr == ALUctr_subu)?(1+~b):b;
        let sum = {a[31],a} + {bb[31],bb};
        let s = a - b;
        case(aluctr)
            ALUctr_add, ALUctr_sub: return 
                ALUout_t{
                    result: sum[31:0], 
                    overflow: (sum[32] == sum[31])? False: True
                };
            ALUctr_addu:return 
                ALUout_t{
                    result:sum[31:0], 
                    overflow: False
                };
            ALUctr_subu:return 
                ALUout_t{
                    result: sum[31:0], 
                    overflow: False
                };
            ALUctr_and:return 
                ALUout_t{
                    result: a & b, 
                    overflow: False
                };
            ALUctr_or:return 
                ALUout_t{
                    result: a | b, 
                    overflow: False
                };
            ALUctr_nor:return 
                ALUout_t{
                    result: ~(a | b), 
                    overflow: False
                }; 
            ALUctr_xor:return 
                ALUout_t{
                    result: a ^ b, 
                    overflow: False
                };
            ALUctr_slt:return 
                ALUout_t{
                    result: (a[31]==b[31] && a < b) || (a[31]==1 && b[31]==0)?1:0, 
                    overflow: False
                }; 
            ALUctr_sltu:return 
                ALUout_t{
                    result: (a < b)?1:0, 
                    overflow: False
                };
            ALUctr_eq:return 
                ALUout_t{
                    result: (a == b)?1:0, 
                    overflow: False
                };
            ALUctr_neq:return 
                ALUout_t{
                    result: (a != b)?1:0, 
                    overflow: False
                };
            ALUctr_gtz:return 
                ALUout_t{  
                    result: (a[31] == 0 && a != 0)?1:0, 
                    overflow: False
                };
            ALUctr_gez:return 
                ALUout_t{
                    result: (a[31] == 0)?1:0, 
                    overflow: False
                };
            ALUctr_ltz:return 
                ALUout_t{
                    result: (a[31] == 1)?1:0, 
                    overflow: False
                };
            ALUctr_lez:return 
                ALUout_t{
                    result: (a == 0 || a[31] == 1)?1:0, 
                    overflow: False
                };
            ALUctr_sll:return 
                ALUout_t{
                    result: b << a[4:0], 
                    overflow: False
                };
            ALUctr_srl:return 
                ALUout_t{
                    result: b >> a[4:0], 
                    overflow: False
                };
            ALUctr_sra:return 
                ALUout_t{
                    result: ({(b[31]==1?32'hffffffff:32'b0), b} >> a[4:0])[31:0], 
                    overflow: False
                };
            ALUctr_clo: return
                ALUout_t{
                    result: {26'b0, pack(countZerosMSB(~a))},
                    overflow: False
                };
            ALUctr_clz:return 
                ALUout_t{
                    result: {26'b0, pack(countZerosMSB(a))}, 
                    overflow: False
                };
            ALUctr_ge  : return
                ALUout_t{
                    result: (s[31] == 0)?1:0,
                    overflow: False
                };
            ALUctr_geu : return
                ALUout_t{
                    result: (a >= b)? 1: 0,
                    overflow: False
                };
            ALUctr_lt  : return
                ALUout_t{
                    result: (s[31] == 1)?1:0,
                    overflow: False
                };
            ALUctr_ltu : return
                ALUout_t{
                    result: (a >= b)? 0: 1,
                    overflow: False
                };
            ALUctr_eq  : return
                ALUout_t{
                    result: (a == b)? 1: 0,
                    overflow: False
                };
            ALUctr_neq : return
                ALUout_t{
                    result: (a == b)? 0: 1,
                    overflow: False
                };
            default:return 
                ALUout_t{
                    result: a + b, 
                    overflow: False
                };
        endcase
    endmethod
endmodule

// module mkTb(Empty);
//     ALU_ifc alu <- mkALU;

//     Reg#(ALUctr) ctr <- mkReg(ALUctr_addu);

//     Reg#(Bit#(32)) cnt <- mkReg(0);


//     rule r(cnt < 20);
//         cnt <= cnt + 1;
//         let y = alu.calc(ctr, 5, 2);
//         $display(fshow(ctr), fshow(y));
//         ctr <= unpack(pack(ctr) + 1);
//     endrule

// endmodule


endpackage