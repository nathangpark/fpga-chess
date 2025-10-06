module chessBoard_vga ( 
    input wire clk,
    input wire [10:0] x,
    input wire [10:0] y,
    input wire valid,
    output reg [2:0] red,
    output reg [2:0] green,
    output reg [2:0] blue
);

    // Parameters for tile size
    localparam TILE_WIDTH = 160;   
    localparam TILE_HEIGHT = 128;

    wire [3:0] row = y / TILE_HEIGHT;
    wire [3:0] col = x / TILE_WIDTH;
    
    wire is_dark_square = row[0] ^ col[0];  // Checkerboard pattern

    // Define RGB values for light and dark squares
    localparam [2:0] LIGHT_RED   = 3'b010;
    localparam [2:0] LIGHT_GREEN = 3'b010;
    localparam [2:0] LIGHT_BLUE  = 3'b111;

    localparam [2:0] DARK_RED   = 3'b000;
    localparam [2:0] DARK_GREEN = 3'b000;
    localparam [2:0] DARK_BLUE  = 3'b010;

    reg [2:0] red_r, green_r, blue_r;
    
    always @(posedge clk) begin
        red   <= red_r;
        green <= green_r;
        blue  <= blue_r;
    end
    
    always @(*) begin
        if (valid) begin
            if (is_dark_square) begin
                red_r   = DARK_RED;
                green_r = DARK_GREEN;
                blue_r  = DARK_BLUE;
            end else begin
                red_r   = LIGHT_RED;
                green_r = LIGHT_GREEN;
                blue_r  = LIGHT_BLUE;
            end
        end else begin
            red_r   = 3'b000;
            green_r = 3'b000;
            blue_r  = 3'b000;
        end
    end

endmodule