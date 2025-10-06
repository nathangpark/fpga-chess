module ChessController (
  input clk, reset, BTNC,
  input [5:0] cursorPosition,
  input [1:0] timeout,
  output wire [255:0] boardData,
  output wire [63:0] moveOptions,
  output wire [5:0] selectedPosition,
  output wire [1:0] checkmate,
  output wire loading, turn, moveSound
  
);

  localparam WHITE = 0, BLACK = 1;
  localparam [2:0] PAWN = 1, ROOK = 2, BISHOP = 3, KNIGHT = 4, QUEEN = 5, KING = 6;

  
  // EXTRA LOGIC
  wire pieceSelected; // is a piece selected
  wire checkingAll; // is CheckAllController currently checking 
  wire simulate;
  wire [1:0] check, checkPiece;
  wire [5:0] blackKingPos, whiteKingPos;
  wire [63:0] moveOptions_unmodified;


  // UPDATE WIRES
  // update chessPiece
  wire updatePiece; 
  wire updatePiece_instructionHandler, updatePiece_checkAllController, updatePiece_checkmateController;
  assign updatePiece = updatePiece_checkAllController || updatePiece_checkmateController || updatePiece_instructionHandler;

  // update checkAllController, modifyOptionsHandler, checkmateController
  wire updateAll;
  
  wire updateModify;
  wire updateModify_instructionHander, updateModify_checkmateController;
  assign updateModify =  updateModify_checkmateController || updateModify_instructionHander;
  
  wire updateCheckmate;
  
  // MOVE WIRES
  wire move;
  wire move_instructionHandler, move_modifyOptionsHandler;
  assign move = move_instructionHandler || move_modifyOptionsHandler;
  
  assign moveSound = move_instructionHandler;
  
  // INSTRUCTION WIRES
  wire [11:0] instruction;
  wire [11:0] instruction_instructionHandler, instruction_modifyOptionsHandler;
  assign instruction = simulate ? instruction_modifyOptionsHandler : instruction_instructionHandler;
  

  // LOADING AND READY WIRES
  wire boardReady, pieceReady, instructionReady, modifyReady, allReady, checkmateReady; 
  assign loading = !boardReady || !pieceReady || !instructionReady || !modifyReady || !allReady || !checkmateReady;

  // PROMOTE WIRES
  wire promote;
  wire [2:0] promoteRow, promotePiece;


  // SELECTED POSITION WIRES
  wire [5:0] selectedPosition_modifyOptions, selectedPosition_instructionHandler, selectedPosition_checkAllController, selectedPosition_checkmateController; 

  // modify options can be controlled by instruction handler or checkmate controller
  assign selectedPosition_modifyOptions = !checkmateReady ? selectedPosition_checkmateController : selectedPosition_instructionHandler;
  assign selectedPosition = checkingAll ? selectedPosition_checkAllController : 
    simulate ? selectedPosition_modifyOptions : 
    !checkmateReady ? selectedPosition_checkmateController: 
    selectedPosition_instructionHandler;


  // CHESS BOARD INSTANTIATION

  ChessBoard chessBoard (
    .clk(clk), 
    .reset(reset),
    .move(move),
    .turn(turn),
    .instruction(instruction),
    .boardData(boardData), 
    .simulate(simulate),
    .promote(promote),
    .promoteRow(promoteRow),
    .promotePiece(promotePiece),
    .ready(boardReady),
    .blackKingPos(blackKingPos),
    .whiteKingPos(whiteKingPos)
  );

  // CHESS PIECE MODULES INSTANTIATION

  ChessPiece chessPiece (
    .clk(clk),
    .reset(reset),
    .position(selectedPosition),
    .update(updatePiece),
    .selected(pieceSelected),
    .boardData(boardData),
    .moveOptions(moveOptions_unmodified),
    .ready(pieceReady),
    .check(checkPiece),
    .blackKingPos(blackKingPos),
    .whiteKingPos(whiteKingPos)
  );


  // INSTRUCTION HANDLER
  InstructionHandler instructionHandler (
    .clk(clk),
    .reset(reset),
    .center(BTNC),
    .pieceSelected(pieceSelected),
    .pieceReady(pieceReady),
    .modifyReady(modifyReady),
    .boardReady(boardReady),
    .checkmateReady(checkmateReady),
    .checkmate(checkmate),
    .cursorPosition(cursorPosition),
    .boardData(boardData),
    .moveOptions(moveOptions),
    .check(checkPiece),
    .updatePiece(updatePiece_instructionHandler),
    .ready(instructionReady),
    .selectedPosition(selectedPosition_instructionHandler),
    .instruction(instruction_instructionHandler),
    .turn(turn),
    .updateModify(updateModify_instructionHander),
    .updateCheckmate(updateCheckmate),
    .promote(promote),
    .promoteRow(promoteRow),
    .promotePiece(promotePiece),
    .move(move_instructionHandler),
    .timeout(timeout)
  );
  

  ModifyOptionsHandler modifyOptionsHandler (
    .clk(clk), 
    .reset(reset),
    .update(updateModify), 
    .pieceReady(pieceReady), 
    .boardReady(boardReady),
    .allReady(allReady), 
    .checkmateReady(checkmateReady),
    .turn(turn), 
    .selected(pieceSelected),
    .check(check),
    .selectedPosition(selectedPosition_modifyOptions),
    .moveOptions(moveOptions_unmodified),
    .instruction(instruction_modifyOptionsHandler),
    .modifiedMoveOptions(moveOptions),
    .simulate(simulate), 
    .ready(modifyReady), 
    .updateAll(updateAll),
    .move(move_modifyOptionsHandler)
  );

  CheckAllController checkAllController (
    .clk(clk),
    .pieceReady(pieceReady), 
    .updateAll(updateAll),
    .check(checkPiece),
    .boardData(boardData),
    .position(selectedPosition_checkAllController), 
    .checkOut(check),
    .ready(allReady), 
    .checkingAll(checkingAll), 
    .updatePiece(updatePiece_checkAllController)
  );
  

  // CHECKMATE CONTROLLER

  CheckmateController checkmateController (
    .clk(clk),
    .reset(reset),
    .update(updateCheckmate), 
    .turn(turn),
    .modifyReady(modifyReady),
    .moveOptions(moveOptions),
    .boardData(boardData),
    .selectedPosition(selectedPosition_checkmateController),
    .updateModify(updateModify_checkmateController), 
    .updatePiece(updatePiece_checkmateController),
    .checkmate(checkmate), 
    .ready(checkmateReady)
  );
  


endmodule