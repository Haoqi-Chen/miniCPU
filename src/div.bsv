
// 除法器包含三个状态，空闲Idle，计算Calc，完成Finish

// 状态转化的条件为：
// start                 :: Idle   ->  Calc
// cnt == 15             :: Calc   ->  Finish
// !pause                :: Finish ->  Idle

// 计算原理：
// 首先将a转换成高32位为0，低32位为a的q。在每个周期开始前，先将q左移一位，
// 末尾补0，然后q的高32位与b相比较看是否大于等于b，若是，则 q = q - {b, 32’b0} + 1，
// 否则不进行操作。这样的的移位操作、比较和减法要执行32次，
// 执行完成后得到的q的高32位为两数a和b相除的余数，低32位表示商。
// 即：
// q' = let q_shifted = {q[62:0], 1'b0}
//      in  if q_shifted[63:32] >= b 
//              then {q_shifted[63:32] - b, q_shifted[31:1], 1'b1}
//              else q_shifted

// 这里提供两个版本
// 一是每周期计算一步，即每周期进行一次移位，比较和减法，这样需要32周期完成计算
// 二是每周期计算两步，这样需要16周期完成计算

`define two_steps_per_cycle 1

import def_types :: *;

typedef enum {
    Idle, DivCalc, MultCalc, DivFinish, MultFinish
} MCstate deriving(FShow, Eq, Bits);

interface MCALU_ifc;
    method Action step(Bool start, ALUctr aluctr, Data a, Data b, Bool pause);
    method Bit#(64) getResult();
    method Bool finish();
endinterface
(*synthesize*)
module mkMCALU(MCALU_ifc);

    Reg#(MCstate) state <- mkReg(Idle);

    Reg#(Bit#(5)) cnt <- mkReg(0);
    Reg#(Data) saved_a <- mkReg(0);
    Reg#(Data) saved_b <- mkReg(0);
    Reg#(Bit#(64)) saved_res <- mkReg(0);
    Reg#(Bool) neg_a <- mkReg(False);
    Reg#(Bool) neg_b <- mkReg(False);
    Reg#(ALUctr) reg_aluctr <- mkReg(ALUctr_addu);

    
    method Action step(Bool start, ALUctr aluctr, Data a, Data b, Bool pause);
        let staged_neg_a = (a[31] == 1) && (aluctr == ALUctr_div || aluctr == ALUctr_mult);
        let staged_neg_b = (b[31] == 1) && (aluctr == ALUctr_div || aluctr == ALUctr_mult);
        neg_a <= staged_neg_a;
        neg_b <= staged_neg_b;



        if(start && state == Idle) begin
            cnt <= 0;
            saved_a   <= staged_neg_a? -a: a; 
            saved_b   <= staged_neg_b? -b: b;
            reg_aluctr    <= aluctr;
            if(aluctr == ALUctr_div || aluctr == ALUctr_divu) begin
                // 除法初始化
                saved_res <= {32'b0, staged_neg_a? -a: a};
                state     <= DivCalc;
            end
            else begin
                // 乘法初始化
                saved_res <= 64'b0;
                state     <= MultCalc;
            end
        end
    // 除法计算
      `ifdef two_steps_per_cycle // 一周期计算两步
        else if(state == DivCalc) begin
            cnt <= cnt + 1;

            if(cnt == 15)
                state <= DivFinish;

            Bit#(64) q0_shift = {saved_res[62:0], 'b0};
            Bit#(64) q1 = 
                (q0_shift[63:32] >= saved_b)? {q0_shift[63:32] - saved_b, q0_shift[31:1], 1'b1}:
                q0_shift;
            Bit#(64) q1_shift = {q1[62:0], 'b0};
            Bit#(64) q2 = 
                (q1_shift[63:32] >= saved_b)? {q1_shift[63:32] - saved_b, q1_shift[31:1], 1'b1}:
                q1_shift;

            saved_res <= q2;
        end
      `else // 一周期计算一步
        else if(state == DivCalc) begin
            cnt <= cnt + 1;

            if(cnt == 31)
                state <= DivFinish;

            let q0_shift = {saved_res[62:0], 'b0};
            Bit#(64) q1 = 
                (q0_shift[63:32] > saved_b)? {q0_shift[63:32] - saved_b, q0_shift + 1}:
                q0_shift;

            saved_res <= q1;
        end
      `endif
        else if(state == DivFinish) begin
            if(!pause) state <= Idle;
        end

        // 乘法计算
      `ifdef two_steps_per_cycle
        else if(state == MultCalc) begin
            cnt <= cnt + 1;

            if(cnt == 15)
                state <= MultFinish;

            let p0_shifted = {1'b0, saved_res[63:1]};
            Bit#(64) p1 = 
                (saved_b[0] == 0)? p0_shifted:
                {p0_shifted[63:31] + {1'b0, saved_a}, p0_shifted[30:0]};

            let p1_shifted = {1'b0, p1[63:1]};
            Bit#(64) p2 = 
                (saved_b[1] == 0)? p1_shifted:
                {p1_shifted[63:31] + {1'b0, saved_a}, p1_shifted[30:0]};

            saved_res <= p2;
            saved_b <= {2'b0, saved_b[31:2]};
        end
      `else
        else if(state == MultCalc) begin
            cnt <= cnt + 1;
            
            if(cnt == 31)
                state <= MultFinish;

            let p0_shifted = {1'b0, saved_res[63:1]};
            Bit#(64) p1 = 
                (saved_b[0] == 0)? p0_shifted:
                {p0_shifted[63:31] + {1'b0, saved_a}, p0_shifted[30:0]};

            saved_res <= p1;
            saved_b <= {1'b0, saved_b[31:1]};
        end
      `endif
        else begin // state == MultFinish
            if(!pause) state <= Idle;
        end

    endmethod

    method Bit#(64) getResult;
        let hi = saved_res[63:32];
        let lo = saved_res[31:0];
        hi = neg_a? (-hi): hi;
        lo = (neg_a != neg_b)? (-lo): lo;
        return (reg_aluctr == ALUctr_div || reg_aluctr == ALUctr_divu)? {hi, lo}:
            (neg_a != neg_b)? (-saved_res): saved_res;
    endmethod
    method Bool finish = (state == DivFinish || state == MultFinish);


endmodule