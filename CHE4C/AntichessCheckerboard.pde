import java.util.Map.Entry;

{
  checkerboardClasses.add(AntichessCheckerboard.class);
}

/**
 * Implementierung eines Schachbretts für den Schachmodus "Räuberschach".
 */
class AntichessCheckerboard extends Checkerboard {
  
  /**
   * Erstellt eine Instanz von AntichessCheckerboard.
   */
  public AntichessCheckerboard() {
    super();
  }
  
  /**
   * Erstellt eine Instanz von AntichessCheckerboard.
   * 
   * @param initial Wenn true, wird die Startaufstellung auf das Schachbrett gelegt. Sonst ist das Schachbrett leer.
   */
  public AntichessCheckerboard(boolean initial) {
    super(initial);
  }
    
  /**
   * Erstellt eine Instanz von AntichessCheckerboard aus einer anderen Instanz. 
   * Es wird also eine (tiefe) Kopie der anderen Instanz erstellt.
   * 
   * @param board die andere Instanz, welche kopiert wird
   */
  public AntichessCheckerboard(Checkerboard board) {
    super(board);
  }
  
  @Override
  public int getScore(ChessFigureColor chessColor) {
    return -super.getScore(chessColor);
  }
  
  @Override
  public int getFigureScore(ChessFigure figure) {
    return figure.type == ChessFigureType.KING ? (int) (ChessFigureType.PAWN.getRelativeValue() * 2.5) : super.getFigureScore(figure);
  }
  
  @Override
  public boolean hasLost(ChessFigureColor chessColor) {
    return this.hasWon(chessColor.getOpposing());
  }
  
  @Override
  public boolean hasWon(ChessFigureColor chessColor) {
    if (this.getSuccessionalBoards(chessColor).isEmpty())
      return true;
    for (ChessFigure figure : this.figures)
      if (figure.chessColor == chessColor)
        return false;
    return true;
  }
  
  @Override
  public HashMap<Checkerboard, ChessMovement> getSuccessionalBoards() {
    return this.filterBoards(super.getSuccessionalBoards());
  }
  
  @Override
  public HashMap<Checkerboard, ChessMovement> getSuccessionalBoards(ChessFigureColor chessColor) {
    return this.filterBoards(super.getSuccessionalBoards(chessColor));
  }
  
  @Override
  public HashMap<Checkerboard, ChessMovement> getSuccessionalBoards(ChessFigure figure) {
    return this.filterBoards(super.getSuccessionalBoards(figure));
  }
  
  @Override
  protected HashMap<Checkerboard, ChessMovement> getSuccessionalBoardsWithPawn(ChessFigure figure) {
    HashMap<Checkerboard, ChessMovement> boards = super.getSuccessionalBoardsWithPawn(figure);
    HashMap<Checkerboard, ChessMovement> kings = new HashMap<Checkerboard, ChessMovement>();
    
    for (Entry<Checkerboard, ChessMovement> entry : boards.entrySet()) {
      if (entry.getValue().toType != null && entry.getValue().toType != ChessFigureType.PAWN) {
        Checkerboard board = new Checkerboard(this);
        ChessMovement movement = new ChessMovement(entry.getValue());
        movement.toType = ChessFigureType.KING;
        movement.apply(board);
        kings.put(board, movement);
      }
    }
    
    boards.putAll(kings);
    return boards;
  }
  
  /**
   * Entfernt alle invaliden Züge, die aufgrund von Sonderregeln wegfallen, aus einer Zuordnung möglicher Züge.
   * 
   * @param boards die Zuordnung möglicher Züge
   * @return die Zuordnung möglicher Züge nach dem Entfernen invalider Züge
   */
  protected HashMap<Checkerboard, ChessMovement> filterBoards(HashMap<Checkerboard, ChessMovement> boards) {
    HashMap<Checkerboard, ChessMovement> filtered = new HashMap<Checkerboard, ChessMovement>();
    int minFigures = this.figures.size();
    
    for (Entry<Checkerboard, ChessMovement> entry : boards.entrySet()) {
      if (entry.getKey().figures.size() < minFigures) {
        minFigures = entry.getKey().figures.size();
        filtered.clear();
      }
      if (entry.getKey().figures.size() == minFigures)
        filtered.put(new AntichessCheckerboard(entry.getKey()), entry.getValue());
    }
        
    return filtered;
  }
  
}