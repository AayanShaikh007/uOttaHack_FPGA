// Display numbers as large digits on HDMI screen
module number_display (
    input  wire         clk_i,
    input  wire         rst_i,
    input  wire [7:0]   number_i,     // Number to display (0-255)
    input  wire [11:0]  x_pos_i,      // Current pixel X position
    input  wire [11:0]  y_pos_i,      // Current pixel Y position
    input  wire         de_i,         // Data enable
    output wire [23:0]  rgb_o         // RGB output
);

    // Display area settings
    localparam DIGIT_WIDTH = 80;
    localparam DIGIT_HEIGHT = 120;
    localparam DIGIT_SPACING = 20;
    localparam START_X = 800;  // Center on 1920x1080 screen
    localparam START_Y = 480;

    // Colors
    localparam [23:0] TEXT_COLOR = 24'hFF_FF_00; // Yellow
    localparam [23:0] BG_COLOR   = 24'h00_00_00; // Black

    // Convert number to 3 decimal digits
    wire [3:0] digit_hundreds = number_i / 100;
    wire [3:0] digit_tens = (number_i / 10) % 10;
    wire [3:0] digit_ones = number_i % 10;

    // Calculate which digit we're in
    wire [11:0] rel_x = x_pos_i - START_X;
    wire [11:0] rel_y = y_pos_i - START_Y;
    
    wire in_display_area = (x_pos_i >= START_X) && 
                          (x_pos_i < START_X + 3*DIGIT_WIDTH + 2*DIGIT_SPACING) &&
                          (y_pos_i >= START_Y) && 
                          (y_pos_i < START_Y + DIGIT_HEIGHT);

    wire [1:0] digit_index = (rel_x < DIGIT_WIDTH) ? 0 :
                            (rel_x < DIGIT_WIDTH + DIGIT_SPACING) ? 3 :
                            (rel_x < 2*DIGIT_WIDTH + DIGIT_SPACING) ? 1 :
                            (rel_x < 2*DIGIT_WIDTH + 2*DIGIT_SPACING) ? 3 :
                            (rel_x < 3*DIGIT_WIDTH + 2*DIGIT_SPACING) ? 2 : 3;

    wire [11:0] digit_x = (digit_index == 0) ? rel_x :
                         (digit_index == 1) ? rel_x - DIGIT_WIDTH - DIGIT_SPACING :
                         (digit_index == 2) ? rel_x - 2*DIGIT_WIDTH - 2*DIGIT_SPACING : 0;

    wire [3:0] current_digit = (digit_index == 0) ? digit_hundreds :
                              (digit_index == 1) ? digit_tens :
                              (digit_index == 2) ? digit_ones : 0;

    // Simple 7-segment style digit ROM
    wire [6:0] segments = get_segments(current_digit);
    wire pixel_on = render_digit(segments, digit_x, rel_y);

    assign rgb_o = (de_i && in_display_area && (digit_index != 3) && pixel_on) ? TEXT_COLOR : BG_COLOR;

    // 7-segment encoding: {A, B, C, D, E, F, G}
    function [6:0] get_segments(input [3:0] digit);
        case (digit)
            4'd0: get_segments = 7'b1111110; // 0
            4'd1: get_segments = 7'b0110000; // 1
            4'd2: get_segments = 7'b1101101; // 2
            4'd3: get_segments = 7'b1111001; // 3
            4'd4: get_segments = 7'b0110011; // 4
            4'd5: get_segments = 7'b1011011; // 5
            4'd6: get_segments = 7'b1011111; // 6
            4'd7: get_segments = 7'b1110000; // 7
            4'd8: get_segments = 7'b1111111; // 8
            4'd9: get_segments = 7'b1111011; // 9
            default: get_segments = 7'b0000000;
        endcase
    endfunction

    // Render segments as thick lines
    function render_digit(input [6:0] segs, input [11:0] x, input [11:0] y);
        localparam SEG_LEN = 60;
        localparam SEG_THICK = 10;
        localparam SEG_GAP = 5;
        
        reg in_seg;
        in_seg = 0;
        
        // Segment A (top)
        if (segs[6] && y < SEG_THICK && x > SEG_GAP && x < SEG_LEN + SEG_GAP)
            in_seg = 1;
        // Segment B (top right)
        if (segs[5] && x > SEG_LEN + SEG_GAP && x < SEG_LEN + SEG_GAP + SEG_THICK && 
            y > SEG_GAP && y < DIGIT_HEIGHT/2 - SEG_GAP)
            in_seg = 1;
        // Segment C (bottom right)
        if (segs[4] && x > SEG_LEN + SEG_GAP && x < SEG_LEN + SEG_GAP + SEG_THICK && 
            y > DIGIT_HEIGHT/2 + SEG_GAP && y < DIGIT_HEIGHT - SEG_GAP)
            in_seg = 1;
        // Segment D (bottom)
        if (segs[3] && y > DIGIT_HEIGHT - SEG_THICK && y < DIGIT_HEIGHT && 
            x > SEG_GAP && x < SEG_LEN + SEG_GAP)
            in_seg = 1;
        // Segment E (bottom left)
        if (segs[2] && x < SEG_THICK && y > DIGIT_HEIGHT/2 + SEG_GAP && y < DIGIT_HEIGHT - SEG_GAP)
            in_seg = 1;
        // Segment F (top left)
        if (segs[1] && x < SEG_THICK && y > SEG_GAP && y < DIGIT_HEIGHT/2 - SEG_GAP)
            in_seg = 1;
        // Segment G (middle)
        if (segs[0] && y > DIGIT_HEIGHT/2 - SEG_THICK/2 && y < DIGIT_HEIGHT/2 + SEG_THICK/2 && 
            x > SEG_GAP && x < SEG_LEN + SEG_GAP)
            in_seg = 1;
            
        render_digit = in_seg;
    endfunction

endmodule
