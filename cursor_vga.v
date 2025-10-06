module cursor_vga (
    input wire clk,
    input wire [10:0] x,         // current VGA pixel X
    input wire [10:0] y,         // current VGA pixel Y
    input wire [10:0] cursor_x,  // mouse-controlled X position
    input wire [10:0] cursor_y,  // mouse-controlled Y position
    input wire valid,           // VGA active video region
    output reg [2:0] red,
    output reg [2:0] green,
    output reg [1:0] blue,
    output wire active
);

    localparam CURSOR_SIZE = 6;      // square cursor (5x5 pixels)
    localparam HALF_SIZE = CURSOR_SIZE / 2;

    wire [10:0] cursor_left   = cursor_x - HALF_SIZE;
    wire [10:0] cursor_right  = cursor_x + HALF_SIZE;
    wire [10:0] cursor_top    = cursor_y - HALF_SIZE;
    wire [10:0] cursor_bottom = cursor_y + HALF_SIZE;

    wire is_cursor_pixel = (x >= cursor_left) && (x <= cursor_right) &&
                           (y >= cursor_top)  && (y <= cursor_bottom);

    assign active = valid && is_cursor_pixel;
    
    
    reg [2:0] red_r, green_r, blue_r;
    
    always @(posedge clk) begin
        red   <= red_r;
        green <= green_r;
        blue  <= blue_r;
    end

    always @(*) begin
        if (active) begin
            red_r   = 3'b111;  // white cursor (full RGB)
            green_r = 3'b111;
            blue_r  = 3'b111;
        end else begin
            red_r   = 3'b000;
            green_r = 3'b000;
            blue_r  = 3'b000;
        end
    end

endmodule
