import BRAMCore :: *;
typedef Bit#(32) Data;
module mkBram_test();
    BRAM_PORT#(Bit#(6),Data) bram <- mkBRAMCore1(32,False);

    Reg#(Data) cnt <- mkReg(0);


    rule rl (cnt < 10);

        cnt <= cnt + 1;

        if     (cnt == 0)     $display("%8h",bram.read);
        else if(cnt == 1)     bram.put(True, 0, 'h01234567);
        else if(cnt == 2)     $display("%8h",bram.read);
        else if(cnt == 3)     $display("%8h",bram.read);
        else if(cnt == 4)     bram.put(False, 0, 'h01234567);
        else if(cnt == 5)     $display("%8h",bram.read);
        else if(cnt == 6)     $display("%8h",bram.read);
        else                  $finish;

    endrule
endmodule