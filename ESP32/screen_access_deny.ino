#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <TFT_eSPI.h>  // Library for the TFT screen

// Wi-Fi credentials
#define WIFI_SSID "Ruba"          // Your Wi-Fi SSID
#define WIFI_PASSWORD "0522498155" // Your Wi-Fi Password

// Firestore URL to get the doorbellState
const String firestoreURL = "https://firestore.googleapis.com/v1/projects/my-smart-doorbell-f6458/databases/(default)/documents/doorbells/123";

// TFT display object
TFT_eSPI tft = TFT_eSPI();  // Create TFT object

// Variables to store the doorbell state
int doorbellState = -1;

void setup() {
  // Start serial communication
  Serial.begin(115200);
  Serial.println("Starting setup...");

  // Initialize TFT screen
  tft.init();
  tft.setRotation(3);  // Rotate the screen if needed
  tft.fillScreen(TFT_BLACK);  // Clear the screen

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi!");

  // Fetch doorbellState from Firestore initially
  fetchDoorbellState();
}

void loop() {
  // Fetch doorbellState from Firestore every 5 seconds
  fetchDoorbellState();

  // If doorbellState is 2, display "Access" on the screen
  if (doorbellState == 2) {
    tft.fillScreen(TFT_BLACK);  // Clear the screen
    tft.setTextSize(3);         // Set bigger text size
    tft.setTextColor(TFT_GREEN); // Set text color to green
    tft.setCursor(50, 120);      // Set text position on the screen
    tft.print("Access");
    Serial.println("Access granted!");  // Print message on Serial Monitor
  }
  // If doorbellState is 3, display "Denied" on the screen
  else if (doorbellState == 3) {
    tft.fillScreen(TFT_BLACK);  // Clear the screen
    tft.setTextSize(3);         // Set bigger text size
    tft.setTextColor(TFT_RED);  // Set text color to red
    tft.setCursor(50, 120);      // Set text position on the screen
    tft.print("Denied");
    Serial.println("Access denied!");  // Print message on Serial Monitor
  }

  // Wait before checking again
  delay(5000);
}

// Function to fetch the doorbellState from Firestore
void fetchDoorbellState() {
  HTTPClient http;
  http.begin(firestoreURL);  // Specify Firestore document URL
  http.addHeader("Content-Type", "application/json");

  // Send GET request to fetch the Firestore document
  int httpResponseCode = http.GET();

  if (httpResponseCode == 200) {
    // Parse the response to extract doorbellState
    String response = http.getString();
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, response);

    // Extract the doorbellState value from the JSON response
    doorbellState = doc["fields"]["doorbellState"]["integerValue"].as<int>();

    Serial.print("Fetched doorbellState: ");
    Serial.println(doorbellState);  // Print the fetched state (for debugging)
  } else {
    Serial.print("Failed to fetch doorbell state. HTTP Code: ");
    Serial.println(httpResponseCode);
  }
}
