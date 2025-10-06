module CheckAllController (
  input clk, reset,
  input pieceReady, updateAll,
  input [1:0] check,
  input [255:0] boardData,
  output reg [5:0] position, 
  output reg [1:0] checkOut,
  output reg ready, checkingAll, updatePiece
);


  reg [2:0] state, stateNext;

  parameter [2:0] S_INITIAL = 0,
    S_IDLE = 1,
    S_DETERMINE_EMPTY = 2,
    S_SET_POSITION = 3,
    S_WAIT_FOR_PIECE_READY = 4,
    S_DETERMINE_CHECK = 5,
    S_ITERATE_POSITION = 6,
    S_SET_CHECK = 7;

  // transitions
  always @(negedge clk) begin
    case (state) 
      S_INITIAL: stateNext = S_IDLE;
      S_IDLE: if (updateAll) stateNext = S_DETERMINE_EMPTY;
      S_DETERMINE_EMPTY: begin
        if (boardData[position*4+:4] > 0) stateNext = S_SET_POSITION;
        else begin
          if (position < 63) stateNext = S_ITERATE_POSITION;
          else stateNext = S_SET_CHECK;
        end
      end
      S_SET_POSITION: stateNext = S_WAIT_FOR_PIECE_READY;
      S_WAIT_FOR_PIECE_READY: if (pieceReady) stateNext = S_DETERMINE_CHECK;
      S_DETERMINE_CHECK: begin
        if (check > 0) stateNext = S_SET_CHECK;
        else begin
          if (position < 63) stateNext = S_ITERATE_POSITION;
          else stateNext = S_SET_CHECK;
        end
      end
      S_ITERATE_POSITION: stateNext = S_DETERMINE_EMPTY;
      S_SET_CHECK: stateNext = S_IDLE;
      default: stateNext = S_INITIAL;
    endcase
  end

  // state -> stateNext and output
  always @(posedge clk) begin
    if (reset) state = S_INITIAL;
    else state = stateNext;

    case (state)
      S_INITIAL: begin
        position = 0;
        checkingAll = 0;
        ready = 1;

        checkOut = 0;
        updatePiece = 0;
      end
      S_IDLE: begin
        position = 0;
        ready = 1;
        checkingAll = 0;
      end
      S_DETERMINE_EMPTY: begin
        checkingAll = 1;
        checkOut = 0;
        ready = 0;
      end
      S_SET_POSITION: begin
        updatePiece = 1;
      end
      S_WAIT_FOR_PIECE_READY: begin
        updatePiece = 0;
      end
      S_DETERMINE_CHECK: begin
        // do nothing
      end
      S_SET_CHECK: begin
        checkOut = check;
      end
      S_ITERATE_POSITION: begin
        position = position + 1;
      end
      
    endcase
  end


  endmodule