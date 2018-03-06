/**
 * Implementierung einer Schachfigur.
 */
class ChessFigure {
  
  public ChessFigureType type;
  public ChessFigureColor chessColor;
  
  protected byte positionX;
  protected byte positionY;
  
  protected boolean moved = false;
  
  /**
   * Erstellt eine Instanz von ChessFigure.
   * 
   * @param type Typ der Figur (Dame, König, Bauer, etc.)
   * @param chessColor Spielerfarbe der Figur (Schwarz / Weiß)
   * @param positionX die x-Position der Figur auf dem Brett (0 - 7)
   * @param positionY die y-Position der Figur auf dem Brett (0 - 7)
   */
  public ChessFigure(ChessFigureType type, ChessFigureColor chessColor, byte positionX, byte positionY) {
    this.type = type;
    this.chessColor = chessColor;
    this.positionX = positionX;
    this.positionY = positionY;
  }
  
  /**
   * Erstellt eine Instanz von ChessFigure aus einer anderen Instanz. 
   * Es wird also eine (tiefe) Kopie der anderen Instanz erstellt.
   * 
   * @param figure die andere Instanz, welche kopiert wird
   */
  public ChessFigure(ChessFigure figure) {
    this.type = figure.type;
    this.chessColor = figure.chessColor;
    this.positionX = figure.positionX;
    this.positionY = figure.positionY;
    this.moved = figure.moved;
  }
  
  /**
   * Gibt den Namen der Figur zurück. (SPIELERFARBE_TYP)
   * 
   * @return der Figurenname
   */
  public String getFigureName() {
    return this.chessColor.toString() + "_" + this.type.toString();
  }
  
  /**
   * Gibt die x-Position der Figur zurück.
   * 
   * @return die x-Position
   */
  public byte getPositionX() {
    return this.positionX;
  }
  
  /**
   * Gibt die y-Position der Figur zurück.
   * 
   * @return die y-Position
   */
  public byte getPositionY() {
    return this.positionY;
  }
  
  /**
   * Setzt die x-Position der Figur, sodass die Figur bewegt wird.
   * 
   * @param x die x-Position
   */
  public void setPositionX(byte x) {
    this.positionX = x;
    this.moved = true;
  }
  
  /**
   * Setzt die y-Position der Figur, sodass die Figur bewegt wird.
   * 
   * @param y die y-Position
   */
  public void setPositionY(byte y) {
    this.positionY = y;
    this.moved = true;
  }
  
  /**
   * Setzt die Position der Figur, sodass die Figur bewegt wird.
   * 
   * @param x die x-Position
   * @param y die y-Position
   */
  public void setPosition(byte x, byte y) {
    this.setPositionX(x);
    this.setPositionY(y);
  }
  
  /**
   * Gibt zurück, ob die Figur bewegt wurde.
   * 
   * @return ob die Figur jemals bewegt wurde.
   */
  public boolean hasMoved() {
    return this.moved;
  }
  
}