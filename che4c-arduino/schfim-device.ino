/**
 * Hardware-spezifische Implementation des SChFiM-Protokolls. 
 * Der Arduino sollte an zwei Stepper-Driver für die jeweilige Achse angeschlossen sein,
 * zwei Mikroschalter für den Reset in die Ausgangsposition besitzen und einen Pin zum Steuern eines Magneten besitzen.
 * 
 * Daten werden über die serielle Schnittstelle zurückgesendet.
 */

#include <Stepper.h>

// 150 mm = 4 Umdrehungen; 1600 Steps = 1 Umdrehung; 1 Step = 0.0234375 mm
static const float STEPSIZE = 0.0234375;
static const byte MAGNET_PIN = 13;

static const byte X_RESET_SWITCH_PIN = 6;
static const byte X_DIR_PIN  = 2;
static const byte X_STEP_PIN = 3;

static const byte Y_RESET_SWITCH_PIN = 7;
static const byte Y_DIR_PIN  = 4; 
static const byte Y_STEP_PIN = 5;

static Stepper xStepper(400, X_DIR_PIN, X_STEP_PIN);
static Stepper yStepper(400, Y_DIR_PIN, Y_STEP_PIN);

unsigned int fieldSize = 20;
unsigned int baseSpeed = 250;

// Anzahl der Figuren in der Ablage
byte figuresInStorage = 0;

byte currentX = 0;
byte currentY = 0;
int distanceX = 0;
int distanceY = 0;
bool magnetEnabeled = false;

/**
 * Sucht im übergebenen null-terminierten Buffer nach Befehlen und versucht diese auszuführen.
 * 
 * @param data null-terminierter Buffer mit SChFiM-Befehlen
 */
void SChFiM_interpretLines(char data[]) {
  int n = 0; 
  while (data[n] != '\0') {
    // finde Befehl
    for (; data[n] != '\0'; n++) {
        if (data[n] == '/') {
          n++;
          break;
        }
    }
    if (data[n] == '\0')
      return;

    // Befehl gefunden
    int skip = 0;
    switch (data[n]) {
      // ChFiM-Befehle
      case 'm': {
        int x1, y1, x2, y2;
        if (sscanf(data + ++n, " %i %i %i %i%n", &x1, &y1, &x2, &y2, &skip) != 4) continue;
        moveFigure(x1, y1, x2, y2);
        break;
      } case 'r': {
        int x1, y1;
        if (sscanf(data + ++n, " %i %i%n", &x1, &y1, &skip) != 2) continue;
        removeFigure(x1, y1);
        break;
      } case 's': {
        char id;
        long value;
        if (sscanf(data + ++n, " %c %li%n", &id, &value, &skip) != 2) continue;
        switch (id) {
          case 'f':
            setFieldSize((unsigned int) value);
            break;
          // SChFiM-Erweiterung
          case 's':
            setBaseSpeed(value);
            break;
        }
        break;
      } case 'g': {
        char firstID;
        char secondID;
        if (sscanf(data + ++n, " %c%c%n", &firstID, &secondID, &skip) != 2) continue;
        switch (firstID) {
          case 'f':
            Serial.print("f");
            Serial.println(getFieldSize());
            break;
          // SChFiM-Erweiterung
          case 's':
            switch (secondID) {
              case 'f':
                Serial.print("sf");
                Serial.println(getFiguresInStorage());
                break;
              case ' ':
                Serial.print("s");
                Serial.println(getBaseSpeed());
            }
            break;
          case 'm':
            Serial.print("m");
            Serial.println(isMagnetEnabeled());
            break;
          case 'c':
            switch (secondID) {
              case 'x':
                Serial.print("cx");
                Serial.println(getCurrentX());
                break;
              case 'y':
                Serial.print("cy");
                Serial.println(getCurrentY());
                break;
            }
            break;
          case 'd':
            switch (secondID) {
              case 'x':
                Serial.print("dx");
                Serial.println(getDistanceToLastX());
                break;
              case 'y':
                Serial.print("dy");
                Serial.println(getDistanceToLastY());
                break;
            }
          break;
        }
        break;
      // SChFiM-Befehle
      } case 'x': {
        resetMotors();
        break;
      }
    }
    n += skip;
    
    // finde Befehlsende
    for (; data[n] != '\0'; n++)
      if (data[n] == '\n')
        break;
  }
}

/**
 * Setzt die Stepper in die Ausgangsposition zurück.
 */
void resetMotors() {
  pinMode(X_RESET_SWITCH_PIN, INPUT);
  pinMode(Y_RESET_SWITCH_PIN, INPUT);
  pinMode(MAGNET_PIN, OUTPUT);
  setStepperSpeed(100);
  disableMagnet();

  while(digitalRead(X_RESET_SWITCH_PIN) == LOW)
    xStepper.step(-1);
  while(digitalRead(Y_RESET_SWITCH_PIN) == LOW)
    yStepper.step(-1);

  // 0, 0 nicht erreichbar, weil Schachbrett versetzt (falsch) eingezeichnet.
  currentX = 2;
  currentY = 2;

  setStepperSpeed(baseSpeed);
}

/**
 * Setzt die Basis-Drehgeschwindigkeit der Stepper in Umdrehungen pro Minute (revolutions per minute).
 * 
 * @param rpm Drehgeschwindigkeit in Umdrehungen pro Minute
 */
void setBaseSpeed(long rpm) {
  baseSpeed = rpm;
}

/**
 * Gibt die Basis-Drehgeschwindigkeit der Stepper in Umdrehungen pro Minute (revolutions per minute) zurück.
 * 
 * @return Drehgeschwindigkeit in Umdrehungen pro Minute
 */
long getBaseSpeed() {
  return baseSpeed;
}

/**
 * Setzt die Drehgeschwindigkeit der Stepper in Umdrehungen pro Minute (revolutions per minute).
 * 
 * @param rpm Drehgeschwindigkeit in Umdrehungen pro Minute
 */
void setStepperSpeed(long rpm) {
  xStepper.setSpeed(rpm);
  yStepper.setSpeed(rpm);
}

/**
 * Schaltet den Magneten ein.
 */
void enableMagnet() {
  digitalWrite(MAGNET_PIN, HIGH);
  magnetEnabeled = true;
}

/**
 * Schaltet den Magneten aus.
 */
void disableMagnet() {
  digitalWrite(MAGNET_PIN, LOW);
  magnetEnabeled = false;
}

/**
 * Gibt zurück, ob der Magnet eingeschaltet ist.
 * 
 * @return ob der Magnet eingeschaltet ist
 */
bool isMagnetEnabeled() {
  return magnetEnabeled;
}

/**
 * Bewegt den Magneten zur angegebenen Ecke.
 * (angefangen vom Schachbrettrand, jedes Feld jeweils nochmals in 4 unterteilt)
 * 
 * @param x x-Koordinate des Eckpunktes
 * @param y y-Koordinate des Eckpunktes
 */
void goTo(byte x, byte y) {
  distanceX = getXDistanceBetween(x, currentX);
  distanceY = getYDistanceBetween(y, currentY);
  if (distanceX != 0)
    xStepper.step(convertToSteps(getXDistanceMillimeters(distanceX)));
  if (distanceY != 0)
    yStepper.step(convertToSteps(getYDistanceMillimeters(distanceY)));
  currentX = x;
  currentY = y;
}

/**
 * Bewegt den Magneten zur angegebenen Ecke unter Berücksichtigung der Kanten.
 * (angefangen vom Schachbrettrand, jedes Feld jeweils nochmals in 4 unterteilt)
 * 
 * @param x x-Koordinate des Eckpunktes
 * @param y y-Koordinate des Eckpunktes
 */
void moveTo(byte x, byte y) {
  goTo(currentX - 1, currentY);
  goTo(currentX, y + 1);
  goTo(x, currentY);
  goTo(currentX, currentY - 1);
}

/**
 * Bewegt eine Figur zum angebenen zum angegebenen Feld.
 * 
 * Zuerst wird der inaktive Magnet zur angegebenen Position bewegt, anschließend der Magnet aktiviert.
 * Die Figur wird entlang der Kanten zur Zielposition bewegt und der Magnet ausgeschaltet.
 * 
 * @param fromX x-Koordinate des Startfeldes
 * @param fromY y-Koordinate des Startfeldes
 * @param toX x-Koordinate des Zielfeldes
 * @param toY y-Koordinate des Zielfeldes
 */
void moveFigure(byte fromX, byte fromY, byte toX, byte toY) {
  setStepperSpeed(baseSpeed);
  disableMagnet();
  goTo(2 * fromX + 3, 2 * fromY + 3);
  enableMagnet();
  moveTo(2 * toX + 3, 2 * toY + 3);
  disableMagnet();
}

/**
 * Entfernt eine Figur vom Spielfeld.
 * 
 * Zuerst wird der inaktive Magnet zur angegebenen Position bewegt, anschließend der Magnet aktiviert.
 * Die Figur wird entlang der Kanten zur Zielposition (am Spielfeldrand) bewegt und der Magnet ausgeschaltet.
 * Die Zielposition wird abhängig von der Anzahl der Figuren in der Ablage berechnet. 
 * 
 * @param fromX x-Koordinate des Startfeldes
 * @param fromY y-Koordinate des Startfeldes
 */
void removeFigure(byte fromX, byte fromY) {
  setStepperSpeed(baseSpeed);
  disableMagnet();
  goTo(2 * fromX + 3, 2 * fromY + 3);
  enableMagnet();
  moveTo(getStorageX(figuresInStorage), getStorageY(figuresInStorage));
  figuresInStorage++;
  disableMagnet();
}

/**
 * Tauscht eine Figur mit einer anderen Figur aus der Ablage.
 * Wenn der gegebene Index kleiner ist als die Anzahl der Figuren in der Ablage,
 * passiert nichts.
 * 
 * @param fromX x-Koordinate des Startfeldes
 * @param fromY y-Koordinate des Startfeldes
 * @param storageIndex Index der Figur in der Ablage
 */
void swapWithStorage(byte fromX, byte fromY, byte storageIndex) {
  setStepperSpeed(baseSpeed);
  if (storageIndex >= getFiguresInStorage())
    return;

  removeFigure(fromX, fromY);
  
  disableMagnet();
  goTo(getStorageX(storageIndex), getStorageY(storageIndex));
  enableMagnet();
  moveTo(fromX, fromY);
  
  disableMagnet();

  goTo(getStorageX(figuresInStorage), getStorageY(figuresInStorage));
  enableMagnet();
  moveTo(getStorageX(storageIndex), getStorageY(storageIndex));
  figuresInStorage--;
  disableMagnet();
}

/**
 * Gibt die x-Eckkoordinate eines bestimmten Indexes in der Ablage zurück.
 * 
 * @param storageIndex Index in der Ablage
 * @return x-Eckkoordinate des Indexes
 */
byte getStorageX(byte storageIndex) {
  if (storageIndex % 16 < 8)
    return (2 * (1 + (storageIndex % 8))) + 1;
  return storageIndex > 16 ? 1 : 19;
}

/**
 * Gibt die y-Eckkoordinate eines bestimmten Indexes in der Ablage zurück.
 * 
 * @param storageIndex Index in der Ablage
 * @return y-Eckkoordinate des Indexes
 */
byte getStorageY(byte storageIndex) {
  if (storageIndex % 16 < 8)
    return storageIndex > 16 ? 1 : 19;
  return (2 * (1 + (storageIndex % 8))) + 1;
}

/**
 * Gibt die Anzahl der Figuren in der Ablage zurück.
 * 
 * @param die Anzahl der Figuren in der Ablage
 */
byte getFiguresInStorage() {
  return figuresInStorage;
}

/**
 * Setzt die Seitenlänge eines einzelnen Schachfeldes.
 * 
 * @param die Seitenlänge eines Schachfeldes
 */
void setFieldSize(unsigned int fSize) {
  fieldSize = fSize / 2;
}

/**
 * Gibt die Seitenlänge eines einzelnen Schachfeldes zurück.
 * 
 * @return die Seitenlänge eines Schachfeldes
 */
unsigned int getFieldSize() {
  return fieldSize * 2;
}

/**
 * Gibt die x-Eckkoordinate der momentanen Position zurück.
 * 
 * @return die x-Koordinate
 */
byte getCurrentX() {
  return currentX;
}

/**
 * Gibt die y-Eckkoordinate der momentanen Position zurück.
 * 
 * @return die y-Koordinate
 */
byte getCurrentY() {
  return currentY;
}

/**
 * Gibt den Abstand auf der x-Achse zur letzten Position in Eckkoordinaten zurück.
 * 
 * @return der x-Abstand
 */
int getDistanceToLastX() {
  return distanceX;
}

/**
 * Gibt den Abstand auf der y-Achse zur letzten Position in Eckkoordinaten zurück.
 * 
 * @return der y-Abstand
 */
int getDistanceToLastY() {
  return distanceY;
}

/**
 * Gibt die Anzahl der Stepper-Schritte, die der angebenen Strecke in Millimetern entsprechen, zurück.
 * 
 * @param distance die Strecke in Milimetern
 * @return die Anzahl der Stepper-Schritte, die der angebenen Strecke entsprechen
 */
int convertToSteps(int distance) {
  return (int) (distance / STEPSIZE);
}

/**
 * Gibt den Abstand zweier x-Koordinaten zurück.
 * 
 * @param x1 erste x-Koordinate
 * @param x2 zweite x-Koordinate
 * @return der Abstand
 */
int getXDistanceBetween(int x1, int x2) {
  return x1 - x2;
}

/**
 * Gibt den Abstand zweier y-Koordinaten zurück.
 * 
 * @param y1 erste y-Koordinate
 * @param y2 zweite y-Koordinate
 * @return der Abstand
 */
int getYDistanceBetween(int y1, int y2) {
  return y1 - y2;
}

/**
 * Gibt den x-Abstand von Eckkoordinaten in Milimetern zurück.
 * 
 * @param x x-Distanz in Eckkoordinaten
 * @return Distanz in Millimetern vom Ursprung
 */
int getXDistanceMillimeters(int x) {
  return x * fieldSize;
}

/**
 * Gibt den y-Abstand von Eckkoordinaten in Milimetern zurück.
 * 
 * @param y y-Distanz in Eckkoordinaten
 * @return Distanz in Millimetern vom Ursprung
 */
int getYDistanceMillimeters(int y) {
  return y * fieldSize;
}

