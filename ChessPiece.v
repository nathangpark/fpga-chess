module ChessPiece (
    input clk, reset,
    input [5:0] position, whiteKingPos, blackKingPos, // position
    input update, selected,
    input [255:0] boardData,
    output reg [63:0] moveOptions, // 64 bits represent 8x8 2D array, 1 if possible to move to, 0 if not possible to move to
    output reg ready, 
    output reg [1:0] check
  );

  /*
    position/ID key 6 bits:
      56 57 58 59 60 61 62 63
      48 49 50 51 52 53 54 55
      40 41 42 43 44 45 46 47 
      32 33 34 35 36 37 38 39
      24 25 26 27 28 29 30 31
      16 17 18 19 20 21 22 23
      08 09 10 11 12 13 14 15 
      00 01 02 03 04 05 06 07 
  */
  reg [63:0] moveOptionsNext;
  integer iteration;
  reg [3:0] state, stateNext;
  reg [2:0] type;
  reg color;


  parameter [3:0] S_INITIAL = 0, 
    S_IDLE = 1, 
    S_UPDATE = 2, 
    S_GET_ALL = 3, 
    S_REMOVE = 4, 
    S_INCREMENT_REMOVE = 5,
    S_CHECK_CHECK = 6,
    S_CHECK_SELECTED = 7,
    S_WAIT_FOR_REG = 8;

  parameter WHITE = 0, BLACK = 1;
  parameter [2:0] PAWN = 1, ROOK = 2, BISHOP = 3, KNIGHT = 4, QUEEN = 5, KING = 6;


  // State transitions
  always @(negedge clk) begin
    case (state)
      S_INITIAL: begin
        stateNext = S_IDLE;
      end
      S_UPDATE: begin
        stateNext = S_CHECK_SELECTED;
      end
      S_CHECK_SELECTED: begin
        if (selected) stateNext = S_GET_ALL;
        else stateNext = S_IDLE;
      end
      S_IDLE: begin
        if (update) begin
          stateNext = S_UPDATE;
        end
      end
      S_GET_ALL: stateNext = S_WAIT_FOR_REG;
      S_WAIT_FOR_REG: if (moveOptions > 0) stateNext = S_REMOVE;
      S_REMOVE: begin
        case (type)
          ROOK: begin
            if (iteration == 6) stateNext = S_CHECK_CHECK;
            else stateNext = S_INCREMENT_REMOVE;
          end
          BISHOP: begin
            if (iteration == 6) stateNext = S_CHECK_CHECK;
            else stateNext = S_INCREMENT_REMOVE;
          end
          QUEEN: begin
            if (iteration == 6) stateNext = S_CHECK_CHECK;
            else stateNext = S_INCREMENT_REMOVE;
          end
          default: stateNext = S_CHECK_CHECK;
        endcase
      end
      S_INCREMENT_REMOVE: stateNext = S_REMOVE;
      S_CHECK_CHECK: stateNext = S_IDLE;
      default: stateNext = S_INITIAL;
    endcase
  end
  
  always @(posedge clk) begin
    moveOptions = moveOptionsNext;
   end
  

  // OUTPUT LOGIC
  always @(posedge clk) begin
    if (reset) state = S_INITIAL;
    else state = stateNext;

    case (state)
      S_INITIAL: begin
        ready = 0;
        moveOptionsNext = 64'b0;
        type = 0;
        check = 0;
        iteration = 0;
      end
      S_IDLE: begin
        ready = 1;
      end
      S_UPDATE: begin
        moveOptionsNext = 64'b0;
        iteration = 0;
        ready = 0;
        color = boardData[position*4 + 3];
        type = boardData[position*4+:3];
        check = 0;
      end
      S_INCREMENT_REMOVE: begin
        iteration <= iteration + 1;
      end
      S_GET_ALL: begin  
        // calculate moveOptionsNext
        case (type)
          // PAWN MOVES
          PAWN: begin
            case (color)
              WHITE: begin
                if (position < 16 && position > 7) moveOptionsNext[position + 16] = 1; // up 2 when in row 2
                if (position < 56) moveOptionsNext[position + 8] = 1; // up 1 when not in last row
                if (position % 8 > 0 && position < 56) moveOptionsNext[position + 7] = 1; // up 1 left 1
                if (position % 8 < 7 && position < 56) moveOptionsNext[position + 9] = 1; // up 1 right 1
              end
              BLACK: begin
                if (position < 56 && position > 46) moveOptionsNext[position - 16] = 1; // down 2 when in row 7
                if (position > 7) moveOptionsNext[position - 8] = 1; // down 1 when not in first row 
                if (position % 8 < 7 && position > 7) moveOptionsNext[position - 7] = 1; // down 1 right 1
                if (position % 8 > 0 && position > 7) moveOptionsNext[position - 9] = 1; // down 1 left 1
              end
            endcase
          end
          ROOK: begin
            // VERTICAL MOVEMENT
            moveOptionsNext[0 + position % 8] = position != 0 + position % 8;
            moveOptionsNext[8 + position % 8] = position != 8 + position % 8;
            moveOptionsNext[16 + position % 8] = position != 16 + position % 8;
            moveOptionsNext[24 + position % 8] = position != 24 + position % 8;
            moveOptionsNext[32 + position % 8] = position != 32 + position % 8;
            moveOptionsNext[40 + position % 8] = position != 40 + position % 8;
            moveOptionsNext[48 + position % 8] = position != 48 + position % 8;
            moveOptionsNext[56 + position % 8] = position != 56 + position % 8;

            // HORIZONTAL MOVEMENT
            moveOptionsNext[0 + position - (position % 8)] = 0 != position % 8;
            moveOptionsNext[1 + position - (position % 8)] = 1 != position % 8;
            moveOptionsNext[2 + position - (position % 8)] = 2 != position % 8;
            moveOptionsNext[3 + position - (position % 8)] = 3 != position % 8;
            moveOptionsNext[4 + position - (position % 8)] = 4 != position % 8;
            moveOptionsNext[5 + position - (position % 8)] = 5 != position % 8;
            moveOptionsNext[6 + position - (position % 8)] = 6 != position % 8;
            moveOptionsNext[7 + position - (position % 8)] = 7 != position % 8;
          end
          KNIGHT: begin
            moveOptionsNext[position - 10] = position % 8 > 1 && position > 7;
            moveOptionsNext[position - 17] = position % 8 > 0 && position > 15;
            moveOptionsNext[position - 15] = position % 8 < 7 && position > 15;
            moveOptionsNext[position - 6] = position % 8 < 6 && position > 7;
            moveOptionsNext[position + 10] = position % 8 < 6 && position < 56;
            moveOptionsNext[position + 17] = position % 8 < 7 && position < 48;
            moveOptionsNext[position + 15] = position % 8 > 0 && position < 48;
            moveOptionsNext[position + 6] = position % 8 > 1 && position < 56;
          end
          BISHOP: begin
            // TOP-RIGHT DIAGONAL
            moveOptionsNext[0 + position % 9] = (
              (0 + position % 9 < 9 * (8 - position % 9)) ~^ (position < 9 * (8 - position % 9))) && 
              position != 0 + position % 9;  
            moveOptionsNext[9 + position % 9] = 
              ((9 + position % 9 < 9 * (8 - position % 9)) ~^ (position < 9 * (8 - position % 9))) && 
              position != 9 + position % 9;
            moveOptionsNext[18 + position % 9] = 
              ((18 + position % 9 < 9 * (8 - position % 9)) ~^ (position < 9 * (8 - position % 9))) && 
              position != 18 + position % 9;
            moveOptionsNext[27 + position % 9] = 
              ((27 + position % 9 < 9 * (8 - position % 9)) ~^ (position < 9 * (8 - position % 9))) && 
              position != 27 + position % 9;
            moveOptionsNext[36 + position % 9] = 
              ((36 + position % 9 < 9 * (8 - position % 9)) ~^ (position < 9 * (8 - position % 9))) && 
              position != 36 + position % 9;
            moveOptionsNext[45 + position % 9] = 
              ((45 + position % 9 < 9 * (8 - position % 9)) ~^ (position < 9 * (8 - position % 9))) && 
              position != 45 + position % 9;
            moveOptionsNext[54 + position % 9] = 
              ((54 + position % 9 < 9 * (8 - position % 9)) ~^ (position < 9 * (8 - position % 9))) && 
              position != 54 + position % 9;
            moveOptionsNext[63] =
              position != 63 &&
              position % 9 == 0;              
            
            // TOP-LEFT DIAGONAL
            moveOptionsNext[0 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 0 + position % 7 < 7 * (position % 7 + 1)) && position != 0 + position % 7;
            moveOptionsNext[7 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 7 + position % 7 < 7 * (position % 7 + 1)) && position != 7 + position % 7;
            moveOptionsNext[14 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 14 + position % 7 < 7 * (position % 7 + 1)) && position != 14 + position % 7;
            moveOptionsNext[21 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 21 + position % 7 < 7 * (position % 7 + 1)) && position != 21 + position % 7;
            moveOptionsNext[28 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 28 + position % 7 < 7 * (position % 7 + 1)) && position != 28 + position % 7;
            moveOptionsNext[35 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 35 + position % 7 < 7 * (position % 7 + 1)) && position != 35 + position % 7;
            moveOptionsNext[42 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 42 + position % 7 < 7 * (position % 7 + 1)) && position != 42 + position % 7;
            moveOptionsNext[49 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 49 + position % 7 < 7 * (position % 7 + 1)) && position != 49 + position % 7;
            moveOptionsNext[56 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 56 + position % 7 < 7 * (position % 7 + 1)) && position != 56 + position % 7;
          end
          QUEEN: begin
            // VERTICAL MOVEMENT
            moveOptionsNext[0 + position % 8] = position != 0 + position % 8;
            moveOptionsNext[8 + position % 8] = position != 8 + position % 8;
            moveOptionsNext[16 + position % 8] = position != 16 + position % 8;
            moveOptionsNext[24 + position % 8] = position != 24 + position % 8;
            moveOptionsNext[32 + position % 8] = position != 32 + position % 8;
            moveOptionsNext[40 + position % 8] = position != 40 + position % 8;
            moveOptionsNext[48 + position % 8] = position != 48 + position % 8;
            moveOptionsNext[56 + position % 8] = position != 56 + position % 8;

            // HORIZONTAL MOVEMENT
            moveOptionsNext[0 + position - (position % 8)] = 0 != position % 8;
            moveOptionsNext[1 + position - (position % 8)] = 1 != position % 8;
            moveOptionsNext[2 + position - (position % 8)] = 2 != position % 8;
            moveOptionsNext[3 + position - (position % 8)] = 3 != position % 8;
            moveOptionsNext[4 + position - (position % 8)] = 4 != position % 8;
            moveOptionsNext[5 + position - (position % 8)] = 5 != position % 8;
            moveOptionsNext[6 + position - (position % 8)] = 6 != position % 8;
            moveOptionsNext[7 + position - (position % 8)] = 7 != position % 8;

            // TOP-RIGHT DIAGONAL
            moveOptionsNext[0 + position % 9] = (
              (0 + position % 9 < 9 * (8 - position % 9)) ~^ (position < 9 * (8 - position % 9))) && 
              position != 0 + position % 9;  
            moveOptionsNext[9 + position % 9] = 
              ((9 + position % 9 < 9 * (8 - position % 9)) ~^ (position < 9 * (8 - position % 9))) && 
              position != 9 + position % 9;
            moveOptionsNext[18 + position % 9] = 
              ((18 + position % 9 < 9 * (8 - position % 9)) ~^ (position < 9 * (8 - position % 9))) && 
              position != 18 + position % 9;
            moveOptionsNext[27 + position % 9] = 
              ((27 + position % 9 < 9 * (8 - position % 9)) ~^ (position < 9 * (8 - position % 9))) && 
              position != 27 + position % 9;
            moveOptionsNext[36 + position % 9] = 
              ((36 + position % 9 < 9 * (8 - position % 9)) ~^ (position < 9 * (8 - position % 9))) && 
              position != 36 + position % 9;
            moveOptionsNext[45 + position % 9] = 
              ((45 + position % 9 < 9 * (8 - position % 9)) ~^ (position < 9 * (8 - position % 9))) && 
              position != 45 + position % 9;
            moveOptionsNext[54 + position % 9] = 
              ((54 + position % 9 < 9 * (8 - position % 9)) ~^ (position < 9 * (8 - position % 9))) && 
              position != 54 + position % 9;
            moveOptionsNext[63] =
              position != 63 &&
              position % 9 == 0;              
            
            // TOP-LEFT DIAGONAL
            moveOptionsNext[0 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 0 + position % 7 < 7 * (position % 7 + 1)) && position != 0 + position % 7;
            moveOptionsNext[7 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 7 + position % 7 < 7 * (position % 7 + 1)) && position != 7 + position % 7;
            moveOptionsNext[14 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 14 + position % 7 < 7 * (position % 7 + 1)) && position != 14 + position % 7;
            moveOptionsNext[21 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 21 + position % 7 < 7 * (position % 7 + 1)) && position != 21 + position % 7;
            moveOptionsNext[28 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 28 + position % 7 < 7 * (position % 7 + 1)) && position != 28 + position % 7;
            moveOptionsNext[35 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 35 + position % 7 < 7 * (position % 7 + 1)) && position != 35 + position % 7;
            moveOptionsNext[42 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 42 + position % 7 < 7 * (position % 7 + 1)) && position != 42 + position % 7;
            moveOptionsNext[49 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 49 + position % 7 < 7 * (position % 7 + 1)) && position != 49 + position % 7;
            moveOptionsNext[56 + position % 7] = (position < 7 * (position % 7 + 1) ~^ 56 + position % 7 < 7 * (position % 7 + 1)) && position != 56 + position % 7;
          end
          KING: begin
            moveOptionsNext[position + 8] = position < 56; //up
            moveOptionsNext[position - 8] = position > 7; // down
            moveOptionsNext[position + 1] = position % 8 < 7; // right
            moveOptionsNext[position - 1] = position % 8 > 0; // left
            moveOptionsNext[position + 9] = position < 56 && position % 8 < 7; // top right
            moveOptionsNext[position + 7] = position < 56 && position % 8 > 0; // top left
            moveOptionsNext[position - 9] = position > 7 && position % 8 > 1; // bottom left
            moveOptionsNext[position - 7] = position > 7 && position % 8 < 7; // bottom right

            // castling
            case (color)
              WHITE: begin
                moveOptionsNext[position + 2] = position == 4;
                moveOptionsNext[position - 2] = position == 4;
              end
              BLACK: begin
                moveOptionsNext[position + 2] = position == 60;
                moveOptionsNext[position - 2] = position == 60;
              end
            endcase
          end
          default: moveOptionsNext = 0;
        endcase
      end
      S_REMOVE: begin
        case (type)
          PAWN: begin
            moveOptionsNext[position + 8] = moveOptions[position + 8] && boardData[(position+8)*4+:4] == 0;
            moveOptionsNext[position + 16] = moveOptions[position + 16] && moveOptions[position + 8] && boardData[(position+16)*4+:4] == 0;
            moveOptionsNext[position - 8] = moveOptions[position - 8] && boardData[(position-8)*4+:4] == 0;
            moveOptionsNext[position - 16] = moveOptions[position - 16] && moveOptions[position - 8] && boardData[(position-16)*4+:4] == 0;
            moveOptionsNext[position + 7] = moveOptions[position + 7] && boardData[(position+7)*4 + 3] != color && boardData[(position+7)*4+:4] != 0;
            moveOptionsNext[position + 9] = moveOptions[position + 9] && boardData[(position+9)*4 + 3] != color && boardData[(position+9)*4+:4] != 0;
            moveOptionsNext[position - 7] = moveOptions[position - 7] && boardData[(position-7)*4 + 3] != color && boardData[(position-7)*4+:4] != 0;
            moveOptionsNext[position - 9] = moveOptions[position - 9] && boardData[(position-9)*4 + 3] != color && boardData[(position-9)*4+:4] != 0;

          end
          ROOK: begin
            // VERTICAL
            if (iteration == 0) begin
              moveOptionsNext[position + 8] = moveOptions[position + 8] && (boardData[(position+8)*4 + 3] != color || boardData[(position+8)*4+:4] == 0);
              moveOptionsNext[position - 8] = moveOptions[position - 8] && (boardData[(position-8)*4 + 3] != color || boardData[(position-8)*4+:4] == 0);
            end else begin
              if (8*(iteration + 1) <= 63 - position) moveOptionsNext[position + (iteration + 1) * 8] = 
                moveOptions[position + (iteration + 1)*8] && // could already move there
                (boardData[(position + 8*(iteration + 1))*4 + 3] != color || boardData[(position + 8*(iteration + 1))*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position + iteration * 8] && // prev square could be moved to (could have opponent)
                boardData[(position + iteration * 8)*4+:4] == 0; // prev square is empty
              if (8*(iteration + 1) <= position) moveOptionsNext[position - (iteration + 1) * 8] = 
                moveOptions[position - (iteration+1)* 8] && // could already move there
                (boardData[(position - (iteration + 1)* 8)*4 + 3] != color || boardData[(position - (iteration + 1) * 8)*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position - iteration * 8] && // prev square could be moved to (could have opponent)
                boardData[(position - iteration * 8)*4+:4] == 0; // prev square is empty
            end
            // HORIZONTAL
            if (iteration == 0) begin
              moveOptionsNext[position + 1] = moveOptions[position + 1] && (boardData[(position+1)*4 + 3] != color || boardData[(position+1)*4+:4] == 0);
              moveOptionsNext[position - 1] = moveOptions[position - 1] && (boardData[(position- 1)*4 + 3] != color || boardData[(position- 1)*4+:4] == 0);
            end else begin
              if (position % 8 + iteration + 1 < 8) moveOptionsNext[position + (iteration + 1)] = 
                moveOptions[position + (iteration + 1)] && // could already move there
                (boardData[(position + iteration + 1)*4 + 3] != color || boardData[(position + iteration + 1)*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position + iteration] && // prev square could be moved to (could have opponent)
                boardData[(position + iteration)*4+:4] == 0; // prev square is empty
              if (position % 8 >= iteration + 1) moveOptionsNext[position - (iteration + 1)] = 
                moveOptions[position - (iteration+1)] && // could already move there
                (boardData[(position - (iteration + 1))*4 + 3] != color || boardData[(position - (iteration + 1))*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position - iteration] && // prev square could be moved to (could have opponent)
                boardData[(position - iteration)*4+:4] == 0; // prev square is empty
            end
          end
          KNIGHT: begin
            moveOptionsNext[position - 10] = moveOptions[position - 10] && (boardData[(position - 10)*4+:4] == 0 || boardData[(position - 10)*4 + 3] != color);
            moveOptionsNext[position - 17] = moveOptions[position - 17] && (boardData[(position - 17)*4+:4] == 0 || boardData[(position - 17)*4 + 3] != color);
            moveOptionsNext[position - 15] = moveOptions[position - 15] && (boardData[(position - 15)*4+:4] == 0 || boardData[(position - 15)*4 + 3] != color);
            moveOptionsNext[position - 6] = moveOptions[position - 6] && (boardData[(position - 6)*4+:4] == 0 || boardData[(position - 6)*4 + 3] != color);
            moveOptionsNext[position + 10] = moveOptions[position + 10] && (boardData[(position + 10)*4+:4] == 0 || boardData[(position + 10)*4 + 3] != color);
            moveOptionsNext[position + 17] = moveOptions[position + 17] && (boardData[(position + 17)*4+:4] == 0 || boardData[(position + 17)*4 + 3] != color);
            moveOptionsNext[position + 15] = moveOptions[position + 15] && (boardData[(position + 15)*4+:4] == 0 || boardData[(position + 15)*4 + 3] != color);
            moveOptionsNext[position + 6] = moveOptions[position + 6] && (boardData[(position + 6)*4+:4] == 0 || boardData[(position + 6)*4 + 3] != color);
          end

          BISHOP: begin
            // TOP RIGHT
            if (iteration == 0) begin
              moveOptionsNext[position + 9] = moveOptions[position + 9] && (boardData[(position+9)*4 + 3] != color || boardData[(position+9)*4+:4] == 0);
              moveOptionsNext[position - 9] = moveOptions[position - 9] && (boardData[(position-9)*4 + 3] != color || boardData[(position-9)*4+:4] == 0);
            end else begin
              if (9*(iteration + 1) <= 63 - position) moveOptionsNext[position + (iteration + 1)*9] = 
                moveOptions[position + (iteration + 1)*9] && // could already move there
                (boardData[(position + 9*(iteration + 1))*4 + 3] != color || boardData[(position + 9*(iteration + 1))*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position + iteration*9] && // prev square could be moved to (could have opponent)
                boardData[(position + iteration*9)*4+:4] == 0; // prev square is empty
              if (9*(iteration + 1) <= position) moveOptionsNext[position - (iteration + 1)*9] = 
                moveOptions[position - (iteration+1)*9] && // could already move there
                (boardData[(position - (iteration + 1)*9)*4 + 3] != color || boardData[(position - (iteration + 1)*9)*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position - iteration*9] && // prev square could be moved to (could have opponent)
                boardData[(position - iteration*9)*4+:4] == 0; // prev square is empty
            end

            // TOP LEFT
            if (iteration == 0) begin
              moveOptionsNext[position + 7] = moveOptions[position + 7] && (boardData[(position+7)*4 + 3] != color || boardData[(position+7)*4+:4] == 0);
              moveOptionsNext[position - 7] = moveOptions[position - 7] && (boardData[(position-7)*4 + 3] != color || boardData[(position-7)*4+:4] == 0);
            end else begin
              if (7*(iteration + 1) <= 63 - position) moveOptionsNext[position + (iteration + 1)*7] = 
                moveOptions[position + (iteration + 1)*7] && // could already move there
                (boardData[(position + 7*(iteration + 1))*4 + 3] != color || boardData[(position + 7*(iteration + 1))*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position + iteration*7] && // prev square could be moved to (could have opponent)
                boardData[(position + iteration*7)*4+:4] == 0; // prev square is empty
              if (7*(iteration + 1) <= position) moveOptionsNext[position - (iteration + 1)*7] = 
                moveOptions[position - (iteration+1)*7] && // could already move there
                (boardData[(position - (iteration + 1)*7)*4 + 3] != color || boardData[(position - (iteration + 1)*7)*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position - iteration*7] && // prev square could be moved to (could have opponent)
                boardData[(position - iteration*7)*4+:4] == 0; // prev square is empty
            end
          end
          QUEEN: begin
            // VERTICAL
            if (iteration == 0) begin
              moveOptionsNext[position + 8] = moveOptions[position + 8] && (boardData[(position+8)*4 + 3] != color || boardData[(position+8)*4+:4] == 0);
              moveOptionsNext[position - 8] = moveOptions[position - 8] && (boardData[(position-8)*4 + 3] != color || boardData[(position-8)*4+:4] == 0);
            end else begin
              if (8*(iteration + 1) <= 63 - position) moveOptionsNext[position + (iteration + 1) * 8] = 
                moveOptions[position + (iteration + 1) * 8] && // could already move there
                (boardData[(position + 8*(iteration + 1))*4 + 3] != color || boardData[(position + 8*(iteration + 1))*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position + iteration * 8] && // prev square could be moved to (could have opponent)
                boardData[(position + iteration * 8)*4+:4] == 0; // prev square is empty
              if (8*(iteration + 1) <= position) moveOptionsNext[position - (iteration + 1)*8] = 
                moveOptions[position - (iteration+1) * 8] && // could already move there
                (boardData[(position - (iteration + 1) * 8)*4 + 3] != color || boardData[(position - (iteration + 1)*8)*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position - iteration * 8] && // prev square could be moved to (could have opponent)
                boardData[(position - iteration * 8)*4+:4] == 0; // prev square is empty
            end
            // HORIZONTAL
            if (iteration == 0) begin
              moveOptionsNext[position + 1] = moveOptions[position + 1] && (boardData[(position+1)*4 + 3] != color || boardData[(position+1)*4+:4] == 0);
              moveOptionsNext[position - 1] = moveOptions[position - 1] && (boardData[(position- 1)*4 + 3] != color || boardData[(position- 1)*4+:4] == 0);
            end else begin
              if (position % 8 + iteration + 1 < 8) moveOptionsNext[position + (iteration + 1)] = 
                moveOptions[position + (iteration + 1)] && // could already move there
                (boardData[(position + iteration + 1)*4 + 3] != color || boardData[(position + iteration + 1)*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position + iteration] && // prev square could be moved to (could have opponent)
                boardData[(position + iteration)*4+:4] == 0; // prev square is empty
              if (position % 8 >= iteration + 1) moveOptionsNext[position - (iteration + 1)] = 
                moveOptions[position - (iteration+1)] && // could already move there
                (boardData[(position - (iteration + 1))*4 + 3] != color || boardData[(position - (iteration + 1))*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position - iteration] && // prev square could be moved to (could have opponent)
                boardData[(position - iteration)*4+:4] == 0; // prev square is empty
            end
            
            // TOP RIGHT
            if (iteration == 0) begin
              moveOptionsNext[position + 9] = moveOptions[position + 9] && (boardData[(position+9)*4 + 3] != color || boardData[(position+9)*4+:4] == 0);
              moveOptionsNext[position - 9] = moveOptions[position - 9] && (boardData[(position-9)*4 + 3] != color || boardData[(position-9)*4+:4] == 0);
            end else begin
              if (9*(iteration + 1) <= 63 - position) moveOptionsNext[position + (iteration + 1)*9] = 
                moveOptions[position + (iteration + 1)*9] && // could already move there
                (boardData[(position + 9*(iteration + 1))*4 + 3] != color || boardData[(position + 9*(iteration + 1))*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position + iteration*9] && // prev square could be moved to (could have opponent)
                boardData[(position + iteration*9)*4+:4] == 0; // prev square is empty
              if (9*(iteration + 1) <= position) moveOptionsNext[position - (iteration + 1)*9] = 
                moveOptions[position - (iteration+1)*9] && // could already move there
                (boardData[(position - (iteration + 1)*9)*4 + 3] != color || boardData[(position - (iteration + 1)*9)*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position - iteration*9] && // prev square could be moved to (could have opponent)
                boardData[(position - iteration*9)*4+:4] == 0; // prev square is empty
            end

            // TOP LEFT
            if (iteration == 0) begin
              moveOptionsNext[position + 7] = moveOptions[position + 7] && (boardData[(position+7)*4 + 3] != color || boardData[(position+7)*4+:4] == 0);
              moveOptionsNext[position - 7] = moveOptions[position - 7] && (boardData[(position-7)*4 + 3] != color || boardData[(position-7)*4+:4] == 0);
            end else begin
              if (7*(iteration + 1) <= 63 - position) moveOptionsNext[position + (iteration + 1)*7] = 
                moveOptions[position + (iteration + 1)*7] && // could already move there
                (boardData[(position + 7*(iteration + 1))*4 + 3] != color || boardData[(position + 7*(iteration + 1))*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position + iteration*7] && // prev square could be moved to (could have opponent)
                boardData[(position + iteration*7)*4+:4] == 0; // prev square is empty
              if (7*(iteration + 1) <= position) moveOptionsNext[position - (iteration + 1)*7] = 
                moveOptions[position - (iteration+1)*7] && // could already move there
                (boardData[(position - (iteration + 1)*7)*4 + 3] != color || boardData[(position - (iteration + 1)*7)*4+:4] == 0) &&  // is empty or has opponent
                moveOptions[position - iteration*7] && // prev square could be moved to (could have opponent)
                boardData[(position - iteration*7)*4+:4] == 0; // prev square is empty
            end
          end
          KING:begin
            moveOptionsNext[position + 8] = moveOptions[position + 8] && (boardData[(position + 8)*4+:4] == 0 || boardData[(position + 8)*4 + 3] != color);
            moveOptionsNext[position - 8] = moveOptions[position - 8] && (boardData[(position - 8)*4+:4] == 0 || boardData[(position - 8)*4 + 3] != color);
            moveOptionsNext[position + 1] = moveOptions[position + 1] && (boardData[(position + 1)*4+:4] == 0 || boardData[(position + 1)*4 + 3] != color);
            moveOptionsNext[position - 1] = moveOptions[position - 1] && (boardData[(position - 1)*4+:4] == 0 || boardData[(position - 1)*4 + 3] != color);
            moveOptionsNext[position + 9] = moveOptions[position + 9] && (boardData[(position + 9)*4+:4] == 0 || boardData[(position + 9)*4 + 3] != color);
            moveOptionsNext[position + 7] = moveOptions[position + 7] && (boardData[(position + 7)*4+:4] == 0 || boardData[(position + 7)*4 + 3] != color);
            moveOptionsNext[position - 9] = moveOptions[position - 9] && (boardData[(position - 9)*4+:4] == 0 || boardData[(position - 9)*4 + 3] != color);
            moveOptionsNext[position - 7] = moveOptions[position - 7] && (boardData[(position - 7)*4+:4] == 0 || boardData[(position - 7)*4 + 3] != color);

            // castling
            moveOptionsNext[position + 2] = moveOptions[position + 2] && 
              boardData[(position + 1)*4+:8] == 0 && 
              boardData[(position + 3)*4+:4] == {color, ROOK};
              
            moveOptionsNext[position - 2] = moveOptions[position - 2] && 
              boardData[(position - 3)*4+:12] == 0 && 
              boardData[(position - 4)*4+:4] == {color, ROOK};  
          end
          default: moveOptionsNext = 0;
        endcase
      end
      S_CHECK_CHECK: begin
        check = 0;
        if (moveOptionsNext[blackKingPos]) check[0] = 1;
        else if (moveOptionsNext[whiteKingPos]) check[1] = 1;
      end
    endcase
  end

endmodule

  /*
    1, 3, 4
    {color, TYPE, INDEX}
    position/ID key 6 bits:
      56 57 58 59 60 61 62 63
      48 49 50 51 52 53 54 55
      40 41 42 43 44 45 46 47 
      32 33 34 35 36 37 38 39
      24 25 26 27 28 29 30 31
      16 17 18 19 20 21 22 23
      08 09 10 11 12 13 14 15 
      00 01 02 03 04 05 06 07 
  */