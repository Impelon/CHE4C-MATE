/**
 * Hauptdatei des Programms af dem Arduino. Wartet auf Befehle über die serielle Schnittstelle.
 */

static const int BUFFER_LENGTH = 33;

/**
 * Funktion, welche bei Ausführung des Programms zuerst ausgeführt wird.
 */
void setup() {
  Serial.begin(9600);
  while (!Serial);
  randomSeed(analogRead(0));

  // SChFiM initialisieren
  setBaseSpeed(250);
  resetMotors();
  // SUIfM initialisieren
  reset();
}

/**
 * Funktion, welche nach dem Startvorgang wiederholt ausgeführt wird.
 */
void loop() {
  // SUIfM-Interaktion
  interact();
}

/**
 * Funktion, welche ausgeführt wird, falls Daten über die serielle Schnittstelle empfangen werden können.
 * Liest eine Zeile und gibt diese zur Interpretation durch SChFiM und SUIfM weiter.
 */
void serialEvent() {
  char input[BUFFER_LENGTH];
  
  int endIndex = Serial.readBytesUntil('\n', input, BUFFER_LENGTH - 2);

  input[endIndex] = '\n';
  input[endIndex + 1] = '\0';

  SChFiM_interpretLines(input);
  SUIfM_interpretLines(input);
}

