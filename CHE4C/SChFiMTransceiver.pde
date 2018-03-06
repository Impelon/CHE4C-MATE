import processing.serial.*;
import java.util.ArrayDeque;

/**
 * Klasse, dessen Instanzen über eine serielle Schnittstelle mit dem SChFiM-Interpreter (Arduino) kommunizieren.
 */
class SChFiMTransceiver extends SerialTransceiver {
  
  protected final static String SET_SYNTAX = "/s %s %d \n";
  protected final static String GET_SYNTAX = "/g %s \n";
  protected final static String RESET_SYNTAX = "/x \n";
  
  protected ArrayDeque<Long> baseSpeedQueue = new ArrayDeque<Long>();
  protected ArrayDeque<Long> fieldSizeQueue = new ArrayDeque<Long>();
  protected ArrayDeque<Boolean> magnetEnabeledQueue = new ArrayDeque<Boolean>();
  protected ArrayDeque<Integer> figuresInStorageQueue = new ArrayDeque<Integer>();
  protected ArrayDeque<Integer> currentXQueue = new ArrayDeque<Integer>();
  protected ArrayDeque<Integer> currentYQueue = new ArrayDeque<Integer>();
  protected ArrayDeque<Integer> distanceXQueue = new ArrayDeque<Integer>();
  protected ArrayDeque<Integer> distanceYQueue = new ArrayDeque<Integer>();
  
  /**
   * Erstellt eine Instanz von SChFiMTransceiver.
   * Es wird die erste Schnittstelle aus der Liste der möglichen Schnittstellen gewählt und mit der Frequenz 9600Hz initialisiert.
   *
   * @param applet Referenz zum Hauptskript (Instanz von PApplet)
   */
  public SChFiMTransceiver(PApplet applet) {
    try {
      this.connect(new Serial(applet, Serial.list()[0], 9600));
    } catch (Exception ex) {
      this.disconnect();
    }
  }
  
  /**
   * Erstellt eine Instanz von SChFiMTransceiver.
   * 
   * @param serial Schnittstelle für die serielle Kommunikation
   */
  public SChFiMTransceiver(Serial serial) {
    this.connect(serial);
  }
  
  /**
   * Sendet einen Schachzug über die serielle Schnittstelle.
   * Bricht die Verbindung ab, falls ein Fehler auftritt.
   * 
   * @param movement der Schachzug, welcher gesendet werden soll
   * @return Wahrheitswert, ob das Senden erfolgreich war
   */
  public boolean transmit(ChessMovement movement) {
    return this.transmit(movement.toSChFiMCommandSequence());
  }
  
  @Override
  protected void interpretLines(String data) {
    String[] lines = data.split("\n");
    
    for (String line : lines) {
      if (line.length() <= 1)
        continue;
      
      switch (line.charAt(0)) {
        case 'f':
          fieldSizeQueue.offer(Long.parseLong(line.replaceAll("[\\D]", "")));
          break;
        case 's':
          switch (line.charAt(1)) {
            case 'f':
              figuresInStorageQueue.offer(Integer.parseInt(line.replaceAll("[\\D]", "")));
              break;
            default:
              baseSpeedQueue.offer(Long.parseLong(line.replaceAll("[\\D]", "")));
          }
          break;
        case 'm':
          magnetEnabeledQueue.offer(new Boolean(Integer.parseInt(line.replaceAll("[\\D]", "")) != 0));
          break;
        case 'c':
          switch (line.charAt(1)) {
            case 'x':
              currentXQueue.offer(Integer.parseInt(line.replaceAll("[\\D]", "")));
              break;
            case 'y':
              currentYQueue.offer(Integer.parseInt(line.replaceAll("[\\D]", "")));
              break;
          }
          break;
        case 'd':
          switch (line.charAt(1)) {
            case 'x':
              distanceXQueue.offer(Integer.parseInt(line.replaceAll("[\\D]", "")));
              break;
            case 'y':
              distanceYQueue.offer(Integer.parseInt(line.replaceAll("[\\D]", "")));
              break;
          }
        break;
      }
    }
  }
  
  /**
   * Sendet den Zurücksetzungsbefehl.
   * 
   * @return Wahrheitswert, ob das Senden erfolgreich war
   */
  public boolean resetMotors() {
    return this.transmit(RESET_SYNTAX);
  }
  
  /**
   * Sendet die Basis-Drehgeschwindigkeit der Stepper in Umdrehungen pro Minute (revolutions per minute).
   * 
   * @param rpm Drehgeschwindigkeit in Umdrehungen pro Minute
   * @return Wahrheitswert, ob das Senden erfolgreich war
   */
  public boolean setBaseSpeed(long rpm) {
    return this.transmit(String.format(SET_SYNTAX, "s", rpm));
  }
  
  /**
   * Fordert die Basis-Drehgeschwindigkeit der Stepper in Umdrehungen pro Minute (revolutions per minute) an.
   * 
   * @return Wahrheitswert, ob das Senden der Anfrage erfolgreich war
   */
  public boolean requestBaseSpeed() {
    return this.transmit(String.format(GET_SYNTAX, "s"));
  }
  
  /**
   * Gibt die Basis-Drehgeschwindigkeit der Stepper in Umdrehungen pro Minute (revolutions per minute) zurück.
   * Erfordert eine zuvorige Anfrage.
   * Falls keine Werte verfügbar sind, wird null zurückgegeben.
   * Es wird nicht garantiert, dass die Antworten auf Anfragen in-order zurückgegeben werden.
   * 
   * @return Drehgeschwindigkeit in Umdrehungen pro Minute
   */
  public Long getBaseSpeed() {
    if (this.isConnected())
      SerialTransceiver.poll(this.serial);
    return this.baseSpeedQueue.poll();
  }
  
  /**
   * Sendet die Seitenlänge eines einzelnen Schachfeldes.
   * 
   * @param die Seitenlänge eines Schachfeldes
   * @return Wahrheitswert, ob das Senden erfolgreich war
   */
  public boolean setFieldSize(int fSize) {
    return this.transmit(String.format(SET_SYNTAX, "f", fSize));
  }
  
  /**
   * Fordert die Seitenlänge eines einzelnen Schachfeldes an.
   * 
   * @return Wahrheitswert, ob das Senden der Anfrage erfolgreich war
   */
  public boolean requestFieldSize() {
    return this.transmit(String.format(GET_SYNTAX, "f"));
  }
  
  /**
   * Gibt die Seitenlänge eines einzelnen Schachfeldes zurück.
   * Erfordert eine zuvorige Anfrage.
   * Falls keine Werte verfügbar sind, wird null zurückgegeben.
   * Es wird nicht garantiert, dass die Antworten auf Anfragen in-order zurückgegeben werden.
   * 
   * @return die Seitenlänge eines Schachfeldes
   */
  public Long getFieldSize() {
    if (this.isConnected())
      SerialTransceiver.poll(this.serial);
    return this.fieldSizeQueue.poll();
  }
  
  /**
   * Fordert den Wahrheitswert an, ob der Magnet eingeschaltet ist.
   * 
   * @return Wahrheitswert, ob das Senden der Anfrage erfolgreich war
   */
  public boolean requestMagnetEnabeled() {
    return this.transmit(String.format(GET_SYNTAX, "m"));
  }
  
  /**
   * Gibt zurück, ob der Magnet eingeschaltet ist.
   * Erfordert eine zuvorige Anfrage.
   * Falls keine Werte verfügbar sind, wird null zurückgegeben.
   * Es wird nicht garantiert, dass die Antworten auf Anfragen in-order zurückgegeben werden.
   * 
   * @return ob der Magnet eingeschaltet ist
   */
  public Boolean getMagnetEnabeled() {
    if (this.isConnected())
      SerialTransceiver.poll(this.serial);
    return this.magnetEnabeledQueue.poll();
  }
  
  /**
   * Fordert die Anzahl der Figuren in der Ablage an.
   * 
   * @return Wahrheitswert, ob das Senden der Anfrage erfolgreich war
   */
  public boolean requestFiguresInStorage() {
    return this.transmit(String.format(GET_SYNTAX, "sf"));
  }
  
  /**
   * Gibt die Anzahl der Figuren in der Ablage zurück.
   * Erfordert eine zuvorige Anfrage.
   * Falls keine Werte verfügbar sind, wird null zurückgegeben.
   * Es wird nicht garantiert, dass die Antworten auf Anfragen in-order zurückgegeben werden.
   * 
   * @param die Anzahl der Figuren in der Ablage
   */
  public Integer getFiguresInStorage() {
    if (this.isConnected())
      SerialTransceiver.poll(this.serial);
    return this.figuresInStorageQueue.poll();
  }
  
  /**
   * Fordert die x-Eckkoordinate der momentanen Position an.
   * 
   * @return Wahrheitswert, ob das Senden der Anfrage erfolgreich war
   */
  public boolean requestCurrentX() {
    return this.transmit(String.format(GET_SYNTAX, "cx"));
  }
  
  /**
   * Gibt die x-Eckkoordinate der momentanen Position zurück.
   * Erfordert eine zuvorige Anfrage.
   * Falls keine Werte verfügbar sind, wird null zurückgegeben.
   * Es wird nicht garantiert, dass die Antworten auf Anfragen in-order zurückgegeben werden.
   * 
   * @return die x-Koordinate
   */
  public Integer getCurrentX() {
    if (this.isConnected())
      SerialTransceiver.poll(this.serial);
    return this.currentXQueue.poll();
  }
  
  /**
   * Fordert die y-Eckkoordinate der momentanen Position an.
   * 
   * @return Wahrheitswert, ob das Senden der Anfrage erfolgreich war
   */
  public boolean requestCurrentY() {
    return this.transmit(String.format(GET_SYNTAX, "cy"));
  }
  
  /**
   * Gibt die y-Eckkoordinate der momentanen Position zurück.
   * Erfordert eine zuvorige Anfrage.
   * Falls keine Werte verfügbar sind, wird null zurückgegeben.
   * Es wird nicht garantiert, dass die Antworten auf Anfragen in-order zurückgegeben werden.
   * 
   * @return die y-Koordinate
   */
  public Integer getCurrentY() {
    if (this.isConnected())
      SerialTransceiver.poll(this.serial);
    return this.currentYQueue.poll();
  }
  
  /**
   * Fordert den Abstand auf der x-Achse zur letzten Position in Eckkoordinaten an.
   * 
   * @return Wahrheitswert, ob das Senden der Anfrage erfolgreich war
   */
  public boolean requestDistanceToLastX() {
    return this.transmit(String.format(GET_SYNTAX, "dx"));
  }
  
  /**
   * Gibt den Abstand auf der x-Achse zur letzten Position in Eckkoordinaten zurück.
   * Erfordert eine zuvorige Anfrage.
   * Falls keine Werte verfügbar sind, wird null zurückgegeben.
   * Es wird nicht garantiert, dass die Antworten auf Anfragen in-order zurückgegeben werden.
   * 
   * @return der x-Abstand
   */
  public Integer getDistanceToLastX() {
    if (this.isConnected())
      SerialTransceiver.poll(this.serial);
    return this.distanceXQueue.poll();
  }
  
  /**
   * Fordert den Abstand auf der y-Achse zur letzten Position in Eckkoordinaten an.
   * 
   * @return Wahrheitswert, ob das Senden der Anfrage erfolgreich war
   */
  public boolean requestDistanceToLastY() {
    return this.transmit(String.format(GET_SYNTAX, "dy"));
  }
  
  /**
   * Gibt den Abstand auf der y-Achse zur letzten Position in Eckkoordinaten zurück.
   * Erfordert eine zuvorige Anfrage.
   * Falls keine Werte verfügbar sind, wird null zurückgegeben.
   * Es wird nicht garantiert, dass die Antworten auf Anfragen in-order zurückgegeben werden.
   * 
   * @return der y-Abstand
   */
  public Integer getDistanceToLastY() {
    if (this.isConnected())
      SerialTransceiver.poll(this.serial);
    return this.distanceYQueue.poll();
  }
  
}