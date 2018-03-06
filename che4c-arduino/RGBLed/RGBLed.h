/**
 * Library for controlling a 4-pin RGB-LED.
 * 
 * @author Ovidiu Tatar
 * @version 1.0
 */

#ifndef RGBLed_h
#define RGBLed_h

#include "Arduino.h"

/**
 * Class for controlling 4-pin RGB-LED's.
 * Note: A multiplier (resistor) will be needed before connecting the pins to the LED.
 * 
 * @author Ovidiu Tatar
 * @version 1.0
 */
 
class RGBLed {
  public:
    /**
     * Creates a new instance of RGBLed.
     * 
     * @param redPin output pin-number for controlling the red amount of the led
     * @param greenPin output pin-number for controlling the green amount of the led
     * @param bluePin output pin-number for controlling the blue amount of the led
     * @param commonanode whether the led uses a common anode (it uses a common cathode if not)
     */
    RGBLed(byte redPin, byte greenPin, byte bluePin, bool commonanode);

    /**
     * Runs code to setup the functionality of the led. Run preferably in the main setup-function.
     */
    void setup() const;

    /**
     * Sets the color of the led.
     * 
     * @param red the amount of red of the color
     * @param green the amount of green of the color
     * @param blue the amount of blue of the color
     */
    void writeColor(int red, int green, int blue) const;

    /**
     * Sets the color of the led using a single color-code.
     * 
     * @param color the color-code
     */
    void writeColor(unsigned long color) const;
  private:
    byte _redPin;
    byte _greenPin;
    byte _bluePin;
    bool _commonanode;
};

#endif