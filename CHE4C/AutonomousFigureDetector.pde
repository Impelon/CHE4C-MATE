import processing.video.*;

/**
 * Klasse für die Bilderkennung, welche sich an verschiedene Lichtverhältnisse selbst anpasst.
 * Erhält bei jedem Aufruf einer Analyse ein Bild übergeben, welches es analysiert.
 */
class AutonomousFigureDetector implements FigureDetector {

  protected int figureArray[] = new int[64];
  protected int[] whiteDifArray = {0,0,0};
  protected PImage video;
  
  protected int pSY;
  protected int pSX;
    
  protected int pEY;
  protected int pEX;
  
  protected float yDif;
  protected float xDif;
  
  protected color[] figureColors = new color[12];
  
  /**
   * Erstellt eine Instanz von AutonomousFigureDetector.
   */
  public AutonomousFigureDetector() {
    loadFigureColors();
  }
  
  /**
   * Läd die Farbwerte der Figuren aus einer Datei.
   */
  public void loadFigureColors() {
    String[] lines = loadStrings("figure_colors.txt");
    for (int i = 0; i < min(lines.length, this.figureColors.length); i++)
    	this.figureColors[i] = unhex(lines[i]);
  }
  
  /**
   * Gibt den pixel-array eines rechteckigen Ausschnitts eines Bildes zurück.
   * 
   * @param image das Ursprungsbild
   * @param x die x-Koordinate des Ausschnittes (obere Ecke links)
   * @param y die y-Koordinate des Ausschnittes (obere Ecke links)
   * @param w die Breite des Ausschnittes
   * @param h die Höhe des Ausschnittes
   * @return der pixel-array des Ausschnittes
   */
  protected color[] getPixelSubset(PImage image, int x, int y, int w, int h) {
    PImage subset = image.get(x, y, w, h);
    subset.loadPixels();
    return subset.pixels;
  }
  
  /**
   * Gibt den Median bezüglich der Farben aus einem pixel-array zurück.
   * 
   * @param data der pixel-array
   * @return der Medien der Farben
   */
  protected color getMedianColor(color[] data) {
    if (data.length <= 0)
      return 0;
    color[] sorted = sort(data);
    return sorted[sorted.length / 2];
  }
  
  /**
   * Gibt die Differenz zweier Farben zurück.
   * Der Algorithmus der Farbendifferenz kann verändert werden, damit er den Licht-/Bildverhältnissen eher entspricht.
   * Statt red(c1) - red(c2) wäre so z.B. auch brightness(c1) - brightness(c2) möglich und eine Gewichtung.
   * 
   * @param c1 erste Farbe
   * @param c2 zweite Farbe
   * @return die Differenz
   */
  protected float colorDifference(color c1, color c2) {
    return sqrt(sq(hue(c1) - hue(c2)) + sq(saturation(c1) - saturation(c2)));
    //return sqrt(sq(red(c1) - red(c2)) + sq(green(c1) - green(c2)) + sq(blue(c1) - blue(c2)));
  }
  
  /**
   * {@inheritDoc}
   * Die Kamera benötigt an der Stelle (width/8, height/4) ein weißes Papier zur Kalibration.
   * Weiß hat normalerweise den RGB-Wert (255, 255, 255). Aufgrund von Lichtverhältnissen und Bildrauschen verändern sich aber alle gemessenen Werte. 
   * Diese Veränderung wird hierdurch festgehalten, damit sie später berücksichtigt werden kann.
   */
  @Override
  public void calibrate(PImage video) {
    this.video = video;
    if (video.width == 0 || video.height == 0)
      return;
        
    int x = video.width / 8;
    int y = video.height / 4;
    
    color[] region = this.getPixelSubset(video, video.width / 8 - video.width / 64, video.height / 4 - video.height / 64, 
            video.width / 32, video.height / 32);
    color currentColor = this.getMedianColor(region);
    
    float r = currentColor >> 16 & 0xFF;
    float g = currentColor >> 8 & 0xFF;
    float b = currentColor & 0xFF;
    
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
        
        float r = currentColor >> 16 & 0xFF;
        float g = currentColor >> 8 & 0xFF;
        float b = currentColor & 0xFF;
        
        // black
        if(r < 40 && g < 40 && b < 40) {
          if((red(video.pixels[loc+5]) > 20 || green(video.pixels[loc+5]) > 20 || blue(video.pixels[loc+5]) > 20) && (red(video.pixels[loc+3200]) > 20 || green(video.pixels[loc+3200]) > 20 || blue(video.pixels[loc+3200]) > 20))
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
        
        float r = currentColor >> 16 & 0xFF;
        float g = currentColor >> 8 & 0xFF;
        float b = currentColor & 0xFF;
        
        // black
        if(r < 40 && g < 40 && b < 40) {
          if((red(video.pixels[loc-5]) > 20 || green(video.pixels[loc-5]) > 20 || blue(video.pixels[loc-5]) > 20) && (red(video.pixels[loc-3200]) > 20 || green(video.pixels[loc-3200]) > 20 || blue(video.pixels[loc-3200]) > 20))
            endPixel = loc;
        }
      }
    }
    pEY = endPixel / this.video.width;
    pEX = endPixel - this.video.width * pEY;
  }
  
  /**
   * Berechnet die Differenz der Koordinaten von den beiden gefundenen Begrenzungen.
   */
  protected void calculateBounds() {
    yDif = abs(pEY - pSY);
    xDif = abs(pEX - pSX);
  }
  
  /**
   * Erstellt ein 8x8 int-Array mit Informationen zu den Schachfiguren und ihren Positionen auf dem Brett.
   * 
   * @param video das Bild, welches analysiert werden soll
   */
  @Override
  public void analyse(PImage video) {
    this.video = video;
    if (random(10) > 8)
    	this.calibrate(video);
        
    // Aufteilung in 8 x 8 Felder
    for(int i = 0; i < 8; i++) {
      for(int j = 0; j < 8; j++) {
        // Die Pixel jedes der Felder werden abgescannt, dabei werden der "Anfangspixel und Endpixel" als Referenzpunkte für die Größe und Position des Feldes auf dem Bild genommen.
        
        color[] region = this.getPixelSubset(video, (int) (j * (xDif / 8) + (xDif / 32) + pSX), (int) (i * (yDif / 8) + (yDif / 32) + pSY), 
            (int) (xDif / 16), (int) (yDif / 16));
        color regionMedian = this.getMedianColor(region);
      
        float smallest = Float.MAX_VALUE;
        int index = 0;
        for (int n = 0; n < this.figureColors.length; n++) {
          float difference = this.colorDifference(regionMedian, this.figureColors[n]);
          if (difference < smallest) {
            smallest = difference;
            index = n;
          }
        }
        
        if (smallest <= 40) {
          println(smallest);
        	this.figureArray[(8 * i) + j] = index + 1;
        } else {
          this.figureArray[(8 * i) + j] = 0;
        }
      }
    }
    this.video.updatePixels();
  }
  
  /**
   * Gibt eine Liste aller gefundener Schachfigure zurück. 
   * Hierzu muss zuerst ein Bild analysiert worden sein.
   *
   * @return eine Liste mit allen gefundenen Schachfiguren
   */
  @Override
  public ArrayList<ChessFigure> getFigures() {
    ArrayList<ChessFigure> figureList = new ArrayList<ChessFigure>();
    
    for(int i = 0; i < this.figureArray.length; i++) {
      if(this.figureArray[i] > 0) {
        int posX = i % 8;
        int posY = i / 8;
        ChessFigureColor chessColor = figureArray[i] < 6 ? ChessFigureColor.BLACK : ChessFigureColor.WHITE;
        ChessFigureType type = ChessFigureType.PAWN;
        
        switch ((this.figureArray[i] - 1) % 6) {
        case 1:
          type = ChessFigureType.KNIGHT;
          break;
        case 2:
          type = ChessFigureType.BISHOP;
          break;
        case 3:
          type = ChessFigureType.ROOK;
          break;
        case 4:
          type = ChessFigureType.QUEEN;
          break;
        case 5:
          type = ChessFigureType.KING;
          break;
        }
        
        figureList.add(new ChessFigure(type, chessColor, (byte) posX, (byte) posY));
      }
    }
    return figureList;
  }
  
  /**
   * Zeichnet das Sichtfeld und die erkannten Figuren.
   */
  @Override
  public void drawFOV(int x, int y, int w, int h) {
    image(this.video, x, y, w, h);
    
    float ratioX = (float) w / this.video.width;
    float ratioY = (float) h / this.video.height;
        
    strokeWeight(4.0);
    stroke(0);
    
    fill(255, 0, 0);
    ellipse(x + pSX * ratioX, y + pSY * ratioY, 24, 24);
    ellipse(x + pEX * ratioX, y + pEY * ratioY, 24, 24);
    
    for(int i = 0; i < 8; i++) {
      for(int j = 0; j < 8; j++) {
        int fieldID = (8 * i) + j;
        
        if (this.figureArray[fieldID] == 0)
        	continue;
        
        fill(this.figureColors[this.figureArray[fieldID] - 1]);

        rect(x + (j * (xDif / 8) + (xDif / 32) + pSX) * ratioX, y + (i * (yDif / 8) + (yDif / 32) + pSY) * ratioY, (xDif / 16), (yDif / 16));
        //ellipse(x + ((j + 0.5) * (xDif / 8) + pSX) * ratioX, y + ((i + 0.5) * (yDif / 8) + pSY) * ratioY, 24, 24);
      }
    }
  }

}