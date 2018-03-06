/**
 * Implementierung eines Schachzuges, welcher mit dem SChFiM-Protokoll arbeiten kann.
 */
class ChessMovement {
  
  protected final static String REMOVE_SYNTAX = "/r %d %d \n";
  protected final static String MOVE_SYNTAX = "/m %d %d %d %d \n";
  
  protected byte fromX;
  protected byte fromY;
  protected byte toX;
  protected byte toY;
  protected boolean castling;
  protected boolean removes;
  protected ChessFigureType toType;
  protected int score = Integer.MIN_VALUE + 1;
  
  /**
   * Erstellt eine Instanz von ChessMovement.
   * 
   * @param fromX die x-Position der Figur auf dem Brett (0 - 7)
   * @param fromY die y-Position der Figur auf dem Brett (0 - 7)
   * @param toX die neue x-Position auf dem Brett (0 - 7)
   * @param toY die neue y-Position auf dem Brett (0 - 7)
   * @param castling ob der Zug eine Rochade darstellt, d.h. ob die Figur auf dem Zielfeld auch bewegt werden soll
   * @param removes ob der Schachzug eine Figur entfernt
   * @param toType Typ der Figur, falls sich dieser verändert (Dame, König, Bauer, etc.)
   */
  public ChessMovement(byte fromX, byte fromY, byte toX, byte toY, boolean castling, boolean removes, ChessFigureType toType) {
    this.fromX = fromX;
    this.fromY = fromY;
    this.toX = toX;
    this.toY = toY;
    this.castling = castling;
    this.removes = removes;
    this.toType = toType;
  }
  
  /**
   * Erstellt eine Instanz von ChessMovement.
   * 
   * @param fromX die x-Position der Figur auf dem Brett (0 - 7)
   * @param fromY die y-Position der Figur auf dem Brett (0 - 7)
   * @param toX die neue x-Position auf dem Brett (0 - 7)
   * @param toY die neue y-Position auf dem Brett (0 - 7)
   * @param castling ob der Zug eine Rochade darstellt, d.h. ob die Figur auf dem Zielfeld auch bewegt werden soll
   * @param removes ob der Schachzug eine Figur entfernt
   */
  public ChessMovement(byte fromX, byte fromY, byte toX, byte toY, boolean castling, boolean removes) {
    this(fromX, fromY, toX, toY, castling, removes, null);
  }
  
  /**
   * Erstellt eine Instanz von ChessMovement aus einer anderen Instanz. 
   * Es wird also eine (tiefe) Kopie der anderen Instanz erstellt.
   * 
   * @param movement die andere Instanz, welche kopiert wird
   */
  public ChessMovement(ChessMovement movement) {
    this.fromX = movement.fromX;
    this.fromY = movement.fromY;
    this.toX = movement.toX;
    this.toY = movement.toY;
    this.castling = movement.castling;
    this.removes = movement.removes;
    this.toType = movement.toType;
  }
  
  /**
   * Führt den Bewegungsablauf auf einem Schachbrett aus.
   * 
   * @param board Schachbrett, auf dem der Bewegungsablauf ausgeführt wird
   */
  public void apply(Checkerboard board) {
    if (this.removes)
      board.figures.remove(board.getFigureOn(this.toX, this.toY));
    if (this.castling) {
      if (board.getFigureOn(this.fromX, this.fromY).chessColor == ChessFigureColor.WHITE)
        board.whiteUsedCastling = true;
      else
        board.blackUsedCastling = true;
      // (n >> 7) | 1 gibt für ein byte n dessen Vorzeichen an
      board.getFigureOn(this.fromX, this.fromY).setPosition((byte) ((((this.toX - this.fromX) >> 7) | 1) * 2 + this.fromX), this.toY);
      board.getFigureOn(this.toX, this.toY).setPosition((byte) ((((this.toX - this.fromX) >> 7) | 1) + this.fromX), this.fromY);
    } else
      board.getFigureOn(this.fromX, this.fromY).setPosition(this.toX, this.toY);
    if (this.toType != null)
      board.getFigureOn(this.toX, this.toY).type = this.toType;
    board.boardScore = null;
  }
  
  /**
   * Gibt den Schachzug als SChFiM-Befehl zurück.
   * 
   * @return ein String, welcher den Befehl (bzw. meherere Befehle) enthält
   */
  public String toSChFiMCommandSequence() {
    String command = "";
    if (this.removes)
      command += String.format(REMOVE_SYNTAX, this.toX, this.toY);
    if (this.castling) {
      // (n >> 7) | 1 gibt für ein byte n dessen Vorzeichen an
      command += String.format(MOVE_SYNTAX, this.fromX, this.fromY, (((this.toX - this.fromX) >> 7) | 1) * 2 + this.fromX, this.toY);
      command += String.format(MOVE_SYNTAX, this.toX, this.toY, (((this.toX - this.fromX) >> 7) | 1) + this.fromX, this.fromY);
    } else
      command += String.format(MOVE_SYNTAX, this.fromX, this.fromY, this.toX, this.toY);
    return command;
  }
  
}