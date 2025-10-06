module chessPieces (
    input wire clk,
    input wire [10:0] x,
    input wire [10:0] y,
    input wire valid,
    input wire [255:0] boardData, 
    output reg [2:0] red,
    output reg [2:0] green,
    output reg [2:0] blue,
    output wire active,
    input wire turn
);

    localparam TILE_WIDTH     = 160;
    localparam TILE_HEIGHT    = 128;
    localparam SPRITE_WIDTH   = 128;
    localparam SPRITE_HEIGHT  = 128;

    // Centering offsets
    localparam X_OFFSET = (TILE_WIDTH - SPRITE_WIDTH) / 2;   // 16
    localparam Y_OFFSET = (TILE_HEIGHT - SPRITE_HEIGHT) / 2; // 0

    // === Tile Position ===
    wire [2:0] col = x / TILE_WIDTH;
    wire [2:0] row = y / TILE_HEIGHT;

    wire [7:0] x_tile = x % TILE_WIDTH;
    wire [7:0] y_tile = y % TILE_HEIGHT;

    wire [7:0] x_local = x_tile - X_OFFSET;
    wire [7:0] y_local = y_tile - Y_OFFSET;

    wire inside_bitmap = (x_local < SPRITE_WIDTH) && (y_local < SPRITE_HEIGHT);

    // === Piece Info ===
    wire [5:0] pos = turn ? row * 8 + (7 - col) : (7 - row) * 8 + col;
    wire [3:0] cur_piece = boardData[pos * 4 +: 4];
    wire color_bit = cur_piece[3];
    wire [2:0] piece_type = cur_piece[2:0];  // 1 to 6, 0 = empty

    // === Sprite Memory Access ===
    wire [10:0] mem_index = (piece_type - 1) * SPRITE_HEIGHT + y_local;

    (* ram_style = "block" *) reg [255:0] sprite_memory [0:767]; // 128 rows * 6 pieces
    initial $readmemh("sprites.mem", sprite_memory);

    reg [255:0] row_bits;
    always @(posedge clk) begin
        if (inside_bitmap && piece_type != 3'd0)
            row_bits <= sprite_memory[mem_index];
        else
            row_bits <= 256'd0;
    end

    wire [1:0] pixel_code = row_bits[255 - (x_local * 2) -: 2];
    assign active = valid && (pixel_code != 2'b00);

    reg [2:0] red_r, green_r, blue_r;
    always @(posedge clk) begin
        red   <= red_r;
        green <= green_r;
        blue  <= blue_r;
    end
    
    always @(*) begin
        red_r = 3'b000;
        green_r = 3'b000;
        blue_r = 3'b000;
    
        if (active) begin
            case (pixel_code)
                2'b01: begin
                    if (color_bit) begin
                        red_r = 3'b000;
                        green_r = 3'b000;
                        blue_r = 3'b000;
                    end else begin
                        red_r = 3'b000;
                        green_r = 3'b000;
                        blue_r = 3'b000;
                    end
                end
                2'b10: begin
                    if (color_bit) begin
                        red_r = 3'b010;
                        green_r = 3'b010;
                        blue_r = 3'b010;
                    end else begin
                        red_r = 3'b111;
                        green_r = 3'b111;
                        blue_r = 3'b111;
                    end
                end
            endcase
        end
    end
    

endmodule
