import processing.video.*;

/**
 * Klasse für die Bilderkennung.
 * Erhält bei jedem Aufruf einer Analyse ein Bild übergeben, welches es analysiert.
 */
class FigureDetector {

  protected int figureArray[] = new int[64];
  protected int[] whiteDifArray = {0,0,0};
  protected PImage video;
  
  protected int pSY;
  protected int pSX;
    
  protected int pEY;
  protected int pEX;
  
  protected int yDif;
  protected int xDif;
  
  /**
   * Kalibriert die Farbwerte der Kamera.
   * Die Kamera benötigt an der Stelle (40|100) ein weißes Papier zur Kalibration.
   * Weiß hat normalerweise den RGB-Wert (255, 255, 255). Aufgrund von Lichtverhältnissen und Bildrauschen verändern sich aber alle gemessenen Werte. 
   * Diese Veränderung wird hierdurch festgehalten, damit sie später berücksichtigt werden kann.
   *
   * @param video das Bild, welches analysiert werden soll
   */
  public void calibrate(PImage video) {
    this.video = video;
        
    int x = video.width / 8;
    int y = video.height / 4;
    
    color currentColor = video.get(x, y);
    
    float r = red(currentColor);
    float g = green(currentColor);
    float b = blue(currentColor);
    
    r = constrain(r, 0, 255);
    g = constrain(g, 0, 255);
    b = constrain(b, 0, 255);
    
    whiteDifArray[0] = 255 - (int) r;
    whiteDifArray[1] = 255 - (int) g;
    whiteDifArray[2] = 255 - (int) b;
    
    searchStart();
    searchEnd();
    calculateBounds();
  }
  
  /**
   * Sucht nach dem ersten Pixel, womit das Schachbrett anfängt.
   * Hierfür wird nur die obere Bildhälfte abgesucht, sodass es zu weniger Fehlern/Ungenauigkeiten kommt.
   */
  protected void searchStart() {
    int startPixel = 0;
    for(int y = 0; y < video.height / 2 && startPixel == 0; y++) {
      for(int x = 0; x < video.width && startPixel == 0; x++) {
        int loc = x + y * video.width;
        color currentColor = video.pixels[loc];
        
        float r = red(currentColor);
        float g = green(currentColor);
        float b = blue(currentColor);
        
        r = constrain(r, 0, 255);
        g = constrain(g, 0, 255);
        b = constrain(b, 0, 255);
        
        
        // black
        if(r < 40 && g < 40 && b < 40) {
          if((red(video.pixels[loc+5]) > 20 || green(video.pixels[loc+5]) > 20 || blue(video.pixels[loc+5]) > 20) && (red(video.pixels[loc+3200]) < 20 || green(video.pixels[loc+3200]) < 20 || blue(video.pixels[loc+3200]) > 20))
            startPixel = loc;
        }
      }
    }
    pSY = startPixel / video.width;
    pSX = startPixel - video.width * pSY;
  }
  
  /**
   * Sucht nach dem letzten Pixel, womit das Schachbrett endet.
   * Hierfür wird nur die untere Bildhälfte abgesucht, sodass es zu weniger Fehlern/Ungenauigkeiten kommt.
   */
  protected void searchEnd() {
    int lastPixel = video.height * video.width - 1;
    int endPixel = lastPixel;
    for(int y = video.height - 1; y > video.height / 2 && endPixel == lastPixel; y--) {
      for(int x = video.width - 1; x > 0 && endPixel == lastPixel; x--) {
        int loc = x + y * video.width;
        color currentColor = video.pixels[loc];
        
        float r = red(currentColor);
        float g = green(currentColor);
        float b = blue(currentColor);
        
        r = constrain(r, 0, 255);
        g = constrain(g, 0, 255);
        b = constrain(b, 0, 255);
  
        
        // black
        if(r < 40 && g < 40 && b < 40) {
          if((red(video.pixels[loc-5]) > 20 || green(video.pixels[loc-5]) > 20 || blue(video.pixels[loc-5]) > 20) && (red(video.pixels[loc-3200]) < 20 || green(video.pixels[loc-3200]) < 20 || blue(video.pixels[loc-3200]) > 20))
            endPixel = loc;
        }
      }
    }
    pEY = endPixel / video.width;
    pEX = endPixel - video.width * pEY;
  }
  
  /**
   * Berechnet die Differenz der Koordinaten von den beiden gefundenen Begrenzungen.
   */
  protected void calculateBounds() {
    yDif = pEY - pSY;
    xDif = pEX - pSX;
  }
  
  /**
   * Zeichnet das Sichtfeld und die erkannten Figuren.
   */
  public void drawFOV(int x, int y, int w, int h) {
    image(video, x, y, w, h);
    
    float ratioX = (float) w / video.width;
    float ratioY = (float) h / video.height;
        
    strokeWeight(4.0);
    stroke(0);
    
    fill(255, 0, 0);
    ellipse(x + pSX * ratioX, y + pSY * ratioY, 24, 24);
    ellipse(x + pEX * ratioX, y + pEY * ratioY, 24, 24);
    
    for(int i = 0; i < 8; i++) {
      for(int j = 0; j < 8; j++) {
        int fieldID = (8 * i) + j;
        boolean skip = false;
        switch (figureArray[fieldID]) {
          case 1:
            fill(254); //Zur Markierung auf dem Bildschirm
            break;
          case 2:
            fill(139,0,139);
            break;
          case 3:
            fill(0,0,255);
            break;
          case 4:
            fill(255,255,0);
            break;
          case 5:
            fill(255,0,255);
            break;
          case 6:
            fill(0,255,255);
            break;
          case 7:
            fill(220,105,30);
            break;
          case 8:
            fill(224,102,255);
            break;
          case 9:
            fill(139,71,38);
            break;
          case 10:
            fill(139,35,35);
            break;
          case 11:
            fill(0,255,0);
            break;
          case 12:
            fill(255,0,0);
            break;
          default:
            skip = true;
        }
        if (skip)
          continue;
        
        ellipse(x + ((j + 0.5) * (xDif / 8) + pSX) * ratioX, y + ((i + 0.5) * (yDif / 8) + pSY) * ratioY, 24, 24);
      }
    }
  }
  
  
  
  /**
   * Erstellt ein 8x8 int-Array mit Informationen zu den Schachfiguren und ihren Positionen auf dem Brett.
   * @param video das Bild, welches analysiert werden soll
   */
  public void analyse(PImage video) {
    this.video = video;
    if (random(0, 10) > 8)
      calibrate(video);
    
    video.loadPixels();
    
    // Aufteilung in 8 x 8 Felder
    for(int i = 0; i < 8; i++) {
      for(int j = 0; j < 8; j++) {
        // Die Pixel jedes der Felder werden abgescannt, dabei werden der "Anfangspixel und Endpixel" als Referenzpunkte für die Größe und Position des Feldes auf dem Bild genommen.
        for(int y = i * (yDif / 8) + pSY; y < (i + 1) * (yDif / 8) + pSY; y++) {
          //Sorgt dafür, dass auch aus der äußeren Schleife gesprungen werden kann
          boolean shouldBreak = true;
          for(int x = j * (xDif / 8) + pSX; x < (j + 1) * (xDif / 8) + pSX; x++) {
            int fieldID = (8 * i) + j;
            int loc = x + y * video.width;              
            color currentColor = video.pixels[loc];
            
            //RGB Werte werden gespeichert
            float r = red(currentColor);
            float g = green(currentColor);
            float b = blue(currentColor);
            
            //Lichtverhältnisse werden einkalkuliert
            //RGB werden auf einen Wert zwischen 0 und 255 beschränkt
            //r = map(r, 0, whiteDifArray[0], 0, 255); 
            //g = map(g, 0, whiteDifArray[1], 0, 255);
            //b = map(b, 0, whiteDifArray[2], 0, 255);
            r += whiteDifArray[0];
            g += whiteDifArray[1];
            b += whiteDifArray[2];
            
            //Es wird nach dieser bestimmten Farbe gesucht
            if(r > 230 && g > 230 && b > 230) //weiß, KING, WHITE
              figureArray[fieldID] = 1; //Das 8x8 Array bekommt einen Wert entsprechend der Frabe die er gefunden hat, in diesem Fall Weiß und König Weiß
            else if(r > 119 && r < 159 && g < 20 && b > 119 && b < 159) //lila, KING, BLACK
              figureArray[fieldID] = 2;
            else if(r < 20 && g < 20 && b > 230) //blau, QUEEN, WHITE
              figureArray[fieldID] = 3;
            else if(r > 230 && g > 230 && b < 20) //gelb, QUEEN, BLACK
              figureArray[fieldID] = 4;
            else if(r > 230 && g < 20 && b > 230) //purple, ROOK, WHITE
              figureArray[fieldID] = 5;
            else if(r < 20 && g > 230 && b > 230) //türkis, ROOK, BLACK
              figureArray[fieldID] = 6;
            else if(r > 190 && r < 230 && g < 125 && g > 85 && b > 10 && b < 50) //orange, BISHOP, WHITE
              figureArray[fieldID] = 7;
            else if(r > 204 && r < 244 && g > 82 && g < 102 && b > 230) //pink, BISHOP, BLACK
              figureArray[fieldID] = 8;
            else if(r > 119 && r < 159 && g > 15 && g < 55 && b > 15 && b < 55) //dunkelrot, KNIGHT, WHITE
              figureArray[fieldID] = 9;
            else if(r > 119 && r < 159 && g > 51 && g < 91 && b > 18 && b < 58) //braun, KNIGHT, BLACK
              figureArray[fieldID] = 10;
            else if(r < 20 && g > 230 && b < 20) //grün, PAWN, WHITE
              figureArray[fieldID] = 11;
            else if(r > 180 && g < 40 && b < 40)//rot, PAWN, BLACK
              figureArray[fieldID] = 12;
            else {
              figureArray[fieldID] = 0;
              shouldBreak = false;
            }
            
            if (shouldBreak)
              break;
          }
          
          if (shouldBreak)
            break;
        }
      }
    }
    video.updatePixels();
  }
  
  /**
   * Gibt eine Liste aller gefundener Schachfigure zurück. 
   * Hierzu muss zuerst ein Bild analysiert worden sein.
   *
   * @return eine Liste mit allen gefundenen Schachfiguren
   */
  public ArrayList<ChessFigure> getFigures() {
    ArrayList<ChessFigure> figureList = new ArrayList<ChessFigure>();
    
    for(int i = 0; i < figureArray.length; i++) {
      if(figureArray[i] > 0) {
        int posX = i % 8;
        int posY = i / 8;
        ChessFigureColor clr = figureArray[i] % 2 == 0 ? ChessFigureColor.BLACK : ChessFigureColor.WHITE;
        ChessFigureType type = ChessFigureType.PAWN;
        
        switch ((figureArray[i] - 1) / 2) {
          case 0:
            type = ChessFigureType.KING;
            break;
          case 1:
            type = ChessFigureType.QUEEN;
            break;
          case 2:
            type = ChessFigureType.ROOK;
            break;
          case 3:
            type = ChessFigureType.BISHOP;
            break;
          case 4:
            type = ChessFigureType.KNIGHT;
            break;
          case 5:
            type = ChessFigureType.PAWN;
            break;
        }
        
        figureList.add(new ChessFigure(type, clr, (byte) posX, (byte) posY));
      }
    }
    return figureList;
  }

}