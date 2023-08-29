//`timescale 1ps / 1ps
module FSM(SS_n,MOSI,rst_n,clk,MISO);

input SS_n,MOSI,rst_n,clk;
wire tx_valid;
wire [7:0]tx_data;
reg[2:0] out_State;
reg [9:0]rx_data;
reg rx_valid;
output reg MISO;

reg[2:0] cs,ns;
parameter IDLE      = 3'b000;
parameter Write     = 3'b001;
parameter Read_Data = 3'b010;
parameter Read_Add  = 3'b100;
parameter CHK       = 3'b111;



integer i =0;
integer s =0;
reg[10:0]Parallel;
reg[7:0]WR_Adress,Read_Address;
reg Read_Mem = 1'b0,P2S = 1'b0;

//State_Memory
always @(posedge clk or negedge rst_n) 
begin
    if(~rst_n)
        cs <= IDLE;
    else
        cs <= ns;    
end

//Output Logic
always @(cs) 
begin
    case (cs)
        IDLE        :out_State = 3'b000;
        Write       :out_State = 3'b001;
        Read_Data   :out_State = 3'b010;
        Read_Add    :out_State = 3'b100;
        CHK         :out_State = 3'b111;
        default     :out_State = 3'b000;
    endcase
end

//Next State Logic Parallel i
always @(cs,SS_n,clk,tx_valid,MOSI,tx_data) 
begin
    case (cs)
        IDLE:
            if(SS_n)
                begin
                    ns = IDLE;
                    s=0;
                    
                    if(cs != Read_Data)
                    begin
                        Parallel  = 11'b0;
                        i=0;
                    end
                    else
                    begin
                        i=i;
                        //Parallel = Parallel;
                    end
                end
            else
            begin
                s = s;
                ns = CHK; 
                //Parallel = Parallel;
            end
                
        Write:
            if(SS_n == 1'b1)
                begin
                    ns = IDLE;
                    if(Parallel[0]==0 && Parallel[2:1] == 2'b00 && i >= 9)
                    begin
                        rx_valid = 1'b1;
                        rx_data = {Parallel[2:1],Parallel[10:3]};
                        WR_Adress = Parallel[10:3];
                        //Parallel = Parallel;
                    end
                    else if(Parallel[0]==0 && Parallel[2:1] == 2'b00 && i < 9)
                    begin
                        rx_valid = 1'b0;
                        rx_data = {Parallel[2:1],Parallel[10:3]};
                        //Parallel = Parallel;
                    end
                    else if(Parallel[0]==0 && Parallel[2:1] == 2'b01)
                    begin
                        if(i >= 9)
                        begin
                            rx_valid = 1'b1;
                            rx_data = {Parallel[2:1],Parallel[10:3]};
                            //Parallel = Parallel;
                        end
                        else
                        begin
                            rx_valid = 1'b0;
                            rx_data = {Parallel[2:1],Parallel[10:3]};
                            //Parallel = Parallel;
                        end
                    end
                    else
                    begin
                        rx_valid = 1'b0;
                        rx_data = {Parallel[2:1],Parallel[10:3]};
                        //Parallel = Parallel;
                    end
                end
            else if(SS_n == 1'b0 && i < 11)
            begin
                  ns =  Write;
                if(clk)
                begin
                    Parallel[i] <= MOSI;  
                    i<=i+1;  
                    rx_valid = 1'b0;  
                end
                else
                begin
                    Parallel[i]<=Parallel[i];
                    i<=i;
                    rx_valid = 1'b0;
                end 
            end
            else
            begin
                rx_valid = 1'b0;
                rx_data = {Parallel[2:1],Parallel[10:3]};
                //Parallel = Parallel;
            end
        CHK:
            begin
                i = 0;
                if(cs == ns)
                begin
                    if(clk)
                    begin
                        if(SS_n == 0 && MOSI == 0)
                            begin
                                ns = Write;
                                rx_valid = 0;
                               // Parallel = Parallel;
                            end
                        else if(SS_n == 0 && MOSI == 1 && Read_Mem == 1'b0)
                            begin
                                ns = Read_Add;
                                rx_valid = 0;
                               // Parallel = Parallel;
                            end
                        else if(SS_n == 0 && MOSI == 1 && Read_Mem == 1'b1)
                            begin
                                ns = Read_Data;
                                rx_valid = 0;
                               // Parallel = Parallel;
                            end                       
                        else if(SS_n == 1)
                            begin
                                ns = IDLE;
                                rx_valid = 0;
                               // Parallel = Parallel;
                            end 
                        else
                        begin
                            ns = cs;
                           // Parallel = Parallel;
                        end
                    end
                 end
                 else
                 begin
                    ns = ns;
                    rx_valid = rx_valid;
                    //Parallel = Parallel;
                 end
            end
        Read_Add:
            if(SS_n == 0)
            begin
                ns = Read_Add;
                if(clk)
                begin
                        Parallel[i] <= MOSI;  
                        i<=i+1;    
                end
                else
                begin
                    Parallel[i]<=Parallel[i];
                end
            end
            else if (SS_n == 1'b1)
            begin
                    ns = IDLE;
                    if(Parallel[0]==1 && Parallel[2:1] == 2'b10 && i >= 9)
                    begin
                        rx_valid = 1'b1;
                        rx_data = {Parallel[2:1],Parallel[10:3]};
                        Read_Address = Parallel[10:3];
                        Read_Mem <= 1'b1;
                       // Parallel = Parallel;
                    end
                    else if(Parallel[0]==1 && Parallel[2:1] == 2'b10 && i < 9)
                    begin
                        rx_valid = 1'b0;
                        rx_data = {Parallel[2:1],Parallel[10:3]};
                        Read_Address = Parallel[10:3];
                        //Parallel = Parallel;
                    end
                    else
                    begin
                        rx_valid = 1'b0;
                        rx_data = {Parallel[2:1],Parallel[10:3]};
                        //Parallel = Parallel;
                    end
            end
            else
            begin
                rx_valid = 1'b0;
                rx_data = {Parallel[2:1],Parallel[10:3]};
                //Parallel = Parallel;
            end
        Read_Data:
            if(SS_n == 1'b0)
            begin
                  ns =  Read_Data;
                  if(clk)
                    begin
                        Parallel[i] <= MOSI;  
                        i<=i+1;    
                    end
                   else
                   begin
                        Parallel[i] <= Parallel[i];
                   end
            end
            else if(SS_n == 1)
            begin
                //ns = Read_Data; 
                Read_Mem = 1'b0;
                if(Parallel[0]==1 && Parallel[2:1] == 2'b11 && i < 9 && clk)
                begin
                    rx_valid = 1'b0;
                    rx_data = {Parallel[2:1],Parallel[10:3]};
                    ns = IDLE;
                    //Parallel = Parallel;
                    
                end
                else if(Parallel[0]==1 && Parallel[2:1] == 2'b11 && i >= 9)
                begin
                    rx_valid = 1'b1;
                    rx_data = {Parallel[2:1],Parallel[10:3]};
                    P2S = 1'b1;
                    
                    if(clk)
                    begin
                        if(tx_valid == 1'b1 && s<9)
                        begin
                            MISO <= tx_data[s];
                            s <= s+1;
                            //Parallel = Parallel;
                        end
                        else
                        begin
                            MISO = 0;
                            if(s>=9)
                            begin
                                ns <= IDLE;
                                //cs <= IDLE;
                                s<= 20;
                                //Parallel = Parallel;
                            end
                            else
                            begin
                                ns <= Read_Data;
                                //Parallel = Parallel;
                            end
                        end
                    end
                end
                else
                begin
                    rx_valid = 1'b0;
                    rx_data = {Parallel[2:1],Parallel[10:3]};
                    ns = IDLE;
                    //Parallel = Parallel;
                end
            end
            else
            begin
                rx_valid = 1'b0;
                rx_data = {Parallel[2:1],Parallel[10:3]};
                ns = IDLE;
                //Parallel = Parallel;
            end
        default: ns = IDLE;
    endcase
    
end
Single_Port_Asynch_Ram finst(rx_data,rx_valid,clk,rst_n,tx_data,tx_valid);
endmodule