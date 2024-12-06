#include <TFT_eSPI.h>

TFT_eSPI tft = TFT_eSPI(); // Create TFT object

void setup() {
  tft.init();            // Initialize the display
  tft.setRotation(0);    // Set rotation: 0, 1, 2, or 3
  tft.fillScreen(TFT_BLACK);  // Clear screen to black
  tft.setTextColor(TFT_WHITE); // Set text color to white
  tft.drawString("Hello, ST7789!", 10, 10, 2); // Draw text
}

void loop() {
  tft.fillCircle(120, 120, 50, TFT_RED);  // Draw a red circle
  delay(1000);
  tft.fillCircle(120, 120, 50, TFT_BLUE); // Draw a blue circle
  delay(1000);
}
