#include <WiFi.h>
#include <HTTPClient.h>
#include <Keypad.h>
#include <ArduinoJson.h>
#include <TFT_eSPI.h>  // Library for the TFT screen

// Wi-Fi credentials
#define WIFI_SSID "Ruba"          // Your Wi-Fi SSID
#define WIFI_PASSWORD "0522498155" // Your Wi-Fi Password

// Firestore URL to get the doorbellPassword and update the doorbell state
const String firestoreURL = "https://firestore.googleapis.com/v1/projects/my-smart-doorbell-f6458/databases/(default)/documents/doorbells/123";

// Keypad configuration
const byte ROW_NUM = 4;    // four rows
const byte COLUMN_NUM = 3; // three columns (for 4x3 keypad)
char keys[ROW_NUM][COLUMN_NUM] = {
  {'1', '2', '3'},
  {'4', '5', '6'},
  {'7', '8', '9'},
  {'*', '0', '#'}
};
byte pin_rows[ROW_NUM] = {19, 25, 26, 22};   // connect to the row pinouts
byte pin_column[COLUMN_NUM] = {21, 14, 12};  // connect to the column pinouts
Keypad keypad = Keypad(makeKeymap(keys), pin_rows, pin_column, ROW_NUM, COLUMN_NUM);

// Password variables
String enteredPassword = "";
String doorbellPassword = "";

// TFT display object
TFT_eSPI tft = TFT_eSPI();  // Create TFT object

// Incorrect attempts counter
int incorrectAttempts = 0;

// Doorbell state
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
    delay(1000);  // This is only for WiFi connection
  }
  Serial.println("Connected to WiFi!");

  // Fetch doorbellPassword from Firestore
  fetchDoorbellPassword();
}

void loop() {
  // Continuously check keypad input
  char key = keypad.getKey();
  if (key) {
    Serial.print("Key Pressed: ");
    Serial.println(key);
    enteredPassword += key;  // Append key to enteredPassword
    displayKey(enteredPassword);  // Display the entered password on the screen
  }

  // If password is entered (length 4), check if it matches
  if (enteredPassword.length() == 4) {
    if (enteredPassword == doorbellPassword) {
      // Update Firestore value to 2 (for Access)
      if (updateFirestoreValue(2)) {
        displayState("Access", TFT_GREEN);
      } else {
        displayState("Error", TFT_RED);
      }

      // Reset the incorrect attempt counter
      incorrectAttempts = 0;
    } else {
      // Update Firestore value to 3 (for Denied)
      if (updateFirestoreValue(3)) {
        displayState("Denied", TFT_RED);
      } else {
        displayState("Error", TFT_RED);
      }

      // Increment incorrect attempt counter
      incorrectAttempts++;

      // If incorrect attempts reach 3, update isInDeadState to 1
      if (incorrectAttempts >= 3) {
        // Update Firestore's isInDeadState to 1
        if (updateDeadState(1)) {
          Serial.println("System is now in Dead State!");
        } else {
          Serial.println("Failed to update Dead State.");
        }

        // Reset the incorrect attempts counter
        incorrectAttempts = 0;
      }
    }

    // Reset entered password after each attempt
    enteredPassword = "";
  }

  // Fetch the doorbell state from Firestore (every 5 seconds)
  static unsigned long lastFetchTime = 0;
  if (millis() - lastFetchTime > 5000) {
    fetchDoorbellState();
    lastFetchTime = millis();
  }
}

// Function to fetch the doorbellPassword from Firestore
void fetchDoorbellPassword() {
  HTTPClient http;
  http.begin(firestoreURL);  // Specify Firestore document URL
  http.addHeader("Content-Type", "application/json");

  // Send GET request to fetch the Firestore document
  int httpResponseCode = http.GET();

  if (httpResponseCode == 200) {
    // Parse the response to extract doorbellPassword
    String response = http.getString();
    Serial.println("Firestore response: " + response);  // Debugging the response
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, response);

    // Check if 'doorbellPassword' is present and extract it
    if (doc["fields"]["doorbellPassword"]["stringValue"].isNull()) {
      Serial.println("Error: doorbellPassword not found in Firestore.");
    } else {
      doorbellPassword = doc["fields"]["doorbellPassword"]["stringValue"].as<String>();
      Serial.print("Fetched Doorbell Password: ");
      Serial.println(doorbellPassword);  // Print fetched password for debugging
    }
  } else {
    Serial.print("Failed to fetch doorbell password. HTTP Code: ");
    Serial.println(httpResponseCode);
  }
}

// Function to update Firestore value (doorbellState)
bool updateFirestoreValue(int newValue) {
  HTTPClient http;
  http.begin(firestoreURL);  // Specify Firestore document URL
  http.addHeader("Content-Type", "application/json");

  // Create the JSON payload to update the "doorbellState" field
  String payload = "{\"fields\": {\"doorbellState\": {\"integerValue\": " + String(newValue) + "}," 
                                       "\"doorbellId\": {\"stringValue\": \"123\"}," 
                                       "\"doorbellPassword\": {\"stringValue\": \"" + doorbellPassword + "\"}," 
                                       "\"isInDeadState\": {\"integerValue\": 0}}}";

  // Send PATCH request to update the Firestore document
  int httpResponseCode = http.PATCH(payload);  // Use PATCH for Firestore updates

  if (httpResponseCode == 200) {
    String response = http.getString();
    http.end();
    return true;
  } else {
    String response = http.getString();
    http.end();
    Serial.println("Error updating Firestore value: " + response);
    return false;
  }
}

// Function to update Firestore's isInDeadState field
bool updateDeadState(int newValue) {
  HTTPClient http;
  http.begin(firestoreURL);  // Specify Firestore document URL
  http.addHeader("Content-Type", "application/json");

  // Create the JSON payload to update the "isInDeadState" field
  String payload = "{\"fields\": {\"isInDeadState\": {\"integerValue\": " + String(newValue) + "}}}";

  // Send PATCH request to update the Firestore document
  int httpResponseCode = http.PATCH(payload);  // Use PATCH for Firestore updates

  if (httpResponseCode == 200) {
    String response = http.getString();
    http.end();
    return true;
  } else {
    String response = http.getString();
    http.end();
    return false;
  }
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
  }
}

// Function to display state on TFT screen
void displayState(String state, uint16_t color) {
  tft.fillScreen(TFT_BLACK);  // Clear the screen
  tft.setTextSize(3);         // Set bigger text size
  tft.setTextColor(color);    // Set text color
  tft.setCursor(50, 120);     // Set text position
  tft.print(state);
}

// Function to display the key pressed on TFT screen
void displayKey(String password) {
  tft.fillScreen(TFT_BLACK);  // Clear the screen
  tft.setTextSize(3);         // Set bigger text size
  tft.setTextColor(TFT_WHITE); // Set text color to white
  tft.setCursor(50, 120);     // Set text position
  tft.print("Enter: ");
  tft.print(password);        // Display the entire entered password

  // Always display the default message, even if doorbellState is 0 or 1
  tft.setTextSize(2);        // Set smaller text size for the default message
  tft.setCursor(10, 50);     // Set text position
  tft.print("Press the code or ring the bell");
} 