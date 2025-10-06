module CheckmateController (
  input clk, reset,
  input update, turn, modifyReady,
  input [63:0] moveOptions,
  input [255:0] boardData,
  output reg [5:0] selectedPosition,
  output reg updateModify, updatePiece, ready,
  output reg [1:0] checkmate
);


  reg [4:0] state = 0, stateNext = 0;
  parameter [4:0] S_INITIAL = 0, 
    S_IDLE = 1, 
    S_NEW_CHECK = 2, 
    S_UPDATE_MODIFY = 3,
    S_WAIT_FOR_MODIFY_READY = 4, 
    S_CHECK_MATE = 5, 
    S_ITERATE = 6, 
    S_IS_NOT_MATE = 7, 
    S_IS_MATE = 8,
    S_DETERMINE_EMPTY = 9;

  // transitions
  always @(negedge clk) begin
    case (state) 
      S_INITIAL: stateNext = S_IDLE;
      S_IDLE: begin
        if (update) begin
          stateNext = S_NEW_CHECK;
        end
      end
      S_NEW_CHECK: stateNext = S_DETERMINE_EMPTY;
      S_DETERMINE_EMPTY: begin
        if (boardData[selectedPosition*4 + 3] == !turn && boardData[selectedPosition*4+:4] > 0) stateNext = S_UPDATE_MODIFY;
        else begin
          if (selectedPosition == 63) stateNext = S_IS_MATE;
          else stateNext = S_ITERATE;
        end
      end
      S_UPDATE_MODIFY: begin
        stateNext = S_WAIT_FOR_MODIFY_READY;
      end
      S_WAIT_FOR_MODIFY_READY: begin
        if (modifyReady) stateNext = S_CHECK_MATE;
      end
      S_CHECK_MATE: begin
        if (moveOptions == 64'b0) begin
          if (selectedPosition == 63) stateNext = S_IS_MATE;
          else stateNext = S_ITERATE;
        end
        else stateNext = S_IS_NOT_MATE;
      end
      S_ITERATE: begin
        stateNext = S_DETERMINE_EMPTY;
      end
      S_IS_MATE: stateNext = S_IS_MATE;
      S_IS_NOT_MATE: stateNext = S_IDLE;
      default: stateNext = S_INITIAL;
    endcase
  end

  // state -> stateNext and output
  always @(posedge clk) begin
    if (reset) state = S_INITIAL;
    else state = stateNext;

    case (state)
      S_INITIAL:begin
        checkmate = 0;
        ready = 1;
        updateModify = 0;
      end
      S_IDLE: begin
        selectedPosition = 0;
        ready = 1;
        checkmate = 0;
        updateModify = 0;
      end
      S_NEW_CHECK: begin
        selectedPosition = 0;
        ready = 0;
      end
      S_UPDATE_MODIFY: begin
        updatePiece = 1;
        updateModify = 1;
      end
      S_WAIT_FOR_MODIFY_READY: begin
        updatePiece = 0;
        updateModify = 0;
      end
      S_IS_NOT_MATE: checkmate = 0;
      S_IS_MATE: begin
        checkmate[turn] = 1;
        ready = 1;
      end
      S_ITERATE: begin
        selectedPosition = selectedPosition + 1;
      end
    endcase
  end


endmodule