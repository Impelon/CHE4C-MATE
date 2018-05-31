import processing.video.*;

/**
 * Grundlage für die Bilderkennung.
 * Erhält bei jedem Aufruf einer Analyse ein Bild übergeben, welches es analysiert.
 */
interface FigureDetector {
  
  /**
   * Kalibriert die Farbwerte der Kamera.
   *
   * @param video das Bild, welches analysiert werden soll
   */
  public void calibrate(PImage video);
  
  /**
   * Analysiert ein �bergebenes Bild nach Schachfiguren.
   * 
   * @param video das Bild, welches analysiert werden soll
   */
  public void analyse(PImage video);
  
  /**
   * Gibt eine Liste aller gefundener Schachfiguren zurück. 
   * Hierzu muss zuerst ein Bild analysiert worden sein.
   *
   * @return eine Liste mit allen gefundenen Schachfiguren
   */
  public ArrayList<ChessFigure> getFigures();
    
  /**
   * Zeichnet das Sichtfeld und die erkannten Figuren.
   * 
   * @param x x-Koordinate der oberen, linken Ecke der Anzeige
   * @param y y-Koordinate der oberen, linken Ecke der Anzeige
   * @param w die Breite der Anzeige
   * @param h die H�he der Anzeige
   */
  public void drawFOV(int x, int y, int w, int h);

}