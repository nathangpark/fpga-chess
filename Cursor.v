module MoveOptions(
    input wire clk,
    input wire [10:0] x,
    input wire [10:0] y,
    input wire [63:0] moveOptions,
    input wire valid,
    input wire turn,
    output reg [2:0] red,
    output reg [2:0] green,
    output reg [1:0] blue,
    output wire active
    );
    
    localparam TILE_WIDTH = 160;   // 640 / 8
    localparam TILE_HEIGHT = 128;  // 480 / 8
    
    localparam SCALE         = 6;  // Change this to scale the pawn size
    localparam BMP_SIZE      = 8;  // 8x8 bitmap

    localparam SCALED_WIDTH  = BMP_SIZE * SCALE;
    localparam SCALED_HEIGHT = BMP_SIZE * SCALE;

    // === Tile Location ===
    wire [3:0] col = x / TILE_WIDTH;
    wire [3:0] row = y / TILE_HEIGHT;

    wire [6:0] x_tile = x % TILE_WIDTH;
    wire [6:0] y_tile = y % TILE_HEIGHT;

    localparam X_OFFSET = (TILE_WIDTH - SCALED_WIDTH) / 2;
    localparam Y_OFFSET = (TILE_HEIGHT - SCALED_HEIGHT) / 2;

    wire [6:0] x_local = x_tile - X_OFFSET;
    wire [6:0] y_local = y_tile - Y_OFFSET;

    wire [3:0] x_bitmap = x_local / SCALE;
    wire [3:0] y_bitmap = y_local / SCALE;

    wire inside_bitmap = (x_local < SCALED_WIDTH) && (y_local < SCALED_HEIGHT);
    
    wire [5:0] pos = turn ? row * 8 + (7 - col) : (7 - row) * 8 + col;
    wire is_highlighted = moveOptions[pos];
    
    reg [7:0] move_options [0:7];
    initial begin
        move_options[0] = 8'b00000000;
        move_options[1] = 8'b00000000;
        move_options[2] = 8'b00011000;
        move_options[3] = 8'b00100100;
        move_options[4] = 8'b00100100;
        move_options[5] = 8'b00011000;
        move_options[6] = 8'b00000000;
        move_options[7] = 8'b00000000;
    end 
    wire pixel_on = is_highlighted && move_options [y_bitmap][7-x_bitmap] && inside_bitmap;
    assign active = valid && pixel_on;

    reg [2:0] red_r, green_r, blue_r;
    
    always @(posedge clk) begin
        red   <= red_r;
        green <= green_r;
        blue  <= blue_r;
    end
    
    always @(*) begin
        if (active) begin
            red_r   = 3'b111;
            green_r = 3'b111;
            blue_r  = 3'b000;
        end else begin
            red_r   = 3'b000;
            green_r = 3'b000;
            blue_r  = 3'b000;
        end
    end
    
endmodule
