module FSM_tb();
reg SS_n,MOSI,rst_n,clk;
wire MISO;

FSM test(SS_n,MOSI,rst_n,clk,MISO);

//Clock Generation
initial 
begin
    clk = 0;
    forever
        #10 clk = ~clk;    
end

integer i;
//Test Writing in address 8'b0 ==> 00000000
initial
begin
    rst_n = 0;
    SS_n  = 0;
    MOSI  = 0;
    #20
    rst_n = 1;
    #240  //Write Address 0000000 as MOSI = 0
    SS_n = 1;
    #20 
    SS_n = 0;
    #40
    MOSI = 1;
    SS_n = 0;
    #20
    MOSI = 0;
    #20
    MOSI = 1;
    for(i  = 0;i<8; i= i+1)
    begin
        #20 MOSI = ~MOSI;
    end
    SS_n = 1;
    i = 0;
    #20
    MOSI = 1;
    SS_n = 0;
    #40
    MOSI = 0;
    #20
    MOSI = 1;
    
    for(i  = 0;i<9; i= i+1)
    begin
        #20 MOSI = 0;
    end
    SS_n = 1;
    i = 0;
    #20
    MOSI = 1;
    SS_n = 0;
    #240
    SS_n = 1;
    #180;
     
    $stop;

end

endmodule