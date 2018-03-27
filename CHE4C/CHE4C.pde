/**
 * Hauptdatei des Programms. Öffnet bei Ausführung eine Benutzeroberfläche.
 * Die einzelnen Variablen dieses Skriptes werden nochmal einzelnd kommentiert, da es sich nicht um eine Klasse mit Getter und Setter handelt.
 */

import java.util.AbstractMap;
import java.util.HashSet;
import java.util.Map.Entry;
import java.lang.Runtime;
import processing.video.*;

// Feldgröße in mm des Roboters
int fieldSize = 40;
// Skalierungsfaktor der Feldgröße für die Anzeige durch dieses Programm
float scaleFactor = 3.0;
// Feldgröße in Pixel für die Anzeige
int pxFieldSize = (int) (fieldSize * scaleFactor);

// Zuordnung von ID's der Bildschirmelemente zu ihren Gitter-Koordinaten
HashMap<String, Entry<Byte, Byte>> elementGrid = new HashMap<String, Entry<Byte, Byte>>();
// ID's der Bildschrimelemente
final String TURN_DISPLAY = "turn";
final String WINNER_DISPLAY = "winner";
final String AI_SELECTOR = "ai";
final String GAME_MODE_SELECTOR = "gameMode";
final String BASE_DEPTH_SELECTOR = "baseDepth";
final String SAVE_FRAMES_SELECTOR = "saveFrames";
final String SERIAL_SELECTOR = "serial";
final String CAPTURE_SELECTOR = "capture";
final String VIEW_SELECTOR = "view";
final String PAUSE_BUTTON = "pause";
final String RESET_BUTTON = "reset";

// Zuordnung die alle Bilder der Figuren enthält
HashMap<String, PImage> figureImages = new HashMap<String, PImage>();
// Wahrheitswert, welcher bestimmt ob jeder Spielzug als Screenshot gespeichert wird
boolean saveFrames = false;
// Wahrheitswert, welcher bestimmt ob die Zugausführung pausiert ist
boolean paused = true;
// Name des Ordners im "frames", wo die Screenshots gespeichert werden sollen
String frameFolder;

// Objekt für die serielle Kommunikation mit dem SChFiM-Interpreter
SChFiMTransceiver movementTransceiver;
// Objekt für die serielle Kommunikation mit dem SUIfM-Interpreter
SUIfMTransceiver interactionTransceiver;
// serielle Schnittstelle
Serial serial;

// Objekt für die Bilderkennung
FigureDetector detector;
// Objekte für die Bildaufnahme
Capture capture;

// Liste, die alle getätigten Züge enthält
ArrayList<Entry<Checkerboard, ChessMovement>> executedMovements;
// Enthält die Positionen der Auswahl durch die Benutzeroberfläche
Entry<PVector, PVector> selection = null;
// Enthält den Figurentyp der Auswahl durch die Benutzeroberfläche (wird bei der Umwandlung von Bauern benutzt)
ChessFigureType typeSelection = null;
// Wahrheitswert, ob der ausgewählte Zug ausgeführt werden soll
boolean confirmedSelection = false;

// Objekt für das aktuelle Spielbrett
Checkerboard board;
// Klasse des Spielbretts; Bestimmt somit den Spielmodi
// kurze Anmekrung am Rande: Da .pde-Klassen als innere Klassen implementiert werden, ist der Sketch (this) immer als Parameter jedes Konstruktors übergeben
Class<? extends Checkerboard> checkerboardClass = Checkerboard.class;
// Liste aller Spielbrett-Klassen; Die einzelnen Klassen müssen sich selbst registrieren durch "{checkerboardClasses.add(<Klassenname>.class);}" außerhalb der Klassendefinition
ArrayList<Class<? extends Checkerboard>> checkerboardClasses = new ArrayList<Class<? extends Checkerboard>>();
// Rundenzähler
int round;
// Basistiefe, Programm erweitert die Suchtiefe automatisch abhängig von verschiedenen Faktoren (Figurenanzahl, Figurenverlust, etc.)
float baseDepth = 4;
// Begrenzung für die Basistiefe, welche von der Oberfläche benutzt wird
int depthLimit = 8;
// Wahrheitswert, welcher bestimmt ob Weiß durch das Programm gesteuert wird
boolean isWhiteAI = false;
// Wahrheitswert, welcher bestimmt ob Schwarz durch das Programm gesteuert wird
boolean isBlackAI = true;

/**
 * Funktion, welche bei Ausführung des Programms zuerst, vor setup(), ausgeführt wird.
 * Wird lediglich dazu benutzt um die Größe des Fensters von der Größe eines Feldes abhängig zu machen.
 */
void settings() {
  size(pxFieldSize * 10, pxFieldSize * 8, P2D);
}

/**
 * Funktion, welche bei Ausführung des Programms ausgeführt wird.
 */
void setup() {
  capture = new Capture(this, 640, 480, 30);
  capture.start();
  detector = new FigureDetector();
  capture.read();
  detector.calibrate(capture);
  
  try {
    serial = new Serial(this, Serial.list()[0], 9600);
  } catch (Exception ex) {
    serial = null;
  }
  movementTransceiver = new SChFiMTransceiver(serial);
  interactionTransceiver = new SUIfMTransceiver(serial);
  
  movementTransceiver.setBaseSpeed(50);
  
  textFont(createFont("Gothic", 20));
  
  loadFigureImages();
    
  try {
    board = checkerboardClass.getConstructor(CHE4C.class, boolean.class).newInstance(this, true);
  } catch (Exception ex) {
    checkerboardClass = Checkerboard.class;
    board = new Checkerboard(true);
  }
  
  frameFolder = "f_" + String.valueOf(day()) + "-" + String.valueOf(month()) + "-" + String.valueOf(year()) + "_" + String.valueOf(hour()) + "-" + String.valueOf(minute()) + "-" + String.valueOf(second()) + "_" + hex(int(random(100000)), 4);
  executedMovements = new ArrayList<Entry<Checkerboard, ChessMovement>>();
  round = 0;
}

/**
 * Funktion, welche nach dem Startvorgang wiederholt ausgeführt wird.
 * Zeichnet die Benutzeroberfläche.
 */
void draw() {
  clear();
  textAlign(CENTER);
  
  if (keyPressed && key == CODED && keyCode == SHIFT) {
    detector.drawFOV();
  } else {
    drawCheckerboard(board, fromGridX((byte) 1), fromGridY((byte) 0));
    drawSelection(fromGridX((byte) 1), fromGridY((byte) 0));
    
    drawTurnDisplay(0, 0);
    drawWinnerDisplay(0, 1);
    drawAISelector(0, 5);
    drawGameModeSelector(0, 6);
    drawBaseDepthSelector(0, 7);
    drawPauseButton(9, 6);
    drawResetButton(9, 7);
  }
  if (!paused && (frameCount % 50 == 0)) {
    if (saveFrames)
      saveFrame("frames/" + frameFolder + "/" + str(round) + ".png");
    tryNext();
  }
}

/**
 * Konvertiert x-Gitter-Koordinaten in x-Bildschirmkoordinaten.
 *
 * @param x die x-Gitter-Koordinate
 * @return die zugehörige x-Bildschirmkoordinate
 */
public int fromGridX(byte x) {
  return x * pxFieldSize;
}

/**
 * Konvertiert y-Gitter-Koordinaten in y-Bildschirmkoordinaten.
 *
 * @param y die y-Gitter-Koordinate
 * @return die zugehörige y-Bildschirmkoordinate
 */
public int fromGridY(byte y) {
  return y * pxFieldSize;
}

/**
 * Konvertiert x-Bildschirmkoordinaten in x-Gitter-Koordinaten.
 *
 * @param x die x-Bildschirmkoordinate
 * @return die zugehörige x-Gitter-Koordinate
 */
public byte toGridX(int x) {
  return (byte) constrain(x / pxFieldSize, 0, 9);
}

/**
 * Konvertiert y-Bildschirmkoordinaten in y-Gitter-Koordinaten.
 *
 * @param y die y-Bildschirmkoordinate
 * @return die zugehörige y-Gitter-Koordinate
 */
public byte toGridY(int y) {
  return (byte) constrain(y / pxFieldSize, 0, 7);
}

/**
 * Hilfsfunktion zur Zugauswahl. 
 * Versucht den nächsten Zug auszuführen, bzw. wartet auf die Ausführung des Zuges durch den Spieler.
 * Stößt die Überprüfung des Spielerzuges nach seiner Tätigung an.
 * Falls das Spiel bereits verloren ist, wird nichts berechnet.
 */
public void tryNext() {
  if (board.hasLost(ChessFigureColor.WHITE) || board.hasLost(ChessFigureColor.BLACK)) {
    interactionTransceiver.setControlStatus(ControlStatus.GAME_ENDED);
    return;
  }
    
  ChessFigureColor turn = round % 2 == 0 ? ChessFigureColor.WHITE : ChessFigureColor.BLACK;
  
  // KI spielt
  if (round % 2 == 0 ? isWhiteAI : isBlackAI) {
    interactionTransceiver.setControlStatus(ControlStatus.CALCULATING);
    int depth = floor(32 / pow(board.figures.size() + 1, 1.4) + baseDepth);
    long t1 = System.nanoTime();
    Entry<Checkerboard, ChessMovement> movement = miniMax(turn, new AbstractMap.SimpleEntry<Checkerboard, ChessMovement>(board, null), depth, -Integer.MAX_VALUE / 10, Integer.MAX_VALUE / 10);
    long t2 = System.nanoTime();
    println(depth, (t2 - t1) / 1000000.0);
    
    executedMovements.add(movement);
    interactionTransceiver.setControlStatus(ControlStatus.MOVING);
    delay(10);
    movementTransceiver.transmit(movement.getValue());
    try {
      board = checkerboardClass.getConstructor(CHE4C.class, Checkerboard.class).newInstance(this, movement.getKey());
    } catch (Exception ex) {
      checkerboardClass = Checkerboard.class;
      board = new Checkerboard(movement.getKey());
    }
    interactionTransceiver.resetConfirmation();
    round++;
  // Spieler spielt
  } else {
    Checkerboard next = null;
    ChessMovement move = null;
    
    capture.read();
    detector.analyse(capture);
    
    interactionTransceiver.setControlStatus(ControlStatus.WAITING_FOR_PLAYER);
    // Zug über Benutzeroberfläche getätigt
    if (selection != null && selection.getKey() != null && selection.getValue() != null && confirmedSelection) {
      if (board.getFigureOn((byte) selection.getKey().x, (byte) selection.getKey().y) != null && !selection.getKey().equals(selection.getValue())) {
        ChessFigure toFigure = board.getFigureOn((byte) selection.getValue().x, (byte) selection.getValue().y);
        boolean castling = board.getFigureOn((byte) selection.getKey().x, (byte) selection.getKey().y).type == ChessFigureType.KING && (toFigure != null && toFigure.type == ChessFigureType.ROOK);
        move = new ChessMovement((byte) selection.getKey().x, (byte) selection.getKey().y, (byte) selection.getValue().x, (byte) selection.getValue().y, 
              castling, !castling && toFigure != null, typeSelection);
        try {
          next = checkerboardClass.getConstructor(CHE4C.class, Checkerboard.class).newInstance(this, board);
        } catch (Exception ex) {
          checkerboardClass = Checkerboard.class;
          next = new Checkerboard(board);
        }
        move.apply(next);
      }
    } else if (interactionTransceiver.getConfirmation()) {
      interactionTransceiver.resetConfirmation();
      
      try {
        next = checkerboardClass.getConstructor(CHE4C.class, Checkerboard.class).newInstance(this, board);
      } catch (Exception ex) {
        checkerboardClass = Checkerboard.class;
        next = new Checkerboard(board);
      }
      next.figures = detector.getFigures();
    }
      
    if (next != null) {
      if (board.isSuccessionalBoard(next, turn)) {
        executedMovements.add(new AbstractMap.SimpleEntry<Checkerboard, ChessMovement>(next, move));
        getDifference(board, next);
        interactionTransceiver.setControlStatus(ControlStatus.MOVING);
        delay(10);
        if (move != null)
          movementTransceiver.transmit(move);
        board = next;
        round++;
      } else {
        interactionTransceiver.setControlStatus(ControlStatus.INVALID_BOARD);
      }
      selection = null;
      typeSelection = null;
      confirmedSelection = false;
    }
  }
}

/**
 * Wählt mit Hilfe des MiniMax-Algorithmus den optimalen  nächsten Zug aus.
 * Diese Implemenation entspricht der NegaMax-Variante (https://de.wikipedia.org/wiki/Minimax-Algorithmus)
 * und benutzt die Alpha-Beta-Suche zur Minimierung der Laufzeit (https://de.wikipedia.org/wiki/Alpha-Beta-Suche).
 * 
 * @param player Spielerfarbe, welche den Zug tätigen soll
 * @param current Zuordnung des aktuellen Spielbretts zu seinem dazugehörigen Schachzug (soll im externen Aufruf das aktuelle Spielbrett enthalten; ein dazugehöriger Schachzug ist nicht benötigt)
 * @param depth aktuelle Suchtiefe
 * @param alpha aktuelle untere Schranke (soll im externen Aufruf -Integer.MAX_VALUE / 10 sein)
 * @param beta aktuelle obere Schranke (soll im externen Aufruf Integer.MAX_VALUE / 10 sein)
 * @return der Zuordnung des Spielbretts zu seinem dazugehörigen Schachzug, welcher ausgewählt wurde
 */
protected Entry<Checkerboard, ChessMovement> miniMax(ChessFigureColor player, Entry<Checkerboard, ChessMovement> current, float depth, int alpha, int beta) {
  if (depth <= 0 || current.getKey().hasLost(player) || current.getKey().hasWon(player)) {
    current.getValue().score = current.getKey().getScore(player);
    return current;
  }
  
  HashMap<Checkerboard, ChessMovement> movements = current.getKey().getSuccessionalBoards(player);
  int maxScore = alpha;
  Entry<Checkerboard, ChessMovement> move = current;
  
  for (Entry<Checkerboard, ChessMovement> e : movements.entrySet()) {
    float actualDepth = depth - (current.getKey().figures.size() > e.getKey().figures.size() ? 
          map(constrain(abs(current.getKey().getScore(player) - e.getKey().getScore(player)),
          0, ChessFigureType.QUEEN.getRelativeValue() + ChessFigureType.PAWN.getRelativeValue()), 
          0, ChessFigureType.QUEEN.getRelativeValue() + ChessFigureType.PAWN.getRelativeValue(),
          0.7, 0) : 1);
    int score = -miniMax(player.getOpposing(), e, actualDepth, -beta, -maxScore).getValue().score;
    e.getValue().score = score;
    if (score > maxScore) {
      maxScore = score;
      move = e;
      if (maxScore >= beta)
        break;
    }
  }
  return move;
}

/**
 * Läd die Bilddateien der Figuren aus dem data-Ordner.
 * Die Namen der Dateien müssen den Namen der Figuren-Typen laut dem Enum entsprechen. 
 * @see ChessFigure#getFigureName()
 */
public void loadFigureImages() {
  for (ChessFigureColor c : ChessFigureColor.values()) {
    for (ChessFigureType t : ChessFigureType.values()) {
      String figureName = c.toString() + "_" + t.toString();
      PImage figureImage = loadImage(figureName + ".png");
      figureImage.resize(pxFieldSize, pxFieldSize);
      figureImages.put(figureName, figureImage);
    }
  }
}

/**
 * Zeichnet das angegebene Spielbrett an der angegebenen Position.
 * 
 * @param board das Spielbrett
 * @param x x-Koordinate der oberen, linken Ecke der Anzeige
 * @param y y-Koordinate der oberen, linken Ecke der Anzeige
 */
public void drawCheckerboard(Checkerboard board, int x, int y) {
  noStroke();
  for (byte i = 0; i < 8; i++) {
    for (byte j = 0; j < 8; j++) {
      fill(((i + j) % 2 == 0) ? #FFCE9E : #D18B47);
      rect(x + i * pxFieldSize, y + j * pxFieldSize, pxFieldSize, pxFieldSize);
    }
  }
  
  for (ChessFigure figure : board.figures)
    image(figureImages.get(figure.getFigureName()), x + figure.positionX * pxFieldSize, y + figure.positionY * pxFieldSize);
}

/**
 * Zeichnet die, an der Benutzeroberfläche getätigten, Auswahl.
 * 
 * @param x x-Koordinate der oberen, linken Ecke der Anzeige
 * @param y y-Koordinate der oberen, linken Ecke der Anzeige
 */
public void drawSelection(int x, int y) {
  if (selection == null)
    return;
  noFill();
  strokeWeight(5);
  if (selection.getKey() != null) {
    stroke(#44AAFF);
    rect(x + selection.getKey().x * pxFieldSize, y + selection.getKey().y * pxFieldSize, pxFieldSize, pxFieldSize);
  }
  if (selection.getValue() != null) {
    stroke(#FF4444);
    rect(x + selection.getValue().x * pxFieldSize, y + selection.getValue().y * pxFieldSize, pxFieldSize, pxFieldSize);
    if (typeSelection != null) {
      tint(255, 127);
      ChessFigure tempFigure = new ChessFigure(typeSelection, round % 2 == 0 ? ChessFigureColor.WHITE : ChessFigureColor.BLACK, (byte) 0, (byte) 0);
      image(figureImages.get(tempFigure.getFigureName()), x + pxFieldSize / 32 + selection.getValue().x * pxFieldSize, y + pxFieldSize / 32 + selection.getValue().y * pxFieldSize, pxFieldSize / 4, pxFieldSize / 4);
      noTint();
    }
  }
}

/**
 * Zeichnet eine Anzeige, die angibt, welche Spielerfarbe an der Reihe ist und zeigt den Rundenzähler an.
 * Die Größe entspricht der pixel-Feldgröße.
 * 
 * @param x x-Gitter-Koordinate der oberen, linken Ecke der Anzeige
 * @param y y-Gitter-Koordinate der oberen, linken Ecke der Anzeige
 */
public void drawTurnDisplay(int x, int y) {
  elementGrid.put(TURN_DISPLAY, new AbstractMap.SimpleEntry<Byte, Byte>((byte) x, (byte) y));
  x = fromGridX((byte) x);
  y = fromGridY((byte) y);
  
  fill(#FFFFFF);
  text("Turn: " + str(round), x, y, x + pxFieldSize, y + pxFieldSize);
  
  ChessFigure tempFigure = new ChessFigure(ChessFigureType.KING, round % 2 == 0 ? ChessFigureColor.WHITE : ChessFigureColor.BLACK, (byte) 0, (byte) 0);
  fill(0x99999999);
  stroke(#BBBBBB);
  strokeWeight(5);
  rect(x + pxFieldSize / 4, y + pxFieldSize / 4, pxFieldSize / 2, pxFieldSize / 2);
  image(figureImages.get(tempFigure.getFigureName()), x + pxFieldSize / 4, y + pxFieldSize / 4, pxFieldSize / 2, pxFieldSize / 2);
}

/**
 * Zeichnet eine Anzeige, die angibt, welche Spielerfarbe gewonnen hat.
 * Die Größe entspricht der pixel-Feldgröße.
 * 
 * @param x x-Gitter-Koordinate der oberen, linken Ecke der Anzeige
 * @param y y-Gitter-Koordinate der oberen, linken Ecke der Anzeige
 */
public void drawWinnerDisplay(int x, int y) {
  elementGrid.put(WINNER_DISPLAY, new AbstractMap.SimpleEntry<Byte, Byte>((byte) x, (byte) y));
  x = fromGridX((byte) x);
  y = fromGridY((byte) y);
  
  fill(#FFFFFF);
  text("Winner:", x, y, x + pxFieldSize, y + pxFieldSize);
  
  ChessFigure tempFigure;
  if (board.hasWon(ChessFigureColor.WHITE))
    tempFigure = new ChessFigure(ChessFigureType.KING, ChessFigureColor.WHITE, (byte) 0, (byte) 0);
  else if (board.hasWon(ChessFigureColor.BLACK))
    tempFigure = new ChessFigure(ChessFigureType.KING, ChessFigureColor.BLACK, (byte) 0, (byte) 0);
  else
    return;
  fill(0x99999999);
  stroke(#BBBBBB);
  strokeWeight(5);
  rect(x + pxFieldSize / 4, y + pxFieldSize / 4, pxFieldSize / 2, pxFieldSize / 2);
  image(figureImages.get(tempFigure.getFigureName()), x + pxFieldSize / 4, y + pxFieldSize / 4, pxFieldSize / 2, pxFieldSize / 2);
}

/**
 * Zeichnet ein Element zur Auswahl der Spielerfarben, welche durch die KI gesteuert werden.
 * Die Größe entspricht der pixel-Feldgröße.
 * 
 * @param x x-Gitter-Koordinate der oberen, linken Ecke des Elements
 * @param y y-Gitter-Koordinate der oberen, linken Ecke des Elements
 */
public void drawAISelector(int x, int y) {
  elementGrid.put(AI_SELECTOR, new AbstractMap.SimpleEntry<Byte, Byte>((byte) x, (byte) y));
  x = fromGridX((byte) x);
  y = fromGridY((byte) y);
  
  fill(#FFFFFF);
  text("AI:", x, y, x + pxFieldSize, y + pxFieldSize);
  
  fill(0x99999999);
  stroke(#BBBBBB);
  strokeWeight(5);
  rect(x + pxFieldSize / 5, y + pxFieldSize / 5, 3 * pxFieldSize / 5, 3 * pxFieldSize / 5);
  
  stroke(#BBBBBB);
  strokeWeight(2);
  
  ChessFigure tempFigure;
  tempFigure = new ChessFigure(ChessFigureType.KING, ChessFigureColor.WHITE, (byte) 0, (byte) 0);
  image(figureImages.get(tempFigure.getFigureName()), x + pxFieldSize / 4, y + 0.22 * pxFieldSize, pxFieldSize / 4, pxFieldSize / 4);
  
  if (isWhiteAI)
    fill(#FFFFFF);
  else
    noFill();
  rect(x + pxFieldSize / 4, y + pxFieldSize / 2, pxFieldSize / 4, pxFieldSize / 4);
  
  tempFigure = new ChessFigure(ChessFigureType.KING, ChessFigureColor.BLACK, (byte) 0, (byte) 0);
  image(figureImages.get(tempFigure.getFigureName()), x + pxFieldSize / 2, y + 0.22 * pxFieldSize, pxFieldSize / 4, pxFieldSize / 4);
  
  if (isBlackAI)
    fill(#FFFFFF);
  else
    noFill();
  rect(x + pxFieldSize / 2, y + pxFieldSize / 2, pxFieldSize / 4, pxFieldSize / 4);
}

/**
 * Zeichnet ein Element zur Auswahl des Spielmoduses, bestimmt durch die Klasse von Checkerboard.
 * Die Größe entspricht der pixel-Feldgröße.
 * 
 * @param x x-Gitter-Koordinate der oberen, linken Ecke des Elements
 * @param y y-Gitter-Koordinate der oberen, linken Ecke des Elements
 */
public void drawGameModeSelector(int x, int y) {
  elementGrid.put(GAME_MODE_SELECTOR, new AbstractMap.SimpleEntry<Byte, Byte>((byte) x, (byte) y));
  x = fromGridX((byte) x);
  y = fromGridY((byte) y);
  
  fill(#FFFFFF);
  text("Game Mode: ", x, y, x + pxFieldSize, y + pxFieldSize);
  
  fill(#FFFFFF);
  pushStyle();
  textSize(16);
  text(checkerboardClass.getSimpleName(), x, y + pxFieldSize / 4, x + pxFieldSize, y + 3 * pxFieldSize / 4);
  popStyle();
}

/**
 * Zeichnet ein Element zur Auswahl des Basissuchtiefe.
 * Die Größe entspricht der pixel-Feldgröße.
 * 
 * @param x x-Gitter-Koordinate der oberen, linken Ecke des Elements
 * @param y y-Gitter-Koordinate der oberen, linken Ecke des Elements
 */
public void drawBaseDepthSelector(int x, int y) {
  elementGrid.put(BASE_DEPTH_SELECTOR, new AbstractMap.SimpleEntry<Byte, Byte>((byte) x, (byte) y));
  x = fromGridX((byte) x);
  y = fromGridY((byte) y);
  
  fill(#FFFFFF);
  stroke(#BBBBBB);
  strokeWeight(5);
  text("Base Depth: " + str(baseDepth), x, y, x + pxFieldSize, y + pxFieldSize);
  
  fill(0x99999999);
  rect(x + pxFieldSize / 4, y + 3 * pxFieldSize / 5, pxFieldSize / 4, pxFieldSize / 4);
  fill(#FFFFFF);
  text("-", x + pxFieldSize / 4, y + 3 * pxFieldSize / 5, pxFieldSize / 4, pxFieldSize / 4);
  
  fill(0x99999999);
  rect(x + pxFieldSize / 2, y + 3 * pxFieldSize / 5, pxFieldSize / 4, pxFieldSize / 4);
  fill(#FFFFFF);
  text("+", x + pxFieldSize / 2, y + 3 * pxFieldSize / 5, pxFieldSize / 4, pxFieldSize / 4);
}

/**
 * Zeichnet einen Schalter, der bei Betätigung die Pausierung der Zugausführung schaltet.
 * Die Größe entspricht der pixel-Feldgröße.
 * 
 * @param x x-Gitter-Koordinate der oberen, linken Ecke des Schalteres
 * @param y y-Gitter-Koordinate der oberen, linken Ecke des Schalteres
 */
public void drawPauseButton(int x, int y) {
  elementGrid.put(PAUSE_BUTTON, new AbstractMap.SimpleEntry<Byte, Byte>((byte) x, (byte) y));
  x = fromGridX((byte) x);
  y = fromGridY((byte) y);
  
  fill(paused ? 0xBB00FF00 : 0xBBFF5555);
  stroke(#BBBBBB);
  strokeWeight(5);
  rect(x + pxFieldSize / 4, y + pxFieldSize / 4, pxFieldSize / 2, pxFieldSize / 2);
  
  fill(#FFFFFF);
  noStroke();
  if (paused) {
    triangle(x + pxFieldSize / 3, y + pxFieldSize / 3, x + pxFieldSize / 3, y + 2 * pxFieldSize / 3, x + 2 * pxFieldSize / 3, y + pxFieldSize / 2);
  } else {
    rect(x + pxFieldSize / 3, y + pxFieldSize / 3, pxFieldSize / 8, pxFieldSize / 3);
    rect(x + 2 * pxFieldSize / 3 - pxFieldSize / 8, y + pxFieldSize / 3, pxFieldSize / 8, pxFieldSize / 3);
  }
}

/**
 * Zeichnet einen Schalter, der bei Betätigung das Brett resettet.
 * Die Größe entspricht der pixel-Feldgröße.
 * 
 * @param x x-Gitter-Koordinate der oberen, linken Ecke des Schalteres
 * @param y y-Gitter-Koordinate der oberen, linken Ecke des Schalteres
 */
public void drawResetButton(int x, int y) {
  elementGrid.put(RESET_BUTTON, new AbstractMap.SimpleEntry<Byte, Byte>((byte) x, (byte) y));
  x = fromGridX((byte) x);
  y = fromGridY((byte) y);
  
  fill(0x99999999);
  stroke(#BBBBBB);
  strokeWeight(5);
  rect(x + pxFieldSize / 4, y + pxFieldSize / 4, pxFieldSize / 2, pxFieldSize / 2);
  
  ellipseMode(CORNER);
  noFill();
  stroke(#FFFFFF);
  strokeWeight(5);
  arc(x + pxFieldSize / 3, y + pxFieldSize / 3, pxFieldSize / 3, pxFieldSize / 3, QUARTER_PI, TWO_PI);
  
  fill(#FFFFFF);
  noStroke();
  triangle(x + 0.6 * pxFieldSize, y + pxFieldSize / 2, x + 0.72 * pxFieldSize, y + pxFieldSize / 2, x + 0.66 * pxFieldSize, y + 3 * pxFieldSize / 5);
}

/**
 * Funktion, welche bei Klicken der Maus ausgeführt wird.
 * Lässt den Benutzer Start- und Zielfeld auswählen.
 */
void mouseClicked() {
  byte gridX = toGridX(mouseX);
  byte gridY = toGridY(mouseY);
  
  if (elementGrid.get(AI_SELECTOR) != null && elementGrid.get(AI_SELECTOR).getKey() == gridX && elementGrid.get(AI_SELECTOR).getValue() == gridY) {
    int x = mouseX - fromGridX(gridX);
    int y = mouseY - fromGridY(gridY);
    if (y > pxFieldSize / 2)
      if (x > pxFieldSize / 2 && x < 3 * pxFieldSize / 4)
        isBlackAI = !isBlackAI;
      else if (x > pxFieldSize / 4 && x < pxFieldSize / 2)
        isWhiteAI = !isWhiteAI;
  }
  
  if (elementGrid.get(GAME_MODE_SELECTOR) != null && elementGrid.get(GAME_MODE_SELECTOR).getKey() == gridX && elementGrid.get(GAME_MODE_SELECTOR).getValue() == gridY) {
    int index = checkerboardClasses.indexOf(checkerboardClass);
    if (index == -1)
      checkerboardClass = Checkerboard.class;
    index++;
    if (index < checkerboardClasses.size())
      checkerboardClass = checkerboardClasses.get(index);
    else
      checkerboardClass = checkerboardClasses.get(0);
    
    try {
      board = checkerboardClass.getConstructor(CHE4C.class, Checkerboard.class).newInstance(this, board);
    } catch (Exception ex) {
      checkerboardClass = Checkerboard.class;
      board = new Checkerboard(board);
    }
  }
  
  if (elementGrid.get(BASE_DEPTH_SELECTOR) != null && elementGrid.get(BASE_DEPTH_SELECTOR).getKey() == gridX && elementGrid.get(BASE_DEPTH_SELECTOR).getValue() == gridY) {
    int x = mouseX - fromGridX(gridX);
    int y = mouseY - fromGridY(gridY);
    if (y > 3 * pxFieldSize / 5)
      if (x > pxFieldSize / 2 && x < 3 * pxFieldSize / 4) {
        baseDepth++;
        if (baseDepth > depthLimit)
          baseDepth = 1;
      } else if (x > pxFieldSize / 4 && x < pxFieldSize / 2) {
        baseDepth--;
        if (baseDepth < 1)
          baseDepth = depthLimit;
      }
  }
  
  if (elementGrid.get(RESET_BUTTON) != null && elementGrid.get(RESET_BUTTON).getKey() == gridX && elementGrid.get(RESET_BUTTON).getValue() == gridY) {
    setup();
  }
  
  if (elementGrid.get(PAUSE_BUTTON) != null && elementGrid.get(PAUSE_BUTTON).getKey() == gridX && elementGrid.get(PAUSE_BUTTON).getValue() == gridY) {
    paused = !paused;
  }
  
  if (mouseX >= fromGridX((byte) 1) && mouseX < fromGridX((byte) 9) && mouseY >= fromGridY((byte) 0) && mouseY < fromGridY((byte) 8)) {
    if (selection == null || selection.getKey() == null)
      selection = new AbstractMap.SimpleEntry<PVector, PVector>(new PVector((mouseX - pxFieldSize) / pxFieldSize, mouseY / pxFieldSize), null);
    else if (selection.getKey().x != (mouseX - pxFieldSize) / pxFieldSize || selection.getKey().y != mouseY / pxFieldSize)
      selection.setValue(new PVector((mouseX - pxFieldSize) / pxFieldSize, mouseY / pxFieldSize));
  }
}

/**
 * Funktion, welche beim Drehen des Mausrades ausgeführt wird.
 * Lässt den Benutzer den Figurentyp auswählen.
 */
void mouseWheel() {
  byte gridX = toGridX(mouseX);
  byte gridY = toGridY(mouseY);
    
  if (mouseX >= fromGridX((byte) 1) && mouseX < fromGridX((byte) 9) && mouseY >= fromGridY((byte) 0) && mouseY < fromGridY((byte) 8)) {
    if (typeSelection == null)
      typeSelection = ChessFigureType.values()[0];
    else {
      boolean found = false;
      for (ChessFigureType t : ChessFigureType.values()) {
        if (found) {
          typeSelection = t;
          return;
        }
        if (typeSelection == t)
          found = true;
      }
      if (found)
        typeSelection = null;
    }
  }
}

/**
 * Funktion, welche bei Drücken einer Tastaturtaste ausgeführt wird.
 * Lässt den Benutzer einen Zug bestätigen oder zurücksetzen.
 */
void keyPressed() {
  if (mouseX >= fromGridX((byte) 1) && mouseX < fromGridX((byte) 9) && mouseY >= fromGridY((byte) 0) && mouseY < fromGridY((byte) 8)) {
    if (key == ENTER || key == RETURN)
      confirmedSelection = true;
    if (key == DELETE) {
      selection = null;
      typeSelection = null;
      confirmedSelection = false;
    }
  }
}
