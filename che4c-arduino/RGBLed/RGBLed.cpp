/**
 * Library for controlling a 4-pin RGB-LED.
 * 
 * @author Ovidiu Tatar
 * @version 1.0
 */

#include "Arduino.h"
#include "RGBLed.h"

/**
 * Creates a new instance of RGBLed.
 * 
 * @param _redPin output pin-number for controlling the red amount of the led
 * @param _greenPin output pin-number for controlling the green amount of the led
 * @param _bluePin output pin-number for controlling the blue amount of the led
 * @param commonanode whether the led uses a common anode (it uses a common cathode if not)
 */
// colon-syntax for initialisation of constants (const)
RGBLed::RGBLed(byte redPin, byte greenPin, byte bluePin, bool commonanode) :
_redPin(redPin), _greenPin(greenPin), _bluePin(bluePin), _commonanode(commonanode) {
}

/**
 * Runs code to setup the functionality of the led. Run preferably in the main setup-function.
 */
void RGBLed::setup() const {
	pinMode(_redPin, OUTPUT);
	pinMode(_greenPin, OUTPUT);
	pinMode(_bluePin, OUTPUT);
}

/**
 * Sets the color of the led.
 * 
 * @param red the amount of red of the color
 * @param green the amount of green of the color
 * @param blue the amount of blue of the color
 */
void RGBLed::writeColor(int red, int green, int blue) const {
	analogWrite(_redPin, _commonanode ? 255 - red : red);
	analogWrite(_greenPin, _commonanode ? 255 - green : green);
	analogWrite(_bluePin, _commonanode ? 255 - blue : blue);
}

/**
 * Sets the color of the led using a single color-code.
 * 
 * @param color the color-code
 */
void RGBLed::writeColor(unsigned long color) const {
	writeColor((color >> 16) & 255, (color >> 8) & 255, color & 255);
}

