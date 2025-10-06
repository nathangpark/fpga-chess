module InstructionHandler (
  input clk, reset, center, 
  input pieceReady, modifyReady, boardReady, checkmateReady, 
  input [1:0] checkmate, timeout,
  input [5:0] cursorPosition,
  input [255:0] boardData,
  input [63:0] moveOptions,
  input [1:0] check,
  output reg updatePiece, ready, pieceSelected, updateModify, updateCheckmate,
  output reg [5:0] selectedPosition,
  output reg [11:0] instruction,
  output reg promote,
  output reg [2:0] promoteRow, promotePiece,
  output reg turn, move
);

  reg [4:0] state, stateNext;
  parameter [4:0] S_INITIAL = 0, 
    S_IDLE = 1, 
    S_SELECTED_PIECE = 2, 
    S_SELECTED_SQUARE = 3, 
    S_CHECK_VALID_MOVE = 4, 
    S_SET_INSTRUCTION = 5, 
    S_CLEAR_PIECE = 6,
    S_WAIT_FOR_PIECE_READY = 7,
    S_MODIFY_OPTIONS = 8,
    S_WAIT_FOR_MODIFY_READY = 9,
    S_UPDATE_PIECE = 10,
    S_WAIT_FOR_CHECK_READY = 11,
    S_DETERMINE_CHECK = 12,
    S_START_CHECKMATE = 13,
    S_TOGGLE_TURN = 14,
    S_WAIT_FOR_BOARD_READY = 15,
    S_WAIT_FOR_CHECKMATE_READY = 16,
    S_DETERMINE_CHECKMATE = 17,
    S_CHECKMATE = 18, 
    S_SET_PROMOTE_ROW = 19,
    S_WAIT_FOR_PROMOTE_READY = 20,
    S_PROMOTE_IDLE = 21,
    S_SET_PROMOTE_PIECE = 22;

  localparam WHITE = 0, BLACK = 1;
  localparam [2:0] PAWN = 1, ROOK = 2, BISHOP = 3, KNIGHT = 4, QUEEN = 5, KING = 6;

  reg [7:0] piece = 0;
  reg [5:0] startSquare = 0, targetSquare = 0;

  // transitions
  always @(negedge clk) begin
    case (state) 
      S_INITIAL: begin
        stateNext = S_IDLE;
      end
      S_IDLE: begin
        if (center) begin
          if (!pieceSelected) stateNext = S_SELECTED_PIECE;
          else stateNext = S_SELECTED_SQUARE;
        end
      end
      S_SELECTED_PIECE: stateNext = S_WAIT_FOR_PIECE_READY;
      S_WAIT_FOR_PIECE_READY: if (pieceReady && !center) stateNext = S_MODIFY_OPTIONS;
      S_MODIFY_OPTIONS: stateNext = S_WAIT_FOR_MODIFY_READY;
      S_WAIT_FOR_MODIFY_READY: if (modifyReady) stateNext = S_IDLE;
      S_SELECTED_SQUARE: if (!center) stateNext = S_CHECK_VALID_MOVE;
      S_CHECK_VALID_MOVE: begin
        if (moveOptions[targetSquare] == 1) stateNext = S_SET_INSTRUCTION;
        else stateNext = S_CLEAR_PIECE;
      end
      S_SET_INSTRUCTION: stateNext = S_WAIT_FOR_BOARD_READY;
      S_WAIT_FOR_BOARD_READY: begin
        if (boardReady) begin
          if (piece[2:0] == PAWN) begin
            if (turn && targetSquare < 8) stateNext = S_SET_PROMOTE_ROW;
            else if (!turn && targetSquare > 55) stateNext = S_SET_PROMOTE_ROW;
            else stateNext = S_UPDATE_PIECE;
          end
          else stateNext = S_UPDATE_PIECE;
        end
      end
      S_SET_PROMOTE_ROW: begin
        stateNext = S_WAIT_FOR_PROMOTE_READY;
      end
      S_WAIT_FOR_PROMOTE_READY: begin
        if (boardReady && pieceReady && !center) stateNext = S_PROMOTE_IDLE;
      end
      S_PROMOTE_IDLE: begin
        if (center) begin
          if (cursorPosition > 31 && cursorPosition % 8 == promoteRow) stateNext = S_SET_PROMOTE_PIECE;
        end
      end
      S_SET_PROMOTE_PIECE: stateNext = S_WAIT_FOR_BOARD_READY;
      S_UPDATE_PIECE: stateNext = S_WAIT_FOR_CHECK_READY;
      S_WAIT_FOR_CHECK_READY: if (pieceReady) stateNext = S_DETERMINE_CHECK;
      S_DETERMINE_CHECK: begin
        if (check[turn]) stateNext = S_START_CHECKMATE;
        else stateNext = S_TOGGLE_TURN;
      end
      S_CLEAR_PIECE: if (!center) stateNext = S_IDLE;
      S_TOGGLE_TURN: stateNext = S_CLEAR_PIECE;
      S_START_CHECKMATE: stateNext = S_WAIT_FOR_CHECKMATE_READY;
      S_WAIT_FOR_CHECKMATE_READY: if (checkmateReady) stateNext = S_DETERMINE_CHECKMATE;
      S_DETERMINE_CHECKMATE: begin
        if (checkmate > 0) stateNext = S_CHECKMATE;
        else stateNext = S_TOGGLE_TURN;
      end
      default: stateNext = S_INITIAL;
    endcase
  end

  // state -> stateNext and output
  always @(posedge clk) begin
    if (reset) state = S_INITIAL;
    else if (timeout > 0) state = S_CHECKMATE;
    else state = stateNext;

    case (state)
      S_INITIAL: begin
        promote = 0;
        move = 0;
        turn = 0;
        piece = 8'd0;
        startSquare = 0;
        targetSquare = 0;
        selectedPosition = 6'b0;
        instruction = 0;
        updatePiece = 0;
        pieceSelected = 0;
        updateModify = 0;
        updateCheckmate = 0;
      end
      S_IDLE: begin
        updatePiece = 0;
        ready = 1;
      end
      S_SELECTED_PIECE: begin
        if (boardData[cursorPosition*4 + 3] == turn && boardData[cursorPosition*4+:4] > 0) begin
          pieceSelected = 1;
          selectedPosition = cursorPosition;
          startSquare = cursorPosition;
          piece = boardData[cursorPosition*4+:4];
          updatePiece = 1;
          ready = 0;
        end
      end
      S_SET_PROMOTE_ROW: begin
        promote = 1;
        promoteRow = targetSquare % 8;
        ready = 0;
        pieceSelected = 0;
        updatePiece = 1;
      end
      S_WAIT_FOR_PROMOTE_READY: begin
        updatePiece = 0;
      end
      S_PROMOTE_IDLE: begin
        ready = 1;
      end
      S_SET_PROMOTE_PIECE: begin
        promote = 0;
        ready = 0;
        if (cursorPosition > 55) promotePiece = QUEEN;
        else if (cursorPosition > 47) promotePiece = KNIGHT;
        else if (cursorPosition > 39) promotePiece = ROOK;
        else promotePiece = BISHOP;
        piece[2:0] = promotePiece;
        pieceSelected = 1;
      end
      S_MODIFY_OPTIONS: updateModify = 1;
      S_WAIT_FOR_MODIFY_READY: updateModify = 0;
      S_CHECK_VALID_MOVE: begin
        ready = 0;
      end
      S_SELECTED_SQUARE: begin
        targetSquare = cursorPosition;
      end
      S_SET_INSTRUCTION: begin
        instruction = {startSquare, targetSquare};
        move = 1;
        // set initial square for check
        selectedPosition = 0;
      end
      S_WAIT_FOR_BOARD_READY: begin
        move = 0;
      end
      S_UPDATE_PIECE: begin
        updatePiece = 1;
        selectedPosition = targetSquare;
      end
      S_WAIT_FOR_PIECE_READY: begin
        updatePiece = 0;
      end
      S_CLEAR_PIECE: begin
        move = 0;
        updatePiece = 1;
        piece = 8'd0;
        pieceSelected = 0;
      end
      S_WAIT_FOR_CHECK_READY: begin
        updatePiece = 0;
      end
      S_START_CHECKMATE: begin
        updateCheckmate = 1;
      end
      S_WAIT_FOR_CHECKMATE_READY: begin
        updateCheckmate = 0;
      end
      S_CHECKMATE: begin
        ready = 1;
      end
      S_TOGGLE_TURN: begin
        move = 0;
        turn = !turn;
        pieceSelected = 0;
      end
    endcase
  end



endmodule