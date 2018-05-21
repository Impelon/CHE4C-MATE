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
    if (this.hasWon(chessColor) || this.hasLost(chessColor))
      return super.getScore(chessColor);
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
  public HashSet<Checkerboard> getSuccessionalBoards() {
    return this.filterBoards(super.getSuccessionalBoards());
  }
  
  @Override
  public HashSet<Checkerboard> getSuccessionalBoards(ChessFigureColor chessColor) {
    return this.filterBoards(super.getSuccessionalBoards(chessColor));
  }
  
  @Override
  public HashSet<Checkerboard> getSuccessionalBoards(ChessFigure figure) {
    return this.filterBoards(super.getSuccessionalBoards(figure));
  }
  
  @Override
  protected boolean isValidPawnTransformationGoal(ChessFigureType type) {
	  return type != ChessFigureType.PAWN;
  }
  
  /**
   * Entfernt alle invaliden Züge, die aufgrund von Sonderregeln wegfallen, aus einer Menge möglicher Züge.
   * 
   * @param boards die Menge möglicher Züge
   * @return die Menge möglicher Züge nach dem Entfernen invalider Züge
   */
  protected HashSet<Checkerboard> filterBoards(HashSet<Checkerboard> boards) {
    HashSet<Checkerboard> filtered = new HashSet<Checkerboard>();
    int minFigures = this.figures.size();
    
    for (Checkerboard board : boards) {
      if (board.figures.size() < minFigures) {
        minFigures = board.figures.size();
        filtered.clear();
      }
      if (board.figures.size() == minFigures)
        filtered.add(new AntichessCheckerboard(board));
    }
        
    return filtered;
  }
  
}