module Single_Port_Asynch_Ram(din,rx_valid,clk,rst_n,dout,tx_valid);


input [9:0]din;
input rx_valid;
input clk,rst_n;
output reg [7:0]dout;
output reg tx_valid;

reg [7:0] mem [255:0];
reg [7:0]address_val;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
    begin
        address_val <= 'b0;
        tx_valid <= 1'b0;
        dout<='b0;
    end
    else
        begin
            if(rx_valid == 1'b1)
            begin
                if(din[9:8] == 2'b00 || din[9:8] == 2'b10)
                begin
                    address_val <= din[7:0];
                    tx_valid <= 1'b0;
                    dout<= mem[address_val];
                end
                else if(din[9:8] == 2'b01)
                begin
                    mem[address_val] <= din[7:0];
                    tx_valid <= 1'b0;
                    dout<= mem[address_val];
                end
                else if (din[9:8] == 2'b11) 
                begin
                    dout<= mem[address_val];
                    tx_valid <= 1'b1;
                end
                else 
                begin
                   
                end
            end
        end
end
endmodule
