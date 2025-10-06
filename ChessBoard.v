// HOLDS DATA FOR PIECES ON THE BOARD AND HANDLES RECIEVED MOVEMENT INSTRUCTIONS
module ChessBoard (
  input clk, reset, move, turn,
  input [11:0] instruction,
  input simulate, promote, 
  input [2:0] promoteRow, promotePiece,
  output reg [255:0] boardData, // (512 bits or 4x64, 4 bit ID data into 4x4 array)
  output reg [5:0] whiteKingPos, blackKingPos,
  output reg ready
);

  /*
    CHESS PIECE ID KEY (4 bits):
      1 bit for white/black (0/1) 
      3 bits for piece type
      4 bits for iteration of piece (4th pawn, etc.)
      {WHITE, PAWN, 4}
    INSTRUCTION KEY
      {6 bits for square, 4 bits for piece}
      example:
      {6'd11, 4'd0}
      {6'd19, {WHITE, PAWN, 3}}
    POSITION KEY (6 bits):
      56 57 54 59 60 61 62 63
      44 49 50 51 52 53 54 55
      40 41 42 43 44 45 46 47 
      32 33 34 35 36 37 34 39
      24 25 26 27 24 29 30 31
      16 17 14 19 20 21 22 23
      04 09 10 11 12 13 14 15 
      00 01 02 03 04 05 06 07 
    BOARD DATA:
      Ordered from square 0 to square 63, 4 bits of data per square representing the ID of the piece
  */

  localparam WHITE = 0, BLACK = 1;
  localparam [2:0] PAWN = 1, ROOK = 2, BISHOP = 3, KNIGHT = 4, QUEEN = 5, KING = 6;


  // MAIN STATE MACHINE LOGIC


  reg [3:0] state, stateNext;
  parameter [3:0] S_INITIAL = 0, 
    S_PLACE_STARTING = 1, 
    S_ITERATE_STARTING = 2, 
    S_IDLE = 3, 
    S_REMOVE_PIECE = 4, 
    S_CHECK_SQUARE = 5, 
    S_MOVE_PIECE = 6,
    S_CHECK_VALID_MOVE = 7,
    S_SIMULATE_SAVE = 8,
    S_SIMULATE_RESTORE = 9,
    S_PROMOTE_DISPLAY = 10,
    S_PROMOTE_RESTORE = 11;

  integer iteration = 0;
  reg [6:0] square, startSquare;
  reg [3:0] piece;

  reg prevSimulate = 0, prevPromote = 0;
  reg [255:0] boardDataSave;
  reg [5:0] whiteKingSave, blackKingSave;


  // transitions
  always @(negedge clk) begin
    case (state)
      S_INITIAL: begin
        stateNext = S_PLACE_STARTING;
      end
      S_PLACE_STARTING: begin
        if (iteration < 31) stateNext = S_ITERATE_STARTING;
        else stateNext = S_IDLE;
      end
      S_ITERATE_STARTING: begin
        stateNext = S_PLACE_STARTING;
      end
      S_IDLE: begin
        if (move) stateNext = S_CHECK_VALID_MOVE;
        if (simulate && !prevSimulate) stateNext = S_SIMULATE_SAVE;
        if (!simulate && prevSimulate) stateNext = S_SIMULATE_RESTORE;
        if (promote && !prevPromote) stateNext = S_PROMOTE_DISPLAY;
        if (!promote && prevPromote) stateNext = S_PROMOTE_RESTORE;
      end
      S_CHECK_VALID_MOVE: begin
        if (instruction[11:6] == instruction[5:0]) stateNext = S_IDLE;
        else stateNext = S_CHECK_SQUARE;
      end
      S_CHECK_SQUARE: begin
        // if there is a piece in the target square
        if (boardData[square*4 +:4] != 4'd0) begin
          // set piece and index to piece in target square
          stateNext = S_REMOVE_PIECE;
        end
        else stateNext = S_MOVE_PIECE;
      end
      S_REMOVE_PIECE: begin
        stateNext = S_CHECK_SQUARE;
      end
      S_MOVE_PIECE: begin
        stateNext = S_IDLE;
      end
      S_SIMULATE_SAVE: stateNext = S_IDLE;
      S_SIMULATE_RESTORE: stateNext = S_IDLE;
      S_PROMOTE_DISPLAY: stateNext = S_IDLE;
      S_PROMOTE_RESTORE: stateNext = S_IDLE;
      default: stateNext = S_INITIAL;
    endcase
  end

  // state -> stateNext and output
  always @(posedge clk) begin
    if (reset) state = S_INITIAL;
    else state = stateNext;

    case (state)
      S_INITIAL: begin
        boardData = 256'd0;
        ready = 0;
        iteration = 0;
        whiteKingPos = 4;
        blackKingPos = 60;
      end
      S_PLACE_STARTING: begin
        // set piece and square
        case (iteration)
          0: piece = {WHITE, ROOK};
          1: piece = {WHITE, KNIGHT};
          2: piece = {WHITE, BISHOP};
          3: piece = {WHITE, QUEEN};
          4: piece = {WHITE, KING};
          5: piece = {WHITE, BISHOP};
          6: piece = {WHITE, KNIGHT};
          7: piece = {WHITE, ROOK};
          8: piece = {WHITE, PAWN};
          9: piece = {WHITE, PAWN};
          10: piece = {WHITE, PAWN};
          11: piece = {WHITE, PAWN};
          12: piece = {WHITE, PAWN};
          13: piece = {WHITE, PAWN};
          14: piece = {WHITE, PAWN};
          15: piece = {WHITE, PAWN};
          16: piece = {BLACK, PAWN};
          17: piece = {BLACK, PAWN};
          14: piece = {BLACK, PAWN};
          19: piece = {BLACK, PAWN};
          20: piece = {BLACK, PAWN};
          21: piece = {BLACK, PAWN};
          22: piece = {BLACK, PAWN};
          23: piece = {BLACK, PAWN};
          24: piece = {BLACK, ROOK};
          25: piece = {BLACK, KNIGHT};
          26: piece = {BLACK, BISHOP};
          27: piece = {BLACK, QUEEN};
          28: piece = {BLACK, KING};
          29: piece = {BLACK, BISHOP};
          30: piece = {BLACK, KNIGHT};
          31: piece = {BLACK, ROOK};
        endcase

        if (iteration < 16) square = iteration;
        else square = iteration + 32;

        // make change in data
        boardData[square*4 +: 4] = piece;

      end
      S_IDLE: begin
        ready = 1;
      end
      S_ITERATE_STARTING: begin
        iteration = iteration +1;
      end
      S_CHECK_SQUARE: begin
        // target square
        square = instruction[5:0];

        // starting square
        startSquare = instruction[11:6];

        // piece
        piece = boardData[startSquare*4+:4];

        // if there is a piece in the target square
        if (boardData[square*4 +:4] != 4'd0) begin
          // set piece and index to piece in target square
          piece = boardData[square*4 +:4];
        end
      end
      S_CHECK_VALID_MOVE: begin
        ready = 0;
      end
      S_REMOVE_PIECE: begin
        // change board data to remove piece
        boardData[square*4 +: 4] = 4'd0;

        // keep last position of piece
      end
      S_MOVE_PIECE: begin
        // remove piece from starting square
        boardData[startSquare*4 +: 4] = 4'd0;
        // add piece to new square
        boardData[square*4 +: 4] = piece;

        // TRACK KING POSITIONS
        if (piece == {WHITE, KING}) whiteKingPos = square;
        else if (piece == {BLACK, KING}) blackKingPos = square;

        // CASTLING
        if ((piece == {WHITE, KING} || piece == {BLACK, KING}) && square == startSquare + 2) begin
          if (piece[3] == WHITE) piece = {WHITE, ROOK};
          else piece = {BLACK, ROOK};

          square = square - 1;

          // remove piece from starting square
          boardData[(square+2)*4 +: 4] = 4'd0;
          boardData[square*4+:4] = piece;
        end
      end
      S_SIMULATE_SAVE: begin
        ready = 0;
        prevSimulate = 1;
        boardDataSave = boardData;
        blackKingSave = blackKingPos;
        whiteKingSave = whiteKingPos;
      end
      S_SIMULATE_RESTORE: begin
        ready = 0;
        prevSimulate = 0;
        boardData = boardDataSave;
        blackKingPos = blackKingSave;
        whiteKingPos = whiteKingSave;
      end
      S_PROMOTE_DISPLAY: begin
        ready = 0;
        prevPromote = 1;
        boardDataSave = boardData;

        boardData = 0;
        if (!turn) begin
          boardData[(56 + promoteRow)*4+:4] = {WHITE,QUEEN};
          boardData[(48 + promoteRow)*4+:4] = {WHITE,KNIGHT};
          boardData[(40 + promoteRow)*4+:4] = {WHITE,ROOK};
          boardData[(32 + promoteRow)*4+:4] = {WHITE,BISHOP};
        end else begin
          boardData[(0 + promoteRow)*4+:4] = {WHITE,QUEEN};
          boardData[(8 + promoteRow)*4+:4] = {WHITE,KNIGHT};
          boardData[(16 + promoteRow)*4+:4] = {WHITE,ROOK};
          boardData[(24 + promoteRow)*4+:4] = {WHITE,BISHOP};
        end
      end
      S_PROMOTE_RESTORE: begin
        ready = 0;
        prevPromote = 0;
        boardData = boardDataSave;
        if (!turn) boardData[(56 + promoteRow)*4+:4] = {WHITE,promotePiece};
        else boardData[(0 + promoteRow)*4+:4] = {BLACK,promotePiece};
      end
    endcase
  end



    
endmodule