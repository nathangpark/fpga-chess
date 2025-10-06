all: compile wave

compile:
	iverilog -o chess.vvp testbenches/ChessController_tb.v ChessController.v ChessBoard.v ChessPiece.v InstructionHandler.v ModifyOptionsHandler.v CheckAllController.v CheckmateController.v ChessClock.v
	vvp chess.vvp > run.log

test:
	iverilog -o chess.vvp NoLoop/ChessController_tb.v NoLoop/ChessController.v NoLoop/ChessBoard.v NoLoop/ChessPiece.v NoLoop/InstructionHandler.v
	vvp chess.vvp > run.log

sound:
	iverilog -o chess.vvp testbenches/moveSoundEffect_tb.v moveSoundEffect.v
	vvp chess.vvp > run.log

wave:
	gtkwave dump.vcd

clean:
	rm rgb.vvp dump.vcd