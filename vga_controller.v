module vga_controller (
    input wire clk,
    input wire rst,
    output wire hsync,
    output wire vsync,
    output wire valid,
    output wire [10:0] x,  // 0 to 1279
    output wire [10:0] y   // 0 to 1023
);

    // === VGA Timing Constants: 1280x1024 @ 60Hz ===
    localparam FRAME_WIDTH  = 1280;
    localparam FRAME_HEIGHT = 1024;

    localparam H_FP   = 48;
    localparam H_PW   = 112;
    localparam H_MAX  = 1688;

    localparam V_FP   = 1;
    localparam V_PW   = 3;
    localparam V_MAX  = 1066;

    localparam H_POL = 1'b1;
    localparam V_POL = 1'b1;

    reg [10:0] h_cnt = 0;
    reg [10:0] v_cnt = 0;

    // === Horizontal Counter ===
    always @(posedge clk) begin
        if (rst)
            h_cnt <= 0;
        else if (h_cnt == H_MAX - 1)
            h_cnt <= 0;
        else
            h_cnt <= h_cnt + 1;
    end

    // === Vertical Counter ===
    always @(posedge clk) begin
        if (rst)
            v_cnt <= 0;
        else if (h_cnt == H_MAX - 1) begin
            if (v_cnt == V_MAX - 1)
                v_cnt <= 0;
            else
                v_cnt <= v_cnt + 1;
        end
    end

    // === Sync Pulses ===
    assign hsync = (H_POL == 1'b1) ?
                   (h_cnt >= (FRAME_WIDTH + H_FP) && h_cnt < (FRAME_WIDTH + H_FP + H_PW)) :
                   ~(h_cnt >= (FRAME_WIDTH + H_FP) && h_cnt < (FRAME_WIDTH + H_FP + H_PW));

    assign vsync = (V_POL == 1'b1) ?
                   (v_cnt >= (FRAME_HEIGHT + V_FP) && v_cnt < (FRAME_HEIGHT + V_FP + V_PW)) :
                   ~(v_cnt >= (FRAME_HEIGHT + V_FP) && v_cnt < (FRAME_HEIGHT + V_FP + V_PW));

    // === Visible Area and Coordinates ===
    assign valid = (h_cnt < FRAME_WIDTH) && (v_cnt < FRAME_HEIGHT);
    assign x = valid ? h_cnt : 0;
    assign y = valid ? v_cnt : 0;

endmodule
