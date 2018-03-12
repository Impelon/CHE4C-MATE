{
  checkerboardClasses.add(Checkerboard.class);
}

/**
 * Implementierung eines Schachbretts für eine vereinfachte Variante des Schachs.
 * Es wird Remis/Patt ignoriert und ein Bauer kann nicht en passant schlagen.
 */
class Checkerboard implements Comparable<Checkerboard> {
  
  protected ArrayList<ChessFigure> figures;
  protected boolean whiteUsedCastling = false;
  protected boolean blackUsedCastling = false;
  
  /**
   * Erstellt eine Instanz von Checkerboard.
   */
  public Checkerboard() {
    this(true);
  }
  
  /**
   * Erstellt eine Instanz von Checkerboard.
   * 
   * @param initial Wenn true, wird die Startaufstellung auf das Schachbrett gelegt. Sonst ist das Schachbrett leer.
   */
  public Checkerboard(boolean initial) {
    this.figures = new ArrayList<ChessFigure>(32);
    if (initial) {
      for (byte n = 0; n < 2; n++) {
      ChessFigureColor c = (n % 2 == 0 ? ChessFigureColor.BLACK : ChessFigureColor.WHITE);
      byte fRow = (byte) (n * 7);
      this.figures.add(new ChessFigure(ChessFigureType.ROOK, c, (byte) 0, fRow));
      this.figures.add(new ChessFigure(ChessFigureType.KNIGHT, c, (byte) 1, fRow));
      this.figures.add(new ChessFigure(ChessFigureType.BISHOP, c, (byte) 2, fRow));
      this.figures.add(new ChessFigure(ChessFigureType.QUEEN, c, (byte) 3, fRow));
      this.figures.add(new ChessFigure(ChessFigureType.KING, c, (byte) 4, fRow));
      this.figures.add(new ChessFigure(ChessFigureType.BISHOP, c, (byte) 5, fRow));
      this.figures.add(new ChessFigure(ChessFigureType.KNIGHT, c, (byte) 6, fRow));
      this.figures.add(new ChessFigure(ChessFigureType.ROOK, c, (byte) 7, fRow));
      for (byte i = 0; i < 8; i++)
        this.figures.add(new ChessFigure(ChessFigureType.PAWN, c, i, (byte) (n % 2 == 0 ? 1 : 6)));
      }
    }
  }
    
  /**
   * Erstellt eine Instanz von Checkerboard aus einer anderen Instanz. 
   * Es wird also eine (tiefe) Kopie der anderen Instanz erstellt.
   * 
   * @param board die andere Instanz, welche kopiert wird
   */
  public Checkerboard(Checkerboard board) {
    this.figures = new ArrayList<ChessFigure>(board.figures.size());
    for (ChessFigure figure : board.figures)
      this.figures.add(new ChessFigure(figure));
    
    this.whiteUsedCastling = board.whiteUsedCastling;
    this.blackUsedCastling = board.blackUsedCastling;
  }
  
  @Override
  public int compareTo(Checkerboard other) {
    return Integer.compare(this.getBoardScore(), other.getBoardScore());
  }
  
  /**
   * Berechnet den Wert des Spielbretts aus der Sicht einer Spielerfarbe.
   *
   * @param chessColor die Spielerfarbe
   * @return der Wert des Spielbretts, positiv falls das Spielbrett positiv für den Spieler aussieht, negativ wenn nicht
   */
  public int getScore(ChessFigureColor chessColor) {
    if (this.hasWon(chessColor))
      return Integer.MAX_VALUE / 10; 
    if (this.hasLost(chessColor))
      return -Integer.MAX_VALUE / 10; 
    
    int score = 0;
    for (ChessFigure figure : this.figures)
      if (figure.chessColor == chessColor)
        score += this.getFigureScore(figure);
      else
        score -= this.getFigureScore(figure);
    return score;
  }
  
  /**
   * Berechnet den Gesamtwert des Spielbretts.
   *
   * @return den Gesamtwert des Spielbretts, welcher sich durch die Figuren auf dem Brett ergeben.
   */
  public int getBoardScore() {
    int boardScore = 0;
    for (ChessFigure figure : this.figures)
      boardScore += this.getFigureScore(figure);
    return boardScore;
  }
  
  /**
   * Berechnet den Wert einer Figur auf dem Spielbrett.
   *
   * @return eine positive Ganzzahl, welche den Wert der Figur auf dem aktuellen Spielbrett ausdrückt
   */
  public int getFigureScore(ChessFigure figure) {
    float scalar = 1.0f;
    switch (figure.type) {
     case PAWN:
       scalar = (figure.chessColor == ChessFigureColor.WHITE ? 7 - figure.getPositionY() : figure.getPositionY()) / 2.0f;
       scalar *= map(this.figures.size(), 0, 32, 0.6, 0.01);
       scalar++;
       break;
     case BISHOP:
       scalar *= map(this.figures.size(), 0, 32, 0.4, 0);
       scalar++;
       break;
     case KNIGHT:
       scalar *= map(this.figures.size(), 0, 32, -0.1, 0.1);
       scalar++;
       break;
    }
    return (int) (scalar * figure.type.getRelativeValue());
  }
  
    /**
   * Gibt zurück, ob das angegebene Schachbrett Resultat eines Spielzuges sein kann.
   *
   * @param board das andere Schachbrett
   * @return ob das angegebene Schachbrett durch einen einzigen, validen Schachzug zum momentanen Schachbrett gebracht werden kann
   */
  public boolean isSuccessionalBoard(Checkerboard board) {
    for (Checkerboard b : this.getSuccessionalBoards().keySet()) {
      boolean same = true;
      for (ChessFigure f1 : board.figures) {
        ChessFigure f2 = b.getFigureOn(f1.getPositionX(), f1.getPositionY());
        if (f2 == null || f1.type != f2.type || f1.chessColor != f2.chessColor) {
            same = false;
            break;
        }
      }
      if (!same)
        continue;
      for (ChessFigure f1 : b.figures) {
        ChessFigure f2 = board.getFigureOn(f1.getPositionX(), f1.getPositionY());
        if (f2 == null || f1.type != f2.type || f1.chessColor != f2.chessColor) {
            same = false;
            break;
        }
      }
      if (same)
        return true;
    }
    return false;
  }
  
  /**
   * Gibt zurück, ob das angegebene Schachbrett Resultat eines Spielzuges der Spielerfarbe sein kann.
   *
   * @param board das andere Schachbrett
   * @param chessColor die Spielerfarbe
   * @return ob das angegebene Schachbrett durch einen einzigen, validen Schachzug des angegebenen Spielers zum momentanen Schachbrett gebracht werden kann
   */
  public boolean isSuccessionalBoard(Checkerboard board, ChessFigureColor chessColor) {
    for (Checkerboard b : this.getSuccessionalBoards(chessColor).keySet()) {
      boolean same = true;
      for (ChessFigure f1 : board.figures) {
        ChessFigure f2 = b.getFigureOn(f1.getPositionX(), f1.getPositionY());
        if (f2 == null || f1.type != f2.type || f1.chessColor != f2.chessColor) {
            same = false;
            break;
        }
      }
      if (!same)
        continue;
      for (ChessFigure f1 : b.figures) {
        ChessFigure f2 = board.getFigureOn(f1.getPositionX(), f1.getPositionY());
        if (f2 == null || f1.type != f2.type || f1.chessColor != f2.chessColor) {
            same = false;
            break;
        }
      }
      if (same)
        return true;
    }
    return false;  
  }
  
  /**
   * Gibt alle Schachfiguren einer Spielerfarbe zurück.
   * 
   * @param chessColor die Spielerfarbe
   * @return eine Liste mit allen Schachfiguren eines Spielers
   */
  public ArrayList<ChessFigure> getFiguresOfColor(ChessFigureColor chessColor) {
    ArrayList<ChessFigure> filtered = new ArrayList<ChessFigure>(this.figures.size());
    for (ChessFigure figure : this.figures)
      if (figure.chessColor == chessColor)
        filtered.add(figure);
    return filtered;
  }
  
  /**
   * Gibt zurück welche Figur sich auf der angegebenen Position befindet.
   * null, falls sich an der angegebenen Position keine Figur befindet.
   * 
   * @param x die x-Position der Figur auf dem Brett (0 - 7)
   * @param y die y-Position der Figur auf dem Brett (0 - 7)
   * @return die Figur an der angegebenen Position
   */
  public ChessFigure getFigureOn(byte x, byte y) {
    for (ChessFigure figure : this.figures)
      if (figure.getPositionX() == x && figure.getPositionY() == y)
        return figure;
    return null;
  }
  
  /**
   * Gibt ob ein Feld frei ist, d.h. dass sich keine Figuren auf dem angegebenen Feld befinden.
   * 
   * @param x die x-Position der Figur auf dem Brett (0 - 7)
   * @param y die y-Position der Figur auf dem Brett (0 - 7)
   * @return ob die Position frei ist
   */
  public boolean isFree(byte x, byte y) {
    for (ChessFigure figure : this.figures)
      if (figure.getPositionX() == x && figure.getPositionY() == y)
        return false;
    return true;
  }
  
  /**
   * Gibt zurück, ob eine bestimmte Spielerfarbe verlohren hat.
   * Zugunfähigkeit wird als verlohrenes Spiel angesehen.
   * 
   * @param chessColor die Spielerfarbe
   * @return ob die Spielerfarbe verlohren hat
   */
  public boolean hasLost(ChessFigureColor chessColor) {
    if (this.getSuccessionalBoards(chessColor).isEmpty())
      return true;
    for (ChessFigure figure : this.figures)
      if (figure.type == ChessFigureType.KING && figure.chessColor == chessColor)
        return false;
    return true;
  }
  
  /**
   * Gibt zurück, ob eine bestimmte Spielerfarbe gewonnen hat.
   * 
   * @param chessColor die Spielerfarbe
   * @return ob die Spielerfarbe gewonnen hat
   */
  public boolean hasWon(ChessFigureColor chessColor) {
    return this.hasLost(chessColor.getOpposing());
  }
    
  /**
   * Berechnet alle möglichen Züge aus dem momentanen Spielzustand und gibt eine Zuordnung der veränderten Schachbretter zu den jeweiligen Schachzügen wieder.
   *
   * @return eine Zuordnung von Spielbrettern zu ihren dazugehörigen Schachzügen
   */
  public HashMap<Checkerboard, ChessMovement> getSuccessionalBoards() {
    HashMap<Checkerboard, ChessMovement> boards = new HashMap<Checkerboard, ChessMovement>();
    for (ChessFigure figure : this.figures)
      boards.putAll(this.getSuccessionalBoards(figure));
    return boards;
  }
  
  /**
   * Berechnet alle möglichen Züge der angegebenen Spielerfarbe aus dem momentanen Spielzustand und gibt eine Zuordnung der veränderten Schachbretter zu den jeweiligen Schachzügen wieder.
   * 
   * @param chessColor die Spielerfarbe
   * @return eine Zuordnung von Spielbrettern zu ihren dazugehörigen Schachzügen
   */
  public HashMap<Checkerboard, ChessMovement> getSuccessionalBoards(ChessFigureColor chessColor) {
    HashMap<Checkerboard, ChessMovement> boards = new HashMap<Checkerboard, ChessMovement>();
    for (ChessFigure figure : this.figures)
      if (figure.chessColor == chessColor)
        boards.putAll(this.getSuccessionalBoards(figure));
    return boards;
  }
  
  /**
   * Berechnet alle möglichen Züge der angegebenen Figur (welche sich auf dem Brett bereits befindet) aus dem momentanen Spielzustand und gibt eine Zuordnung der veränderten Schachbretter zu den jeweiligen Schachzügen wieder.
   * 
   * @param figure die Figur, welche die Züge tätigen soll.
   * @return eine Zuordnung von Spielbrettern zu ihren dazugehörigen Schachzügen
   */
  public HashMap<Checkerboard, ChessMovement> getSuccessionalBoards(ChessFigure figure) {
    if (this.figures.contains(figure)) {
      switch (figure.type) {
        case KING:
          return this.getSuccessionalBoardsWithKing(figure);
        case QUEEN:
          return this.getSuccessionalBoardsWithQueen(figure);
        case ROOK:
          return this.getSuccessionalBoardsWithRook(figure);
        case BISHOP:
          return this.getSuccessionalBoardsWithBishop(figure);
        case KNIGHT:
          return this.getSuccessionalBoardsWithKnight(figure);
        case PAWN:
          return this.getSuccessionalBoardsWithPawn(figure);
      }
    }

    return new HashMap<Checkerboard, ChessMovement>();
  }
  
  /*
   * Konkretete Implementation von getSuccessionalBoards(ChessFigure).
   * (gleiche Parameter- und Rückgabewerte)
   * Es wird davon ausgegangen, dass die übergebene Figur auf dem Brett liegt und der Typ der jeweiligen Methode entspricht.
   * Desshalb sollten diese Methoden nicht von außerhalb angesprochen werden.
   */
  
  protected HashMap<Checkerboard, ChessMovement> getSuccessionalBoardsWithKing(ChessFigure figure) {
    HashMap<Checkerboard, ChessMovement> boards = new HashMap<Checkerboard, ChessMovement>();
        
    // Acht Nachbarfelder
    byte x;
    byte y;
    for (byte i = -1; i < 2; i++) {
      for (byte j = -1; j < 2; j++) {
        x = (byte) (i + figure.getPositionX());
        y = (byte) (j + figure.getPositionY());
        
        if (x < 0 || x >= 8 || y < 0 || y >= 8)
          continue;
        
        ChessFigure tempFigure = this.getFigureOn(x, y);
        if (tempFigure == null || tempFigure.chessColor.getOpposing() == figure.chessColor) {
          Checkerboard board = new Checkerboard(this);
          ChessMovement movement = new ChessMovement(figure.getPositionX(), figure.getPositionY(), x, y, false, tempFigure != null);
          movement.apply(board);
          boards.put(board, movement);
        }
      }
    }
    
    // Rochade
    // eine weniger flexible Rochade wäre mit Chess960 kompatibel
    if (!(figure.hasMoved() || (figure.chessColor == ChessFigureColor.WHITE ? this.whiteUsedCastling : this.blackUsedCastling))) {
      for (byte dir = 0; dir < 2; dir++) {
        byte offset = (byte) (dir % 2 == 0 ? 1 : -1);
        for (x = (byte) (figure.getPositionX() + offset); x < 8 && x >= 0; x += offset) {
          ChessFigure tempFigure = this.getFigureOn(x, figure.getPositionY());
          if (tempFigure == null)
            continue;
          else {
            if (tempFigure.chessColor == figure.chessColor && tempFigure.type == ChessFigureType.ROOK && !tempFigure.hasMoved()) {
              Checkerboard board = new Checkerboard(this);
              ChessMovement movement = new ChessMovement(figure.getPositionX(), figure.getPositionY(), x, figure.getPositionY(), true, false);
              movement.apply(board);
              boards.put(board, movement);
            }
            break;
          }
        }
      }
    }
    
    return boards;
  }
  
  protected HashMap<Checkerboard, ChessMovement> getSuccessionalBoardsWithQueen(ChessFigure figure) {
    HashMap<Checkerboard, ChessMovement> boards = new HashMap<Checkerboard, ChessMovement>();
    
    // Vier Diagonalen und vier Himmelsrichtungen
    boards.putAll(this.getSuccessionalBoardsWithRook(figure));
    boards.putAll(this.getSuccessionalBoardsWithBishop(figure));
    
    return boards;
  }
  
  protected HashMap<Checkerboard, ChessMovement> getSuccessionalBoardsWithRook(ChessFigure figure) {
    HashMap<Checkerboard, ChessMovement> boards = new HashMap<Checkerboard, ChessMovement>();
    
    // Vier Himmelsrichtungen
    for (byte dir = 0; dir < 4; dir++) {
      byte start = (dir < 2 ? figure.getPositionX() : figure.getPositionY());
      byte x;
      byte y;
      byte offset = (byte) (dir % 2 == 0 ? 1 : -1);
      for (byte i = offset; (i + start < 8) && (i + start >= 0); i += offset) {
        switch (dir) {
          default:
          case 0:
          case 1:
            x = (byte) (i + start);
            y = figure.getPositionY();
            break;
          case 2:
          case 3:
            x = figure.getPositionX();
            y = (byte) (i + start);
            break;
        }
        
        ChessFigure tempFigure = this.getFigureOn(x, y);
        if (tempFigure == null || tempFigure.chessColor.getOpposing() == figure.chessColor) {
          Checkerboard board = new Checkerboard(this);
          ChessMovement movement = new ChessMovement(figure.getPositionX(), figure.getPositionY(), x, y, false, tempFigure != null);
          movement.apply(board);
          boards.put(board, movement);
        }
        if (tempFigure != null)
          break;
      }
    }
    
    return boards;
  }
  
  protected HashMap<Checkerboard, ChessMovement> getSuccessionalBoardsWithBishop(ChessFigure figure) {
    HashMap<Checkerboard, ChessMovement> boards = new HashMap<Checkerboard, ChessMovement>();
    
    // Vier Diagonalen
    for (byte dir = 0; dir < 4; dir++) {
      byte x;
      byte y;
      byte offset = (byte) (dir % 2 == 0 ? 1 : -1);
      for (byte i = offset; true; i += offset) {
        y = (byte) (i + figure.getPositionY());
        switch (dir) {
          default:
          case 0:
          case 3:
            x = (byte) (i + figure.getPositionX());
            break;
          case 1:
          case 2:
            x = (byte) (-i + figure.getPositionX());
            break;
        }
        
        if (x < 0 || x >= 8 || y < 0 || y >= 8)
          break;
        
        ChessFigure tempFigure = this.getFigureOn(x, y);
        if (tempFigure == null || tempFigure.chessColor.getOpposing() == figure.chessColor) {
          Checkerboard board = new Checkerboard(this);
          ChessMovement movement = new ChessMovement(figure.getPositionX(), figure.getPositionY(), x, y, false, tempFigure != null);
          movement.apply(board);
          boards.put(board, movement);
        }
        if (tempFigure != null)
          break;
      }
    }
    
    return boards;
  }
  
  protected HashMap<Checkerboard, ChessMovement> getSuccessionalBoardsWithKnight(ChessFigure figure) {
    HashMap<Checkerboard, ChessMovement> boards = new HashMap<Checkerboard, ChessMovement>();
    
    byte x;
    byte y;
    for (byte mode = 0; mode < 8; mode++) {
      if (mode % 2 == 0) {
        x = (byte) ((mode < 4 ? 2 : -2) + figure.getPositionX());
        y = (byte) ((mode % 4 < 2 ? 1 : -1) + figure.getPositionY());
      } else {
        x = (byte) ((mode < 4 ? 1 : -1) + figure.getPositionX());
        y = (byte) ((mode % 4 < 2 ? 2 : -2) + figure.getPositionY());
      }
      
      if (x < 0 || x >= 8 || y < 0 || y >= 8)
        continue;
      
      ChessFigure tempFigure = this.getFigureOn(x, y);
      if (tempFigure == null || tempFigure.chessColor.getOpposing() == figure.chessColor) {
        Checkerboard board = new Checkerboard(this);
        ChessMovement movement = new ChessMovement(figure.getPositionX(), figure.getPositionY(), x, y, false, tempFigure != null);
        movement.apply(board);
        boards.put(board, movement);
      }
    }
    
    return boards;
  }
  
  protected HashMap<Checkerboard, ChessMovement> getSuccessionalBoardsWithPawn(ChessFigure figure) {
    HashMap<Checkerboard, ChessMovement> boards = new HashMap<Checkerboard, ChessMovement>();
    
    byte direction = (byte) (figure.chessColor == ChessFigureColor.WHITE ? -1 : 1);
    
    // Doppelsprung
    if (!figure.hasMoved()) {
      if (this.getFigureOn(figure.getPositionX(), (byte) (figure.getPositionY() + direction)) == null && this.getFigureOn(figure.getPositionX(), (byte) (figure.getPositionY() + direction + direction)) == null) {
        Checkerboard board = new Checkerboard(this);
        ChessMovement movement = new ChessMovement(figure.getPositionX(), figure.getPositionY(), figure.getPositionX(), (byte) (figure.getPositionY() + direction + direction), false, false);
        movement.apply(board);
        boards.put(board, movement);
      }
    }
      
    byte x;
    byte y = (byte) (figure.getPositionY() + direction);
    for (byte i = -1; i < 2; i++) {
      x = (byte) (i + figure.getPositionX());
      ChessFigure tempFigure = this.getFigureOn(x, y);
      Checkerboard tempBoard = null;
      ChessMovement tempMovement = null;
      if (i == 0) {
        // Vorwärts
        if (tempFigure == null)
          tempBoard = new Checkerboard(this);
          tempMovement = new ChessMovement(figure.getPositionX(), figure.getPositionY(), x, y, false, false);
      } else {
        // Diagonalschlag
        if (tempFigure != null && tempFigure.chessColor.getOpposing() == figure.chessColor)
          tempBoard = new Checkerboard(this);
          tempMovement = new ChessMovement(figure.getPositionX(), figure.getPositionY(), x, y, false, true);
      }
      
      if (tempBoard == null)
        continue;
      
      // Umwandlung
      if (y == (figure.chessColor == ChessFigureColor.WHITE ? 0 : 7)) {
        for (ChessFigureType type : ChessFigureType.values()) {
          if (type != ChessFigureType.PAWN && type != ChessFigureType.KING) {
            Checkerboard board = new Checkerboard(tempBoard);
            ChessMovement movement = new ChessMovement(tempMovement);
            movement.toType = type;
            movement.apply(board);
            boards.put(board, movement);
          }
        }
      } else {
        tempMovement.apply(tempBoard);
        boards.put(tempBoard, tempMovement);
      }
    }

    return boards;
  }

}