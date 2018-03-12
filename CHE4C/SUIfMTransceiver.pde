import processing.serial.*;
import java.util.ArrayDeque;

/**
 * Klasse, dessen Instanzen über eine serielle Schnittstelle mit dem SUIfM-Interpreter (Arduino) kommunizieren.
 */
class SUIfMTransceiver extends SerialTransceiver {
  
  protected final static String SET_SYNTAX = "/s %s %d \n";
  protected final static String GET_SYNTAX = "/g %s \n";
  
  protected ArrayDeque<Integer> controlStatusQueue = new ArrayDeque<Integer>();
  protected boolean confirmed = false;
  
  
  /**
   * Erstellt eine Instanz von SUIfMTransceiver.
   * Es wird die erste Schnittstelle aus der Liste der möglichen Schnittstellen gewählt und mit der Frequenz 9600Hz initialisiert.
   *
   * @param applet Referenz zum Hauptskript (Instanz von PApplet)
   */
  public SUIfMTransceiver(PApplet applet) {
    try {
      this.connect(new Serial(applet, Serial.list()[0], 9600));
    } catch (Exception ex) {
      this.disconnect();
    }
  }
  
  /**
   * Erstellt eine Instanz von SUIfMTransceiver.
   * 
   * @param serial Schnittstelle für die serielle Kommunikation
   */
  public SUIfMTransceiver(Serial serial) {
    this.connect(serial);
  }
  
  @Override
  protected void interpretLines(String data) {
    String[] lines = data.split("\n");
    
    for (String line : lines) {
      if (line.startsWith("/confirm")) {
        confirmed = true;
        continue;
      }
      if (line.length() <= 1)
        continue;
      
      switch (line.charAt(0)) {
        case 'c':
          switch (line.charAt(1)) {
            case 's':
              controlStatusQueue.offer(Integer.parseInt(line.replaceAll("[\\D]", "")));
              break;
          }
          break;
      }
    }
  }
  
  /**
   * Setzt den Bestätigungzustand zurück.
   */
  public void resetConfirmation() {
    if (this.isConnected())
      SerialTransceiver.poll(this.serial);
    this.confirmed = false;
  }
  
  /**
   * Gibt zurück, ob der Benutzer bestätigt hat.
   * 
   * @return Wahrheitswert, ob der Benutzer bestätigt hat
   */
  public boolean getConfirmation() {
    if (this.isConnected())
      SerialTransceiver.poll(this.serial);
    return this.confirmed;
  }
  
  /**
   * Sendet den ControlStatus, welcher angezeigt werden soll.
   * 
   * @param status der ControlStatus
   * @return Wahrheitswert, ob das Senden erfolgreich war
   */
  public boolean setControlStatus(ControlStatus status) {
    return this.transmit(String.format(SET_SYNTAX, "cs", status.getStatusByte()));
  }
  
  /**
   * Fordert den ControlStatus an.
   * 
   * @return Wahrheitswert, ob das Senden der Anfrage erfolgreich war
   */
  public boolean requestControlStatus() {
    return this.transmit(String.format(GET_SYNTAX, "cs"));
  }
  
  /**
   * Gibt die Basis-Drehgeschwindigkeit der Stepper in Umdrehungen pro Minute (revolutions per minute) zurück.
   * Erfordert eine zuvorige Anfrage.
   * Falls keine Werte verfügbar sind, wird null zurückgegeben.
   * Es wird nicht garantiert, dass die Antworten auf Anfragen in-order zurückgegeben werden.
   * 
   * @return Drehgeschwindigkeit in Umdrehungen pro Minute
   */
  public ControlStatus getControlStatus() {
    if (this.isConnected())
      SerialTransceiver.poll(this.serial);
    Integer result = this.controlStatusQueue.poll();
    if (result == null)
      return null;
    return ControlStatus.valueOf(result);
  }
  
}