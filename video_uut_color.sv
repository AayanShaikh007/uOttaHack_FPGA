// video_uut_color.sv
// Modified to use VIO probe for dynamic color control

module video_uut_color (
    input  wire         clk_i,
    input  wire         cen_i,
    input  wire         rst_i,
    input  wire         vid_sel_i,
    input  wire [23:0]  vid_rgb_i,
    input  wire [1:0]   vh_blank_i,
    input  wire [2:0]   dvh_sync_i,
    input  wire [7:0]   vio_color_i,  // From VIO probe: 0=blue, 1=green, 2=red
    output wire [2:0]   dvh_sync_o,
    output wire [23:0]  vid_rgb_o
);

    // Video parameters
    localparam H_RES = 1920;
    localparam V_RES = 1080;
    localparam V_MID = V_RES / 2;
    localparam BG_COLOR   = 24'h00_00_00;
    localparam LINE_THICKNESS = 6;
    localparam ANIM_SPEED     = 1;

    typedef enum logic [1:0] {
        S_IDLE   = 2'd0,
        S_ATTACK = 2'd1,
        S_HOLD   = 2'd2,
        S_DECAY  = 2'd3
    } state_t;

    reg [23:0]  vid_rgb_d1;
    reg [2:0]   dvh_sync_d1;
    reg [11:0]  x_cnt;
    reg [11:0]  y_cnt;
    reg         prev_de, prev_vs;

    state_t     current_state = S_IDLE;
    reg [7:0]   state_timer   = 0;
    reg [3:0]   global_amp    = 0;
    reg [3:0]   target_amp    = 0;
    reg [5:0]   speed_cnt     = 0;
    reg [15:0]  lfsr          = 16'hACE1;
    reg [15:0]  phase_ofs     = 0;
    reg [4:0]   freq_1        = 12;
    reg [4:0]   freq_2        = 18;

    logic [15:0] idx_1, idx_2;
    logic [7:0]  saw_1, saw_2;

    // ===== DYNAMIC COLOR BASED ON VIO PROBE =====
    wire [23:0] line_color = get_color_from_probe(vio_color_i);

    function [23:0] get_color_from_probe(input [7:0] color_val);
        case (color_val[1:0])
            2'b00: get_color_from_probe = 24'h00_00_FF;  // BLUE
            2'b01: get_color_from_probe = 24'h00_FF_00;  // GREEN
            2'b10: get_color_from_probe = 24'hFF_00_00;  // RED
            default: get_color_from_probe = 24'h00_FF_00; // Default GREEN
        endcase
    endfunction

    wire data_en = dvh_sync_i[2];
    wire hsync   = dvh_sync_i[0];
    wire vsync   = dvh_sync_i[1];

    always @(posedge clk_i) begin
        if (rst_i) begin
            x_cnt <= 0;
            y_cnt <= 0;
            prev_de <= 0;
            prev_vs <= 0;
        end else if (cen_i) begin
            prev_de <= data_en;
            prev_vs <= vsync;

            if (!prev_de && data_en) begin
                x_cnt <= 0;
            end else if (data_en) begin
                x_cnt <= x_cnt + 1;
            end

            if (!prev_vs && vsync) begin
                y_cnt <= 0;
            end else if (prev_de && !data_en) begin
                y_cnt <= y_cnt + 1;
            end
        end
    end

    // Animation state machine
    always @(posedge clk_i) begin
        if (rst_i) begin
            current_state <= S_IDLE;
            state_timer   <= 0;
            global_amp    <= 0;
            target_amp    <= 0;
            speed_cnt     <= 0;
            lfsr          <= 16'hACE1;
        end else if (cen_i) begin
            if (speed_cnt < ANIM_SPEED) begin
                speed_cnt <= speed_cnt + 1;
            end else begin
                speed_cnt <= 0;
                lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

                case (current_state)
                    S_IDLE: begin
                        if (state_timer == 0) begin
                            target_amp    <= lfsr[3:0];
                            state_timer   <= lfsr[7:4] + 8'd10;
                            current_state <= S_ATTACK;
                        end else begin
                            state_timer <= state_timer - 1;
                        end
                    end

                    S_ATTACK: begin
                        if (global_amp < target_amp) begin
                            global_amp <= global_amp + 1;
                        end else begin
                            state_timer   <= lfsr[6:3] + 8'd15;
                            current_state <= S_HOLD;
                        end
                    end

                    S_HOLD: begin
                        if (state_timer == 0) begin
                            current_state <= S_DECAY;
                        end else begin
                            state_timer <= state_timer - 1;
                        end
                    end

                    S_DECAY: begin
                        if (global_amp > 0) begin
                            global_amp <= global_amp - 1;
                        end else begin
                            state_timer   <= lfsr[7:2] + 8'd20;
                            current_state <= S_IDLE;
                        end
                    end
                endcase
            end
        end
    end

    // Wave generation
    assign idx_1 = (x_cnt * freq_1) + phase_ofs;
    assign idx_2 = (x_cnt * freq_2) + (phase_ofs >> 1);

    assign saw_1 = idx_1[15:8];
    assign saw_2 = idx_2[15:8];

    wire [8:0] wave_sum = saw_1 + saw_2;
    wire [7:0] wave_out = wave_sum[8:1];

    wire [11:0] scaled_wave = (wave_out * global_amp) >> 4;
    wire [11:0] wave_y = V_MID + scaled_wave - (wave_out >> 1);

    wire [11:0] y_diff = (y_cnt > wave_y) ? (y_cnt - wave_y) : (wave_y - y_cnt);
    wire        in_beam = (y_diff < LINE_THICKNESS);

    // Use dynamic color from VIO instead of fixed WAVE_COLOR
    wire [23:0] waveform_rgb = (data_en && in_beam && !vid_sel_i) ? line_color : BG_COLOR;

    always @(posedge clk_i) begin
        if (cen_i) begin
            dvh_sync_d1 <= dvh_sync_i;
            vid_rgb_d1  <= vid_sel_i ? vid_rgb_i : waveform_rgb;
        end
    end

    assign dvh_sync_o = dvh_sync_d1;
    assign vid_rgb_o  = vid_rgb_d1;

endmodule
