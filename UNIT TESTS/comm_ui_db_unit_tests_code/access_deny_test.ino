#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// Wi-Fi credentials
#define WIFI_SSID "M.ghantous"         // Your Wi-Fi SSID
#define WIFI_PASSWORD "0504900168"     // Your Wi-Fi Password

// Firestore URL to get the current value (Firestore document URL)
const String firestoreURL = "https://firestore.googleapis.com/v1/projects/my-smart-doorbell-f6458/databases/(default)/documents/actions/status";

// Pin for the built-in LED (usually GPIO 2 on ESP32)
#define LIGHT_PIN 2

// Blink delay time
unsigned long lastBlinkTime = 0;
unsigned long blinkInterval = 500; // 500ms for blink (LED on for 500ms, off for 500ms)
bool lightState = LOW; // Current state of the light (on/off)
bool isBlinking = false; // State if the light should blink

void setup() {
  // Start serial communication
  Serial.begin(115200);

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi!");

  // Initialize the light pin (Built-in LED)
  pinMode(LIGHT_PIN, OUTPUT);
}

void loop() {
  // Read the current value from Firebase for 'actions/access'
  int actionValue = getActionValueFromFirestore();
  
  Serial.print("Current action value: ");
  Serial.println(actionValue);
  
  // If the value is 1, turn the light ON
  if (actionValue == 1) {
    digitalWrite(LIGHT_PIN, HIGH);  // Turn the light ON
    isBlinking = false;             // Stop blinking
  }
  // If the value is 2, start blinking the light
  else if (actionValue == 2) {
    isBlinking = true;              // Start blinking
  }
  // If the value is any other number, turn the light OFF
  else {
    digitalWrite(LIGHT_PIN, LOW);   // Turn the light OFF
    isBlinking = false;             // Stop blinking
  }

  // Handle blinking logic
  if (isBlinking) {
    unsigned long currentMillis = millis();
    if (currentMillis - lastBlinkTime >= blinkInterval) {
      // Save the last time you blinked the light
      lastBlinkTime = currentMillis;

      // Toggle the light state
      lightState = !lightState;
      digitalWrite(LIGHT_PIN, lightState);  // Turn the light on/off
    }
  }

  // Wait a while before checking the value again
  delay(100); // Small delay for stability
}

// Function to get the current value from Firebase Firestore (for "actions/access")
int getActionValueFromFirestore() {
  HTTPClient http;
  http.begin(firestoreURL);  // Specify Firestore document URL
  http.addHeader("Content-Type", "application/json");

  // Send GET request to fetch current value
  int httpResponseCode = http.GET();
  
  if (httpResponseCode == 200) {
    // Parse the JSON response to extract the current value
    String response = http.getString();
    Serial.println(response);
    
    // Parse JSON using ArduinoJson
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, response);
    
    // Correct access to "value" -> "integerValue"
    int actionValue = doc["fields"]["value"]["integerValue"].as<int>();
    http.end();
    return actionValue;
  } else {
    Serial.print("Error fetching document: ");
    Serial.println(httpResponseCode);
    http.end();
    return -1;  // Return -1 in case of an error (handle it as needed)
  }
}
