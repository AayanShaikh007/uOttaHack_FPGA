// Simple UART RX module for receiving data from PC
module uart_rx #(
    parameter CLK_FREQ = 125_000_000,  // 125MHz clock
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid
);

localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

reg [15:0] clk_count = 0;
reg [2:0]  bit_index = 0;
reg [1:0]  state = 0;
reg [7:0]  rx_byte = 0;
reg        rx_d1, rx_d2;  // Double-flop synchronizer

// Synchronize RX input
always @(posedge clk) begin
    rx_d1 <= rx;
    rx_d2 <= rx_d1;
end

always @(posedge clk) begin
    if (rst) begin
        state <= 0;
        valid <= 0;
        clk_count <= 0;
        bit_index <= 0;
    end else begin
        valid <= 0;
        
        case (state)
            0: begin  // Idle - wait for start bit
                clk_count <= 0;
                bit_index <= 0;
                if (rx_d2 == 0) state <= 1;  // Start bit detected
            end
            
            1: begin  // Start bit - wait to middle
                if (clk_count < CLKS_PER_BIT/2) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    state <= 2;
                end
            end
            
            2: begin  // Data bits
                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    rx_byte[bit_index] <= rx_d2;
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        state <= 3;
                    end
                end
            end
            
            3: begin  // Stop bit
                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    data <= rx_byte;
                    valid <= 1;
                    state <= 0;
                end
            end
        endcase
    end
end

endmodule
