/**
 * Hardware-spezifische Implementation des SUIfM-Protokolls. 
 * Der Arduino sollte an einer RGB-LED angeschlossen sein,
 * und die Verbindung zu einem Druckknopf besitzen.
 * 
 * Daten werden über die serielle Schnittstelle zurückgesendet.
 */

#include <RGBLed.h>

static const byte RED_PIN = A2;
static const byte GREEN_PIN  = A1;
static const byte BLUE_PIN = A0;

static const byte CONFIRMATION_BUTTON_PIN = 12;

static RGBLed statusLED(RED_PIN, GREEN_PIN, BLUE_PIN, false);

byte controlStatus = 0;
byte toggledCooldown = 0;

/**
 * Sucht im übergebenen null-terminierten Buffer nach Befehlen und versucht diese auszuführen.
 * 
 * @param data null-terminierter Buffer mit SUIfM-Befehlen
 */
void SUIfM_interpretLines(char data[]) {
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
      // SUIfM-Befehle
      case 's': {
        char firstID;
        char secondID;
        long value;
        if (sscanf(data + ++n, " %c%c %li%n", &firstID, &secondID, &value, &skip) != 3) continue;
        switch (firstID) {
          case 'c':
            switch (secondID) {
              case 's':
                setControlStatus((byte) value);
                break;
            }
          break;
        }
        break;
      } case 'g': {
        char firstID;
        char secondID;
        if (sscanf(data + ++n, " %c%c%n", &firstID, &secondID, &skip) != 2) continue;
        switch (firstID) {
          case 'c':
            switch (secondID) {
              case 's':
                Serial.print("cs");
                Serial.println(getControlStatus());
                break;
            }
          break;
        }
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
 * Setzt Pins und den Control-Status auf den Ausgangszustand zurück.
 */
void reset() {
  pinMode(CONFIRMATION_BUTTON_PIN, INPUT_PULLUP);
  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);
  
  controlStatus = 0;
}

void interact() {
  if (digitalRead(CONFIRMATION_BUTTON_PIN) == LOW) {
    if (toggledCooldown == 0) {
      Serial.println("/confirm");
      toggledCooldown = 100;
    }
  } else {
    if (toggledCooldown > 0)
      toggledCooldown--;
  }
  
  switch (controlStatus) {
    case 1: // CALCULATING
      if (millis() % 2000 < 1000)
        statusLED.writeColor(0x000000FF);
      else
        statusLED.writeColor(0x00000000);
      break;
    case 2: // MOVING
      statusLED.writeColor(0x0000FFFF);
      break;
    case 3: // INVALID_BOARD
      statusLED.writeColor(0x00FF0000);
      break;
    case 4: // WAITING_FOR_PLAYER
      if (millis() % 2000 < 1000)
        statusLED.writeColor(0x0000FF00);
      else
        statusLED.writeColor(0x00000000);
      break;
    case 5: // GAME_ENDED
      if (millis() % 5000 < 1000)
        statusLED.writeColor(0x00FF00FF);
      else
        statusLED.writeColor(0x00000000);
      break;
    case 0: // IDLE
    default:
      break;
  }
}

/**
 * Setzt den Control-Status.
 * Dies führt zu einer entsprechenden Verhaltensänderung der LED.
 * 
 * @param state der Control-Status
 */
void setControlStatus(byte state) {
  controlStatus = state;
}

/**
 * Gibt den Control-Status zurück.
 * 
 * @return der Status
 */
long getControlStatus() {
  return controlStatus;
}

