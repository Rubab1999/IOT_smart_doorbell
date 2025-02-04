#include <Keypad.h>

// Define keypad size
const byte ROWS = 4; // Four rows
const byte COLS = 3; // Three columns

// Define the keymap
char keys[ROWS][COLS] = {
  {'1', '2', '3'},
  {'4', '5', '6'},
  {'7', '8', '9'},
  {'*', '0', '#'}
};

// Connect keypad ROW pins to these GPIOs on the ESP32
byte rowPins[ROWS] = {12, 13, 14, 15};

// Connect keypad COLUMN pins to these GPIOs on the ESP32
byte colPins[COLS] = {18, 19, 21};

// Create the Keypad object
Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

void setup() {
  Serial.begin(115200);
  Serial.println("Keypad Test");
}

void loop() {
  char key = keypad.getKey(); // Read the key press

  if (key) { // If a key is pressed
    Serial.print("Key pressed: ");
    Serial.println(key);
  }
}