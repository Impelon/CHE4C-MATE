/**
 * Klasse, für die Mitteilung, dass eine Figur, welche benötigt wird, nicht vorhanden ist.
 */
class FigureNotFoundException extends Exception {
  
  protected final ChessFigureType type;
  protected final ChessFigureColor chessColor;
	
  /**
   * Erstellt eine Instanz von FigureNotFoundException.
   * 
   * @param type Typ der Figur (Dame, König, Bauer, etc.)
   * @param chessColor Spielerfarbe der Figur (Schwarz / Weiß)
   */
	public FigureNotFoundException(ChessFigureType type, ChessFigureColor chessColor) {
    super();
    
    this.type = type;
    this.chessColor = chessColor;
  }
  
  /**
   * Erstellt eine Instanz von FigureNotFoundException.
   * 
   * @param message Fehlermeldung
   * @param type Typ der Figur (Dame, König, Bauer, etc.)
   * @param chessColor Spielerfarbe der Figur (Schwarz / Weiß)
   */
  public FigureNotFoundException(String message, ChessFigureType type, ChessFigureColor chessColor) {
    super(message);
    
    this.type = type;
    this.chessColor = chessColor;
  }
  
  /**
   * Gibt den Typ der benötigten Figur zurück.
   * 
   * @return Typ der benötigten Figur (Dame, König, Bauer, etc.)
   */
  public ChessFigureType getType() {
    return this.type;
  }
  
  /**
   * Gibt die Spielerfarbe der benötigten Figur zurück.
   * 
   * @return Spielerfarbe der Figur (Schwarz / Weiß)
   */
  public ChessFigureColor getChessColor() {
    return this.chessColor;
  }
	
}