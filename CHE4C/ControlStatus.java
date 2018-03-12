/**
 * Aufzählung für den Control-Status für den Arduino.
 */
enum ControlStatus {
  IDLE(0),
  CALCULATING(1),
  MOVING(2),
  INVALID_BOARD(3),
  WAITING_FOR_PLAYER(4),
  GAME_ENDED(5);
  
  protected int statusByte;
  
  ControlStatus(int statusByte) {
    this.statusByte = statusByte;
  }
  
  /**
   * Gibt die byte-Repräsentation des Status zurück.
   * 
   * @return ein byte, welches den Status repräsentiert
   */
  int getStatusByte() {
    return this.statusByte;
  }
  
  /**
   * Gibt den ControlStatus entsprechend der byte-Repräsentation zurück.
   * 
   * @param statusByte die byte-Repräsentation
   * @return den ControlStatus; null, falls kein entsprechender ControlStatus existiert
   */
  public static ControlStatus valueOf(int statusByte) {
    for (ControlStatus status : values())
      if (status.statusByte == statusByte)
        return status;
    return null;
  }
  
}