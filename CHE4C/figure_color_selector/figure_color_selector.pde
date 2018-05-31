import processing.video.*;

Capture cam;
int current = 0;

int index = 0;
color median = 0;
color[] selected = new color[12];
String[] names = {"Bauer Schwarz", "Springer Schwarz", "Laeufer Schwarz", "Turm Schwarz", "Dame Schwarz", "Koenig Schwarz",
                  "Bauer Weiß", "Springer Weiß", "Laeufer Weiß", "Turm Weiß", "Dame Weiß", "Koenig Weiß"};

void setup() {
  size(640, 480, P2D);
  rectMode(CORNERS);
  
  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++)
      println(i, cameras[i]);
    
    cam = new Capture(this, cameras[current]);
    cam.start();
  }
  
  textFont(createFont("Gothic", 28));
}

void exit() {
  PrintWriter output = createWriter("figure_colors.txt");
  for (int n = 0; n < selected.length; n++)
    output.println(hex(selected[n]));
  output.flush();
  output.close();
  super.exit();
}

void draw() {
  if (cam.available() == true)
    cam.read();
  image(cam, 0, 0);
  
  noFill();
  rect(cam.width / 2 - cam.width / 8, cam.height / 2 - cam.height / 8, cam.width / 2 + cam.width / 8, cam.height / 2 + cam.height / 8);
  
  median = getMedianColor(getPixelSubset(cam, cam.width / 2 - cam.width / 8, cam.height / 2 - cam.height / 8, cam.width / 8, cam.height / 8));
  cam.updatePixels();
  fill(median);
  rect(15, 15, 65, 65);
  fill(0);
  textSize(14);
  text("#" + hex(median), 80, 45);
  
  fill(#FFFFFF);
  textSize(28);
  text(names[index], width / 2 - (textWidth(names[index]) / 2), 30);
}

void keyPressed() {
  selected[index] = median;
  if ((key == ENTER || key == RETURN) && index < (selected.length - 1))
    index++;
  if (key == DELETE && index > 0)
    index--;
  
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
public color[] getPixelSubset(PImage image, int x, int y, int w, int h) {
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
public color getMedianColor(color[] data) {
  if (data.length <= 0)
    return 0;
  color[] sorted = sort(data);
  return sorted[sorted.length / 2];
}