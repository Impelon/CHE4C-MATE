/**
 * Aufzählung für die Spielerfarbe von Schachfiguren.
 */
enum ChessFigureColor {
  WHITE,
  BLACK;
  
   /**
    * Gibt die gegnerische Spielerfarbe zurück.
    * 
    * @return die gegnerische Spielerfarbe
    */
  ChessFigureColor getOpposing() {
    return this == WHITE ? BLACK : WHITE;
  }
}