import processing.serial.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map.Entry;
import java.util.Iterator;

/**
 * abstrakte Klasse, für die Kommunikation über die serielle Schnittstelle.
 */
abstract class SerialTransceiver {
  
  protected static final ArrayList<SerialTransceiver> receivers = new ArrayList<SerialTransceiver>();
  protected Serial serial = null;
  // separate Threads zum Senden von Daten. Falls sie nicht terminieren, wird die Verbindung unterbrochen.
  private final HashMap<Long, Thread> transmissionThreads = new HashMap<Long, Thread>();
  
  /**
   * Gibt zurück, ob eine Verbindung hergestellt wurde.
   */
  public boolean isConnected() {
    return this.serial != null;
  }
  
  /**
   * Bricht die aktuelle Verbindung ab und verbindet neu.
   *
   * @param serial Schnittstelle für die serielle Kommunikation
   */
  public void connect(Serial serial) {
    this.disconnect();
    this.serial = serial;
    receivers.add(this);
  }
  
  /**
   * Bricht die aktuelle Verbindung ab.
   */
  public void disconnect() {
    if (this.serial != null)
      this.serial.stop();
    this.serial = null;
    receivers.remove(this);
  }
  
  /**
   * Gibt die Schnittstelle für die serielle Kommunikation zurück.
   * 
   * @return die Schnittstelle; null, falls keine Verbindung geschafft wurde
   */
  public Serial getSerial() {
    return this.serial;
  }
  
  /**
   * Sendet Daten über die serielle Schnittstelle.
   * Bricht die Verbindung ab, falls ein Fehler auftritt.
   * 
   * @param data die Daten, welche gesendet werden sollen
   * @return Wahrheitswert, ob das Senden erfolgreich war
   */
  public boolean transmit(String data) {
    if (!this.isConnected())
      return false;
    try {
      boolean disconnect = false;
      for (Iterator<Entry<Long, Thread>> iterator = this.transmissionThreads.entrySet().iterator(); iterator.hasNext();) {
        Entry<Long, Thread> entry = iterator.next();
        if (System.currentTimeMillis() - entry.getKey() > 2000) {
          if (entry.getValue() != null) {
            if (entry.getValue().isAlive())
              disconnect = true;
            else
              iterator.remove();
          } else
            iterator.remove();
        }
      }
      if (disconnect) {
        this.transmissionThreads.clear();
        this.disconnect();
        return false;
      }
      
      Thread thread = new Thread(new SerialTransmissionRunnable(this.serial, data));
      thread.start();
      transmissionThreads.put(System.currentTimeMillis(), thread);
    } catch (Exception ex) {
      this.disconnect();
      return false;
    }
    return true;
  }
  
  /**
   * Sucht im übergebenen String nach Daten und versucht diese zu interpretieren.
   * 
   * @param data String mit Daten
   */
  protected abstract void interpretLines(String data);
  
  /**
   * Empfängt Daten über die serielle Schnittstelle und sendet diese zum interpretieren weiter.
   */
  public static void poll(Serial serial) {
    if (serial == null)
      return;
    String lines = "";
    while (serial.available() > 0) {
      String line = serial.readStringUntil('\n');
      if (line == null)
        break;
      lines += line;
    }
    
    for (SerialTransceiver receiver : receivers) {
      if (serial == receiver.getSerial())
        receiver.interpretLines(lines);
    }
  }
  
  
  /**
   * Klasse, dessen Instanzen Daten über die serielle Schnittstelle übermitteln.
   */
  class SerialTransmissionRunnable implements Runnable {
  
  private Serial serial;
  private String data;
  
  public SerialTransmissionRunnable(Serial serial, String data) {
    this.serial = serial;
    this.data = data;
  }
  
  @Override
  public void run() {
    try {
      if (this.serial != null)
        this.serial.write(data);
    } catch (Exception ex) {}
  }
  
}
  
}