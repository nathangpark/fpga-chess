module ModifyOptionsHandler (
  input clk, reset, update, pieceReady, boardReady, allReady, turn, selected, checkmateReady,
  input [1:0] check,
  input [5:0] selectedPosition,
  input [63:0] moveOptions,
  output reg [11:0] instruction,
  output reg [63:0] modifiedMoveOptions,
  output reg simulate, ready, updateAll, move
);

  localparam WHITE = 0, BLACK = 1;
  localparam [2:0] PAWN = 1, ROOK = 2, BISHOP = 3, KNIGHT = 4, QUEEN = 5, KING = 6;
  
  reg [5:0] i = 0;

  reg [3:0] state, stateNext = 0;
  parameter [3:0] S_INITIAL = 0, // initial
    S_IDLE = 1,  // while waiting for a request to update pieces
    S_CHECK_MOVE = 2, 
    S_SIMULATE_MOVE = 3, 
    S_ITERATE = 4, 
    S_CHECK_SIMULATION = 5,
    S_WAIT_FOR_SIMULATED_READY = 6,
    S_REMOVE_OPTION = 7,
    S_RESET_BOARD = 8,
    S_WAIT_FOR_PIECE_READY = 9, // while waiting for confirmation that pieces are ready to be checked
    S_SAVE_OPTIONS = 10,
    S_WAIT_FOR_RESET_READY = 11,
    S_WAIT_FOR_ALL_READY = 12,
    S_START_CHECK_ALL = 13,
    S_IDLE_MODIFIED = 14,
    S_WAIT_FOR_BOARD_SAVE_READY = 15;


  // transitions
  always @(negedge clk) begin
    case (state) 
      S_INITIAL: begin
        stateNext = S_IDLE;
      end
      S_IDLE: begin
        if (update) stateNext = S_WAIT_FOR_PIECE_READY;
      end
      S_WAIT_FOR_PIECE_READY: begin
        if (pieceReady) stateNext = S_SAVE_OPTIONS;
      end
      S_SAVE_OPTIONS: begin
        if (modifiedMoveOptions == moveOptions) stateNext = S_CHECK_MOVE;
      end
      S_CHECK_MOVE: begin
        // STARTS PROCESS OF CHECKING SIMULATED MOVE
        if (modifiedMoveOptions[i] == 1) stateNext = S_SIMULATE_MOVE;
        else if (i < 63) stateNext = S_ITERATE;
        else stateNext = S_IDLE_MODIFIED;
      end
      S_ITERATE: begin
        // MOVES TO CHECK MOVE
        stateNext = S_CHECK_MOVE;
      end
      S_SIMULATE_MOVE: begin
        stateNext = S_WAIT_FOR_BOARD_SAVE_READY;
      end
      S_WAIT_FOR_BOARD_SAVE_READY: begin
        if (boardReady) stateNext = S_WAIT_FOR_SIMULATED_READY;
      end
      S_WAIT_FOR_SIMULATED_READY: begin
        if (boardReady) stateNext = S_START_CHECK_ALL;
      end
      S_START_CHECK_ALL: begin
        stateNext = S_WAIT_FOR_ALL_READY;
      end
      S_WAIT_FOR_ALL_READY: begin
        if (allReady) stateNext = S_CHECK_SIMULATION;
      end
      S_CHECK_SIMULATION: begin 
        if (checkmateReady && check[!turn]) stateNext = S_REMOVE_OPTION;
        else if (!checkmateReady && check[turn]) stateNext = S_REMOVE_OPTION;
        else stateNext = S_RESET_BOARD;
      end
      S_REMOVE_OPTION: begin
        stateNext = S_RESET_BOARD;
      end
      S_RESET_BOARD: begin
        stateNext = S_WAIT_FOR_RESET_READY;
      end
      S_WAIT_FOR_RESET_READY: begin
        if (boardReady) begin
          if (i < 63) stateNext = S_ITERATE;
          else stateNext = S_IDLE_MODIFIED;
        end
      end
      S_IDLE_MODIFIED: begin
        if (!selected) stateNext = S_IDLE;
        if (update) stateNext = S_WAIT_FOR_PIECE_READY;
      end
    endcase
  end

  // state -> stateNext and output
  always @(posedge clk) begin
    if (reset) state = S_INITIAL;
    else state = stateNext;

    case (state)
      S_INITIAL: begin
        simulate = 0;
        ready = 1;
        modifiedMoveOptions = 0;
        updateAll = 0;
        move = 0;
      end
      S_IDLE: begin
        i = 0;
        ready = 1;
        modifiedMoveOptions = 0;
      end
      S_WAIT_FOR_PIECE_READY: begin
        ready = 0;
      end
      S_CHECK_MOVE: begin
        // do nothign
      end
      S_SIMULATE_MOVE: begin
        // send instruction to board
        simulate = 1;
        instruction <= {selectedPosition,i};
        move = 1;
      end
      S_WAIT_FOR_SIMULATED_READY: begin
        move = 0;
      end
      S_START_CHECK_ALL: begin
        updateAll = 1;
      end
      S_WAIT_FOR_ALL_READY: begin
        updateAll = 0;
      end
      S_ITERATE: begin
        if (i < 63) i = i + 1;
      end
      S_REMOVE_OPTION: begin
        modifiedMoveOptions[i] = 0;
      end
      S_RESET_BOARD: begin
        simulate = 0;
      end
      S_SAVE_OPTIONS: begin
        i = 0;
        modifiedMoveOptions = moveOptions;
      end
      S_WAIT_FOR_RESET_READY: begin
        if (i == 63) begin
          instruction <= 14'b0; // send invalid instruction
        end
      end
      S_IDLE_MODIFIED: begin
        ready = 1;
        i = 0;
      end
      
    endcase
  end


endmodule;