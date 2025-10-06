module top (
    input wire clk_100mhz,
    input wire rst,
    input wire [10:0] cursor_x,
    input wire [10:0] cursor_y,
    input wire [255:0] boardData,
    input wire [5:0] cursorPosition,
    input wire [63:0] moveOptions,
    input wire [5:0] selectedPosition,
    input wire loading,
    input wire turn,
    input wire update,
    
    //outputs
    output wire hsync,
    output wire vsync,
    output wire [2:0] RED,
    output wire [2:0] GREEN,
    output wire [2:0] BLUE

    
);

    // Clock generation
    wire clk_pixel;
    wire clk_locked;

    clk_gen clk_inst (
        .clk_in1(clk_100mhz),
        .reset(1'b0),
        .clk_pixel(clk_pixel),
        .locked(clk_locked)
    );
   

    // VGA signals
    wire [10:0] x, y;
    wire valid;

    vga_controller vga_inst (
        .clk(clk_pixel),
        .rst(~clk_locked),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .x(x),
        .y(y)
    );
    

    // RGB wires from board and pieces
    wire [2:0] board_r, board_g, board_b;
    wire [2:0] piece_r, piece_g, piece_b;
    wire draw_piece;

    // Draw chess board
    chessBoard_vga board_inst (
        .clk(clk_pixel),
        .x(x),
        .y(y),
        .valid(valid),
        .red(board_r),
        .green(board_g),
        .blue(board_b)
    );

    // Draw chess pieces
    chessPieces pieces_inst (
        .clk(clk_pixel),
        .x(x),
        .y(y),
        .valid(valid),
        .boardData(boardData),
        .red(piece_r),
        .green(piece_g),
        .blue(piece_b),
        .active(draw_piece),
        .turn(turn)
    );
    
    wire [2:0] options_r, options_g, options_b;
    wire draw_options;
    
    MoveOptions move_options (
        .clk(clk_pixel),
        .x(x),
        .y(y),
        .valid(valid),
        .moveOptions(moveOptions),
        .red(options_r),
        .green(options_g),
        .blue(options_b),
        .active(draw_options),
        .turn(turn)
    );
    
    wire [2:0] cursor_r, cursor_g, cursor_b;
    wire draw_cursor;
    cursor_vga cursor_inst (
        .clk(clk_pixel),
        .x(x),
        .y(y),
        .valid(valid),
        .cursor_x(cursor_x),
        .cursor_y(cursor_y),
        .red(cursor_r),
        .green(cursor_g),
        .blue(cursor_b),
        .active(draw_cursor)
    );
    

    // Final pixel output: pieces override board
    assign RED = valid ? (draw_cursor ? cursor_r : (draw_options ? options_r : (draw_piece ? piece_r : board_r))) : 3'b000;
    assign GREEN = valid ? (draw_cursor ? cursor_g : (draw_options ? options_g : (draw_piece ? piece_g : board_g))) : 3'b000;
    assign BLUE = valid ? (draw_cursor ? cursor_b : (draw_options ? options_b : (draw_piece ? piece_b : board_b))) : 3'b000;
        
    
endmodule