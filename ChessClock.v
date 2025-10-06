
module ChessClock (
  input clk, reset,
  input move, turn,
  input [1:0] checkmate,
  output reg [6:0] ssd,
  output reg [7:0] anode_enable,
  output reg [1:0] timeout
);


  parameter [9:0] START_TIME = 180;
  parameter [26:0] CLOCK_SPEED = 100000000; 
  parameter [26:0] BLINK_SPEED = 50000;
  parameter [26:0] REFRESH_RATE = CLOCK_SPEED / 1000; 


  reg [9:0] whiteTime, blackTime;
  reg [26:0] counter;
  reg [21:0] refreshCounter;
  reg [2:0] currentDigit;

  reg [2:0] state, stateNext;
  parameter [2:0] S_INITIAL = 0, S_IDLE = 1, S_RUNNING = 2, S_DECREMENT = 3, S_DONE = 4;

  initial begin
    refreshCounter = 0;
    currentDigit = 0;
  end

  // FUNCTION FOR GETTING SSD DISPLAY VALUE (input 4 bit number and output 7 bit ssd)  
  function automatic [6:0] ssdValue;
    input [3:0] value;
    
    case(value)
      4'h0: ssdValue = 7'b0000001; // Display 0
      4'h1: ssdValue = 7'b1001111; // Display 1
      4'h2: ssdValue = 7'b0010010; // Display 2
      4'h3: ssdValue = 7'b0000110; // Display 3
      4'h4: ssdValue = 7'b1001100; // Display 4
      4'h5: ssdValue = 7'b0100100; // Display 5
      4'h6: ssdValue = 7'b0100000; // Display 6
      4'h7: ssdValue = 7'b0001111; // Display 7
      4'h8: ssdValue = 7'b0000000; // Display 8
      4'h9: ssdValue = 7'b0000100; // Display 9
      4'hA: ssdValue = 7'b0001000; // Display A
      4'hB: ssdValue = 7'b1100000; // Display B
      4'hC: ssdValue = 7'b0110001; // Display C
      4'hD: ssdValue = 7'b1000010; // Display D
      4'hE: ssdValue = 7'b0110000; // Display E
      4'hF: ssdValue = 7'b0111000; // Display F
      default: ssdValue = 7'b1111111; // All segments off
    endcase

  endfunction

  // state transitions
  always @(negedge clk) begin
    case (state)
      S_INITIAL: if (whiteTime > 0 && blackTime > 0) stateNext = S_IDLE;
      S_IDLE: if (move) stateNext = S_RUNNING;
      S_RUNNING: begin
        if (whiteTime == 0 || blackTime == 0 || checkmate > 0) stateNext = S_DONE;
        else if (counter > CLOCK_SPEED) stateNext = S_DECREMENT;
      end
      S_DECREMENT: stateNext = S_RUNNING;
    endcase
  end

  // state -> stateNext and output
  always @(posedge clk) begin
    if (reset) state = S_INITIAL;
    else state = stateNext;

    case (state)
      S_INITIAL: begin
        whiteTime = START_TIME;
        blackTime = START_TIME;
        counter = 0;
        timeout = 0;
      end
      S_RUNNING: begin
        counter = counter + 1;
      end
      S_DECREMENT: begin
        counter = 0;
        if (turn) blackTime = blackTime - 1;
        else whiteTime = whiteTime - 1;

        if (whiteTime == 0) timeout[0] = 1;
        else if (blackTime == 0) timeout[1] = 1;
      end
      S_DONE: begin
      end
    endcase

    // REFRESH
    if (refreshCounter > REFRESH_RATE) begin
      refreshCounter = 0;
      case (currentDigit)
        0: anode_enable = 8'b11111110;
        1: anode_enable = 8'b11111101;
        2: anode_enable = 8'b11111011;
        3: anode_enable = 8'b11110111;
        4: anode_enable = 8'b11101111;
        5: anode_enable = 8'b11011111;
        6: anode_enable = 8'b10111111;
        7: anode_enable = 8'b01111111;
      endcase
      case (currentDigit)
        0: ssd = ssdValue(blackTime % 10);
        1: ssd = blackTime >= 10 ? ssdValue((blackTime % 60) / 10) : 7'b1111111;
        2: ssd = blackTime >= 60 ? ssdValue((blackTime / 60) % 10) : 7'b1111111;
        3: ssd = blackTime == 600 ? ssdValue(1) : 7'b1111111;
        4: ssd = ssdValue(whiteTime % 10);
        5: ssd = whiteTime >= 10 ? ssdValue((whiteTime % 60) / 10) : 7'b1111111;
        6: ssd = whiteTime >= 60 ? ssdValue((whiteTime / 60) % 10) : 7'b1111111;
        7: ssd = whiteTime == 600 ? ssdValue(1) : 7'b1111111;
      endcase
      currentDigit = currentDigit + 1;
    end

    refreshCounter = refreshCounter + 1;
  end



endmodule
