/**
 * Aufzählung für die Schachfigur-Art.
 */
enum ChessFigureType {
  KING(10000),
  QUEEN(900),
  ROOK(500),
  BISHOP(300),
  KNIGHT(300),
  PAWN(100);
  
  protected int relativeValue;
  
  ChessFigureType(int relativeValue) {
    this.relativeValue = relativeValue;
  }
  
  /**
   * Gibt den relativen Figurenwert zurück.
   * 
   * @return der Figurenwert (in [vielfachen] Bauerneinheiten)
   */
  int getRelativeValue() {
    return this.relativeValue;
  }
  
}