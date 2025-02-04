#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <driver/i2s.h>

// Wi-Fi credentials
#define WIFI_SSID "Ruba"         // Your Wi-Fi SSID
#define WIFI_PASSWORD "0522498155"     // Your Wi-Fi Password

// Firestore URL to get the current value (Firestore document URL)
const String firestoreURL = "https://firestore.googleapis.com/v1/projects/my-smart-doorbell-f6458/databases/(default)/documents/actions/status";

// I2S Pin configuration
#define I2S_BCK_IO 27  // Bit Clock (BCLK)
#define I2S_WS_IO 26   // Word Select (LRC)
#define I2S_DO_IO 25   // Data Out (DIN)

#define SAMPLE_RATE 44100   // 44.1kHz sample rate for audio
#define FREQUENCY 440      // Frequency of sound (440 Hz = A4 note)

bool soundPlaying = false;  // Flag to check if sound is playing

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

  // Configure I2S for sound output (use pins for I2S)
  i2s_config_t i2s_config = {
    .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_TX),      // Master mode, transmit only
    .sample_rate = SAMPLE_RATE,                 // 44.1 kHz sample rate
    .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT, // 16-bit audio
    .channel_format = I2S_CHANNEL_FMT_RIGHT_LEFT, // Stereo
    .communication_format = I2S_COMM_FORMAT_I2S, // Standard I2S format
    .intr_alloc_flags = 0,                      // Default interrupt flags
    .dma_buf_count = 8,                         // Number of buffers
    .dma_buf_len = 64                           // Size of each buffer
  };

  i2s_pin_config_t pin_config = {
    .bck_io_num = I2S_BCK_IO,
    .ws_io_num = I2S_WS_IO,
    .data_out_num = I2S_DO_IO,
    .data_in_num = I2S_PIN_NO_CHANGE            // No input required
  };

  // Install I2S driver and set pin configuration
  i2s_driver_install(I2S_NUM_0, &i2s_config, 0, NULL);
  i2s_set_pin(I2S_NUM_0, &pin_config);
}

void loop() {
  // Get the current action value from Firestore
  int actionValue = getActionValueFromFirestore();
  
  Serial.print("Current action value: ");
  Serial.println(actionValue);
  
  // If value is 1, play sound. Otherwise, stop sound.
  if (actionValue == 1 && !soundPlaying) {
    playSound(); // Play sound for value 1
    soundPlaying = true;
  } else if (actionValue != 1 && soundPlaying) {
    stopSound(); // Stop sound for any value other than 1
    soundPlaying = false;
  }

  delay(1000); // Wait for a second before checking again
}

// Function to get the current action value from Firebase Firestore (for "actions/access")
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
    
    // Access the "value" field
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

// Function to play a 440 Hz sine wave sound (A4 note)
void playSound() {
  size_t bytes_written;
  static int16_t sample_data[64];
  static int phase = 0;
  
  // Generate a 440Hz sine wave (A4 note)
  for (int i = 0; i < 64; i++) {
    sample_data[i] = (int16_t)(2000 * sin((phase++) * 2 * PI / (SAMPLE_RATE / FREQUENCY)));  // 440Hz sine wave
  }

  // Write sine wave to I2S
  i2s_write(I2S_NUM_0, sample_data, sizeof(sample_data), &bytes_written, portMAX_DELAY);
}

// Function to stop sound (halt the playback)
void stopSound() {
  // We can stop the sound by writing silence data or by halting the I2S stream.
  // No sound is played by stopping the I2S output.

  // Stop the current sound output (no data is sent)
  i2s_zero_dma_buffer(I2S_NUM_0);  // This function halts I2S transmission and effectively stops the sound
}
