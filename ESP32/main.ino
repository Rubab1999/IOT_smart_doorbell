#include <TFT_eSPI.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <Keypad.h>
#include <ArduinoJson.h>
  // Library for the TFT screen
#include <driver/i2s.h>
#include <math.h>

#define CUSTOM_RED 0xF800 
#define SAMPLE_RATE 16000
#define AMPLITUDE 10000  

#define WIFI_SSID "Ruba"          // Your Wi-Fi SSID
#define WIFI_PASSWORD "0522498155"
#define I2S_WS 12   // LRC on MAX98357A
#define I2S_SD 25   // DIN (serial data)
#define I2S_SCK 27  // BCLK

bool isPlaying = false;
unsigned long startTime = 0;


unsigned long doorbellStartTime = 0;  // Store the time when the button is pressed
bool isPlayingDoorbell = false;  

//#define WIFI_SSID "ICST"          // Your Wi-Fi SSID
//#define WIFI_PASSWORD "arduino123"      // Your Wi-Fi Password

#define LED_PIN 13  // LED connected to GPIO 13
bool ledState = false;  // Track the current LED state for blinking
unsigned long lastBlinkTime = 0;  // Last time the LED state was toggled
const unsigned long blinkInterval = 500; 

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
int wifiStatus = 0;
// TFT display object


TFT_eSPI tft = TFT_eSPI();  // Create TFT object

// Doorbell state
int doorbellState = 0;    // Doorbell state (default to 0)
int lastDoorbellState = 0;  // Track the last doorbell state
String message="";

// Timer variables
unsigned long stateChangeTime = 0;
const unsigned long stateDuration = 5000;  // 5 seconds duration for Access/Denied
bool timerActive = false;
int status=0;
int incorrectAttempts=0;
String imageURL = "http://10.100.102.60/capture"; 


#define BUTTON_PIN 5  // Define button pin (changed to 15)
#define I2S_NUM I2S_NUM_0
#define I2S_BCK_IO 27  // Bit Clock (BCLK)
#define I2S_WS_IO 26   // Word Select (LRC)
#define I2S_DO_IO 25  // Data Input
#define SAMPLE_RATE 44100     // 44.1 kHz Sample Rate
#define SINE_FREQUENCY 440    // 440 Hz (A4 Note)

void playDoorbell() {
    playTone(784, 300);  // "Ding" (G5) - 300ms
    delay(100);          
    playTone(523, 400);  // "Dong" (C5) - 400ms
}

// Function to generate a sine wave and send it to I2S
void playTone(float frequency, int duration_ms) {
    int16_t samples[256];
    size_t bytesWritten;
    float phase = 0.0;
    float phaseIncrement = 2.0 * PI * frequency / SAMPLE_RATE;
    int numSamples = (SAMPLE_RATE * duration_ms) / 1000;  

    for (int i = 0; i < numSamples; i++) {
        samples[i % 256] = (int16_t)(AMPLITUDE * sin(phase));
        phase += phaseIncrement;
        if (phase >= 2.0 * PI) phase -= 2.0 * PI;

        if ((i + 1) % 256 == 0) {
            i2s_write(I2S_NUM_0, samples, sizeof(samples), &bytesWritten, portMAX_DELAY);
        }
    }
}

void setup() {
  // Start serial communication
  Serial.begin(115200);
  Serial.println("Starting setup...");

  // Initialize TFT screen
  tft.init();
  tft.setRotation(3);  // Rotate the screen if needed
  tft.fillScreen(TFT_WHITE);  // Clear the screen

	pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);  // This is only for WiFi connection
    wifiStatus = 0;
     Serial.println("Connecting to Wi-Fi...");
  }
   wifiStatus = 1;
  Serial.println("Connected to WiFi!");

  // Fetch doorbellPassword from Firestore
  fetchDoorbellPassword();

  // Set button pin mode
  pinMode(BUTTON_PIN, INPUT_PULLUP);  // Use internal pull-up resistor

  // Initialize I2S for sound


  // Display the state message when starting up
  displayStateBasedOnDoorbellState(doorbellState,0);  // Display the message corresponding to doorbellState 0
}

// Add a flag to track the doorbell ringing state


void loop() {
    checkWiFiStatus();

  if (WiFi.status() == WL_CONNECTED) {
    if (wifiStatus == 0) {  // Update only if the status changes
      wifiStatus = 1;
      Serial.println("Wi-Fi reconnected!");
    //  digitalWrite(LED_PIN, HIGH);
    }
  } else {
    if (wifiStatus == 1) {  // Update only if the status changes
      wifiStatus = 0;
      Serial.println("Wi-Fi disconnected!");
    }
  }
   if (wifiStatus == 0) {
    // Blink LED when Wi-Fi is disconnected
    if (millis() - lastBlinkTime >= blinkInterval) {
      ledState = !ledState;  // Toggle LED state
      //digitalWrite(LED_PIN, ledState ? HIGH : LOW);
    //  lastBlinkTime = millis();  // Update the last blink time
    }
  } else {
    // Turn LED on when Wi-Fi is connected
    //digitalWrite(LED_PIN, HIGH);
  }
  // Continuously check keypad input
  char key = keypad.getKey();
  if (key && status == 0) {
    Serial.print("Key Pressed: ");
    Serial.println(key);

    if (key == '#') {
      // Remove last character from enteredPassword if it's not empty
      if (enteredPassword.length() > 0) {
        enteredPassword.remove(enteredPassword.length() - 1);
      }
    } else {
      enteredPassword += key;  // Append other keys to enteredPassword
    }

    // Display the entered password on the screen
    displayText("Enter: " + enteredPassword, TFT_BLACK, 2);  // Display the entered password on the screen
  }

  // If password is entered (length 4), check if it matches
  if (enteredPassword.length() == 4) {
    if (enteredPassword == doorbellPassword) {
      // Correct password entered, update Firestore doorbellState to 5 (Access)
      if (updateFirestoreValue(5)|| (wifiStatus==0)) {
        status = 0;
        displayText("Access", TFT_GREEN, 3); 
        startI2S();
        playAccessSound(); // Bigger text for Access
        stateChangeTime = millis();  // Start the 5-second timer
        timerActive = true;
        // Activate the timer
          if(wifiStatus==0){
          doorbellState=0;
        }
        
        
      } else {
        displayText("Error", CUSTOM_RED, 3);
      }

      // Reset incorrect attempt counter on success
      incorrectAttempts = 0;
    } else {
      // Incorrect password entered, update Firestore doorbellState to 6 (Denied)
      if (updateFirestoreValue(6)|| (wifiStatus==0)) {
        displayText("Denied", CUSTOM_RED, 3);
        startI2S();  // Bigger text for Denied
         playDeniedSound();
        stateChangeTime = millis();  // Start the 5-second timer
        timerActive = true;  // Activate the timer
        if(wifiStatus==0){
          doorbellState=0;
        }
        
      } else {
        displayText("Error", CUSTOM_RED, 3);
      }

      // Reset entered password after each attempt
      enteredPassword = "";

      // Incorrect password entered
      incorrectAttempts++;

      // Check if 3 wrong attempts were made
      if (incorrectAttempts >= 3) {
        // Update Firestore to set isInDeadState to 1 (locked out)
        if (updateIsInDeadState(1)) {  // This is where we update the "isInDeadState" field
          displayStateBasedOnDoorbellState(doorbellState, status);
        } else {
          displayText("Error", CUSTOM_RED, 3);
        }

        // Reset incorrect attempt counter
        incorrectAttempts = 0;
      } 
    }


    // Reset entered password after each attempt
    enteredPassword = "";
  }

  // Check if the button is pressed and doorbellState is 0
    if (digitalRead(BUTTON_PIN) == LOW) {
        if (doorbellState == 0 && !isPlayingDoorbell) {
            // First press - trigger the doorbell ringing
        doorbellState = 1;
        updateFirestoreValue(doorbellState);  
        displayText("Ringing", TFT_BLACK, 3);
        isPlayingDoorbell = true;
        startTime = millis();  // Start timer

        startI2S();  // Start I2S only when button is pressed
        playDoorbell();   // Record the start time

    if (isPlayingDoorbell) {
        if (millis() - startTime < 10000) {
        Serial.println("🔇 Stopping sound...");
        isPlayingDoorbell = false;
        stopI2S(); // Play sound for 3 seconds
        } else {
            isPlayingDoorbell = false;  // Stop sound
            Serial.println("Sound Stopped!");
        }
    }
        } 
    }


  // Fetch the doorbell state from Firestore (every 5 seconds)
  static unsigned long lastFetchTime = 0;
  if (millis() - lastFetchTime > 5000) {
    fetchDoorbellState();  // Fetch the latest doorbellState value from Firestore
    fetchIsInDeadState();
    fetchDoorbellPassword();
    lastFetchTime = millis();
  }

  // Always update display according to the doorbellState value
  if (doorbellState != lastDoorbellState) {
    displayStateBasedOnDoorbellState(doorbellState, status);
    lastDoorbellState = doorbellState;  // Update the last state
  }

  // Reset doorbellState to 0 after 5 seconds
  if (timerActive && millis() - stateChangeTime >= stateDuration) {
    updateFirestoreValue(0);  // Reset state to 0
    doorbellState = 0;        // Update local state variable
    displayStateBasedOnDoorbellState(doorbellState, status);
    
    timerActive = false;      // Deactivate the timer
  }
  // Check if isInDeadState has changed from 1 to 0
  static int lastStatus = 1;  // Store the last status value
  if (lastStatus == 1 && status == 0) {
  displayText("                      Enter Code \n    or \n     Ring Bell", TFT_BLACK, 3);  }
  lastStatus = status;  // Update the last status value
}

// Function to trigger the camera and take a picture
void takePicture() {
  // Assuming you have an image capture function for your camera
  // You will need to write or call a function that captures an image
  // For example:
  // camera.capture();  // Call the camera's capture method (replace with actual function)

  Serial.println("Picture captured!");

  // You can save the image or upload it to a server here
}


// Function to display state based on doorbellState value
// Function to display state based on doorbellState and isInDeadState values
void displayStateBasedOnDoorbellState(int doorbellState, int status) {
  // Check if the doorbell state is 0 and the isInDeadState is 1
  if (doorbellState == 0 && status == 1) {
    displayText("         Door Locked\n      Ring the Bell", TFT_BLACK, 2);  // Display "Door Locked. Ring the Bell"
  } 
  // Check if both doorbellState and isInDeadState are 0
  else if (doorbellState == 0 && status == 0) {
    displayText("                           Enter Code \n    or \n     Ring Bell", TFT_BLACK, 3);  // Display "Enter the code or ring the bell"
  }
  // Handle other doorbell states
  else {
    switch (doorbellState) {
      case 1:
        displayText("Ringing", TFT_BLACK, 3);  // Show "Ringing"
        break;
      case 2:
        fetchMessageFromFirestore();
        displayText("Access " + message, TFT_GREEN, 3);  // Show "Access"
        break;
      case 3:
      fetchMessageFromFirestore();
        displayText("Denied " + message, CUSTOM_RED, 3);  // Show "Denied"
        break;
      case 5:
        displayText("Access", TFT_GREEN, 3);  // Access (new state)
        break;
      case 4:
         displayText("No answer, deny", TFT_BLACK, 3);
         break;
      case 6:
        displayText("Denied", CUSTOM_RED, 3);   // Denied (new state)
        break;
      default:
        displayText("Unknown State", TFT_BLACK, 2);  // Show "Unknown State"
        break;
    }
  }
}

// Function to display text on the screen
void displayText(String text, uint16_t color, int textSize) {
    tft.fillScreen(TFT_WHITE);  // Clear the screen
    tft.setTextSize(textSize);  // Set text size
    tft.setTextColor(color);    // Set text color

    int textWidth = tft.textWidth(text);  // Get text width
    int screenWidth = tft.width();  // Get screen width
    int screenHeight = tft.height();  // Get screen height

    int centerX = (screenWidth - textWidth) / 2;  // Center X
    int centerY = (screenHeight - (8 * textSize)) / 2;  // Center Y

    tft.setCursor(centerX, centerY);  // Set centered cursor
    tft.print(text);  // Display the text
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

// Function to fetch the doorbellState from Firestore
void fetchDoorbellState() {
  HTTPClient http;
  http.begin(firestoreURL);  // Specify Firestore document URL
  http.addHeader("Content-Type", "application/json");

  // Send GET request to fetch the Firestore document
  int httpResponseCode = http.GET();

  if (httpResponseCode == 200) {
    String response = http.getString();
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, response);

    // Extract the doorbellState value from the JSON response
    doorbellState = doc["fields"]["doorbellState"]["integerValue"].as<int>();
  } else {
    Serial.print("Failed to fetch doorbell state. HTTP Code: ");
    Serial.println(httpResponseCode);
  }
}

// Function to update doorbellState field in Firestore
void fetchMessageFromFirestore() {
    HTTPClient http;
    http.begin(firestoreURL);  // Specify Firestore document URL
    http.addHeader("Content-Type", "application/json");

    // Send GET request to fetch the Firestore document
    int httpResponseCode = http.GET();

    if (httpResponseCode == 200) {
        String response = http.getString();
        DynamicJsonDocument doc(1024);
        deserializeJson(doc, response);

        // Extract the message field from the JSON response
        if (doc.containsKey("fields") && doc["fields"].containsKey("message")) {
            message = doc["fields"]["message"]["stringValue"].as<String>();
        } else {
            Serial.println("❌ 'message' field not found in Firestore response!");
        }
    } else {
        Serial.print("❌ Failed to fetch message. HTTP Code: ");
        Serial.println(httpResponseCode);
    }

    http.end();
    return ;
}


// Function to update doorbellState field in Firestore
bool updateFirestoreValue(int newValue) {
  HTTPClient http;
  http.begin(firestoreURL);  // Specify Firestore document URL
  http.addHeader("Content-Type", "application/json");

  // Create the JSON payload to update the "doorbellState" field
String payload = "{\"fields\": {"
                 "\"doorbellState\": {\"integerValue\": " + String(newValue) + "},"
                 "\"doorbellId\": {\"stringValue\": \"123\"},"
                 "\"doorbellPassword\": {\"stringValue\": \"" + doorbellPassword + "\"},"
                 "\"isInDeadState\": {\"integerValue\": " + String(status) + "},"
                 "\"imageURL\": {\"stringValue\": \"" + imageURL + "\"}"
                 "}}";


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


  // Send PATCH request to update the Firestore document

// Function to fetch the isInDeadState value from Firestore
void fetchIsInDeadState() {
  HTTPClient http;
  http.begin(firestoreURL);  // Specify Firestore document URL
  http.addHeader("Content-Type", "application/json");

  // Send GET request to fetch the Firestore document
  int httpResponseCode = http.GET();

  if (httpResponseCode == 200) {
    String response = http.getString();  // Get the response
    DynamicJsonDocument doc(1024);  // Create a JSON document to store the response
    deserializeJson(doc, response);  // Deserialize the response

    // Extract the isInDeadState value from the response
    if (doc["fields"]["isInDeadState"]["integerValue"].isNull()) {
      Serial.println("Error: isInDeadState not found in Firestore.");
    } else {
      status = doc["fields"]["isInDeadState"]["integerValue"].as<int>();  // Store the value in status variable
      Serial.print("Fetched isInDeadState: ");
      Serial.println(status);  // Print for debugging
    }
  } else {
    Serial.print("Failed to fetch isInDeadState. HTTP Code: ");
    Serial.println(httpResponseCode);
  }

  http.end();  // Close the HTTP connection
}


// Function to update isInDeadState field in Firestore while preserving other fields
bool updateIsInDeadState(int newValue) {
  status = newValue;
  HTTPClient http;
  http.begin(firestoreURL);  // Specify Firestore document URL
  http.addHeader("Content-Type", "application/json");
  doorbellState=0;
  // Create the JSON payload to update the "isInDeadState" field, while preserving other fields
String payload = "{\"fields\": {"
                 "\"isInDeadState\": {\"integerValue\": " + String(newValue) + "},"
                 "\"doorbellId\": {\"stringValue\": \"123\"},"
                 "\"doorbellPassword\": {\"stringValue\": \"" + doorbellPassword + "\"},"
                 "\"doorbellState\": {\"integerValue\": " + String(doorbellState) + "},"
                 "\"imageURL\": {\"stringValue\": \"" + imageURL + "\"}"
                 "}}";


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

bool updateFirestoreImage() {
  HTTPClient http;
  http.begin(firestoreURL);  // Specify Firestore document URL
  http.addHeader("Content-Type", "application/json");
  fetchDoorbellState();  // Fetch the latest doorbellState value from Firestore0

  // Create the JSON payload to update the "doorbellState" and "imageURL" fields
  String payload = "{\"fields\": {\"doorbellState\": {\"integerValue\": " + String(doorbellState) + "},"
                                       "\"doorbellId\": {\"stringValue\": \"123\"},"
                                       "\"doorbellPassword\": {\"stringValue\": \"" + doorbellPassword + "\"},"
                                       "\"isInDeadState\": {\"integerValue\": " + String(status) + "},"
                                       "\"imageURL\": {\"stringValue\": \"" + imageURL + "\"}}}";

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




// Function to generate "Ding-Dong" sound





// Function to check Wi-Fi status and control LED
void checkWiFiStatus() {
    if (WiFi.status() == WL_CONNECTED) {
        if (wifiStatus == 0) {  
            wifiStatus = 1;
            Serial.println("Wi-Fi reconnected!");
        }
        digitalWrite(LED_PIN, HIGH);  // LED ON when connected
    } else {
        if (wifiStatus == 1) {  
            wifiStatus = 0;
            Serial.println("Wi-Fi disconnected!");
        }
        // Blink LED when Wi-Fi is disconnected
        if (millis() - lastBlinkTime >= blinkInterval) {
            ledState = !ledState;
            digitalWrite(LED_PIN, ledState ? HIGH : LOW);
            lastBlinkTime = millis();
        }
    }
}

















// 🛠️ Start I2S ONLY when the button is pressed
void startI2S() {
    Serial.println("🔊 Initializing I2S...");

    i2s_config_t i2s_config = {
        .mode = i2s_mode_t(I2S_MODE_MASTER | I2S_MODE_TX),
        .sample_rate = SAMPLE_RATE,
        .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT,
        .channel_format = I2S_CHANNEL_FMT_RIGHT_LEFT,
        .communication_format = (i2s_comm_format_t)(I2S_COMM_FORMAT_I2S | I2S_COMM_FORMAT_I2S_MSB),
        .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,
        .dma_buf_count = 8,
        .dma_buf_len = 64,
        .use_apll = false,
        .tx_desc_auto_clear = true
    };

    i2s_pin_config_t pin_config = {
        .bck_io_num = I2S_SCK,
        .ws_io_num = I2S_WS,
        .data_out_num = I2S_SD,
        .data_in_num = I2S_PIN_NO_CHANGE
    };

    i2s_driver_install(I2S_NUM_0, &i2s_config, 0, NULL);
    i2s_set_pin(I2S_NUM_0, &pin_config);
    i2s_set_clk(I2S_NUM_0, SAMPLE_RATE, I2S_BITS_PER_SAMPLE_16BIT, I2S_CHANNEL_STEREO);
}

// 🛠️ Stop I2S COMPLETELY after 3 seconds to prevent noise
void stopI2S() {
    Serial.println("🔇 Disabling I2S...");
    i2s_driver_uninstall(I2S_NUM_0);  // Completely turn off I2S
}

void playAccessSound() {
    Serial.println("🔓 Access Granted! Playing Success Sound...");
    
    playTone(523, 150);  // "Do" (C5) - 150ms
    delay(50);
    playTone(659, 150);  // "Re" (E5) - 150ms
    delay(50);
    playTone(784, 150);  // "Mi" (G5) - 150ms
    delay(50);
    stopI2S();

    Serial.println("✅ Access Sound Completed.");
}

void playDeniedSound() {
    Serial.println("🚫 Access Denied! Playing Error Sound...");
    
    playTone(200, 150);  // Low "Bzzt" (G3) - 150ms
    delay(50);
    playTone(200, 150);  // Second "Bzzt" - 150ms
    delay(50);
     stopI2S();
    
    Serial.println("❌ Denied Sound Completed.");
}

















