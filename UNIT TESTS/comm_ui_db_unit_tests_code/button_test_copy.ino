#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// Wi-Fi credentials
#define WIFI_SSID "M.ghantous"         // Your Wi-Fi SSID
#define WIFI_PASSWORD "0504900168"     // Your Wi-Fi Password

// Firestore URL for reading and updating the document
const String firestoreURL = "https://firestore.googleapis.com/v1/projects/my-smart-doorbell-f6458/databases/(default)/documents/counters/counter";

// Button connected to GPIO 15
#define BUTTON_PIN 15

// Button state variables
int lastButtonState = HIGH;  // Last state of the button
int currentButtonState;      // Current state of the button
unsigned long lastDebounceTime = 0;  
unsigned long debounceDelay = 50;  // Debounce time (milliseconds)

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

  // Initialize button pin
  pinMode(BUTTON_PIN, INPUT_PULLUP);  // Set the button pin as input with pull-up resistor
}

void loop() {
  // Read the state of the button
  currentButtonState = digitalRead(BUTTON_PIN);

  // Check if the button state has changed (debounced)
  if (currentButtonState == LOW && lastButtonState == HIGH) {
    // Button was just pressed, increment the value in Firestore
    delay(debounceDelay);  // Wait for debounce
    updateFirestoreDocument();  // Increment the value in Firestore
  }

  // Save the current button state for the next loop iteration
  lastButtonState = currentButtonState;
}

// Function to update Firestore document
void updateFirestoreDocument() {
  HTTPClient http;
  http.begin(firestoreURL);  // Specify Firestore document URL

  // Add content-type header
  http.addHeader("Content-Type", "application/json");

  // Get the current value from Firestore
  int currentValue = getCurrentValueFromFirestore();
  int newValue = currentValue + 1;  // Increment the value by 1

  // JSON payload to update the value field
  String jsonPayload = "{\"fields\": {\"value\": {\"integerValue\": " + String(newValue) + "}}}";

  // Send the PATCH request with the JSON payload
  int httpResponseCode = http.PATCH(jsonPayload);

  if (httpResponseCode > 0) {
    Serial.print("HTTP Response code: ");
    Serial.println(httpResponseCode);
    Serial.println("Document updated successfully!");
  } else {
    Serial.print("Error on sending PATCH request: ");
    Serial.println(httpResponseCode);
  }

  http.end();
}

// Function to get the current value from Firestore
int getCurrentValueFromFirestore() {
  HTTPClient http;
  // Use the correct Firestore document URL for your counter
  String url = "https://firestore.googleapis.com/v1/projects/my-smart-doorbell-f6458/databases/(default)/documents/counters/counter";
  http.begin(url);  // Specify Firestore document URL
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
    
    // Get the 'value' from the Firestore document (assumed to be under "fields" -> "value" -> "integerValue")
    int currentValue = doc["fields"]["value"]["integerValue"].as<int>();
    http.end();
    return currentValue;
  } else {
    Serial.print("Error fetching document: ");
    Serial.println(httpResponseCode);
    http.end();
    return 0;  // Return 0 in case of an error
  }
}
