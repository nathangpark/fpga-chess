module ChessTop (
    input wire clk,
    input wire reset,
    output wire hsync,
    output wire vsync,
    output wire [2:0] RED,
    output wire [2:0] GREEN,
    output wire [2:0] BLUE,
    output wire [6:0] ssd,
    output wire [7:0] anode_enable,
    output wire [1:1] JA,
    output wire [15:0] led,

    // Mouse
    inout ps2_clk,
    inout ps2_data
);

    wire [1:0] timeout;

    assign led[15:8] = timeout[1] || checkmate == 1 ? 8'b11111111 : 8'b00000000;
    assign led[7:0] = timeout[0] || checkmate > 1 ? 8'b11111111 : 8'b00000000;
    
    
    wire speaker_out;

    moveSoundEffect soundPlayer (
    .clk(clk),         
    .moveSound(moveSound),  
    .speaker_out(JA[1]) 
    ); 


    ChessClock chessClock(
    
    .clk(clk),
    .reset(reset),
    .move(moveSound),
    .turn(turn),
    .checkmate(checkmate),
    .ssd(ssd),
    .anode_enable(anode_enable),
    .timeout(timeout)
    );
    

    //DIGILENT MOUSE LOGIC
    wire [11:0] xpos;
    wire [11:0] ypos;
    wire [7:0]  zpos;
    wire left, middle, right;
    
    MouseCtl mouse_inst (
        .clk(clk),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .xpos(xpos),
        .ypos(ypos),
        .zpos(zpos),
        .left(left),
        .middle(middle),
        .right(right)
    );
    
    
    localparam TILE_WIDTH  = 160;
    localparam TILE_HEIGHT = 128;
    
    wire [2:0] cursor_col = xpos / TILE_WIDTH;
    wire [2:0] cursor_row = ypos / TILE_HEIGHT;
     
    wire [5:0] cursorPosition = turn ? cursor_row * 8 + (7 - cursor_col) : (7 - cursor_row) * 8 + cursor_col;
    

    wire [255:0] boardData;
    wire [63:0] moveOptions;
    wire [5:0] selectedPosition;
    wire loading;
    wire [1:0] checkmate; 
    wire turn, moveSound;  



    // === Chess VGA Display
    top display (
        .clk_100mhz(clk),
        .rst(reset),
        .boardData(boardData),
        .moveOptions(moveOptions),
        .selectedPosition(selectedPosition),
        .cursor_x(xpos),
        .cursor_y(ypos),
        .loading(loading),
        .turn(turn),
        .hsync(hsync),
        .vsync(vsync),
        .RED(RED),
        .GREEN(GREEN),
        .BLUE(BLUE)
    );
 
    ChessController chessController(
        .clk(clk),
        .reset(reset),
        .BTNC(left),
        .boardData(boardData),
        .cursorPosition(cursorPosition),
        .moveOptions(moveOptions),
        .selectedPosition(selectedPosition),
        .loading(loading),
        .checkmate(checkmate),
        .turn(turn),
        .moveSound(moveSound),
        .timeout(timeout)
    );
    

endmodule
