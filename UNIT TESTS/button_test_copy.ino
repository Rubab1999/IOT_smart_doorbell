#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <driver/i2s.h>
#include <math.h>

// Wi-Fi credentials
#define WIFI_SSID "Ruba"          // Your Wi-Fi SSID
#define WIFI_PASSWORD "0522498155" // Your Wi-Fi Password

// Firestore URL to get the current value (Firestore document URL)
const String firestoreURL = "https://firestore.googleapis.com/v1/projects/my-smart-doorbell-f6458/databases/(default)/documents/actions/status";

// Pin for the button
#define BUTTON_PIN 15  // GPIO 15 for button

// I2S Configurations for sound output (assuming you are using a DAC)
#define I2S_NUM           I2S_NUM_0 // Use I2S Port 0
#define I2S_BCLK_PIN      27       // Bit Clock
#define I2S_LRCLK_PIN     26       // Left-Right Clock (Word Select)
#define I2S_DIN_PIN       25       // Data Input

// Sound configurations
#define SAMPLE_RATE       44100     // 44.1 kHz Sample Rate
#define SINE_FREQUENCY    440       // 440 Hz (A4 Note)

void setup() {
  // Start serial communication
  Serial.begin(115200);
  Serial.println("Starting setup...");

  // Connect to Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi!");

  // Initialize button pin
  pinMode(BUTTON_PIN, INPUT_PULLUP); // Enable internal pull-up resistor

  // I2S Configuration for sound
  i2s_config_t i2s_config = {
    .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_TX),
    .sample_rate = SAMPLE_RATE,
    .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT,
    .channel_format = I2S_CHANNEL_FMT_ONLY_LEFT,
    .communication_format = I2S_COMM_FORMAT_I2S,
    .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,
    .dma_buf_count = 8,
    .dma_buf_len = 64,
    .use_apll = false,
    .tx_desc_auto_clear = true,
    .fixed_mclk = 0
  };

  i2s_pin_config_t pin_config = {
    .bck_io_num = I2S_BCLK_PIN,
    .ws_io_num = I2S_LRCLK_PIN,
    .data_out_num = I2S_DIN_PIN,
    .data_in_num = I2S_PIN_NO_CHANGE
  };

  // Initialize I2S
  i2s_driver_install(I2S_NUM, &i2s_config, 0, NULL);
  i2s_set_pin(I2S_NUM, &pin_config);
  i2s_zero_dma_buffer(I2S_NUM);

  Serial.println("Setup complete!");
}

void loop() {
  // Read button state
  if (digitalRead(BUTTON_PIN) == LOW) { // Button pressed (active low)
    Serial.println("Button pressed! Updating value to 1...");
    
    // Update Firestore value to 1
    if (updateFirestoreValue(1)) {
      Serial.println("Firestore updated successfully!");
    } else {
      Serial.println("Failed to update Firestore.");
    }

    // Generate and play sound
    playSound();

    // Add delay to prevent multiple updates and sound triggers
    delay(1000);
  }
}

// Function to update Firestore value
bool updateFirestoreValue(int newValue) {
  HTTPClient http;
  http.begin(firestoreURL);  // Specify Firestore document URL
  http.addHeader("Content-Type", "application/json");

  // Create the JSON payload
  String payload = "{\"fields\": {\"value\": {\"integerValue\": " + String(newValue) + "}}}";

  // Send PATCH request to update the Firestore document
  int httpResponseCode = http.PATCH(payload);

  if (httpResponseCode == 200) {
    String response = http.getString();
    Serial.println("Response from Firestore: " + response);
    http.end();
    return true;
  } else {
    Serial.print("Error updating value: ");
    Serial.println(httpResponseCode);
    String response = http.getString();
    Serial.println("Response from Firestore: " + response);
    http.end();
    return false;
  }
}

// Function to generate and play sine wave sound
void playSound() {
  const int amplitude = 10000; // Amplitude of sine wave
  const int samples_per_cycle = SAMPLE_RATE / SINE_FREQUENCY;
  static int sample_index = 0;
  int16_t samples[256];

  // Generate sine wave samples
  for (int i = 0; i < 256; i++) {
    samples[i] = (int16_t)(amplitude * sin(2.0 * M_PI * (sample_index++) / samples_per_cycle));
    if (sample_index >= samples_per_cycle) {
      sample_index = 0;
    }
  }

  // Send the samples to I2S to play the sound
  size_t bytes_written;
  i2s_write(I2S_NUM, samples, sizeof(samples), &bytes_written, portMAX_DELAY);
}
