#include <driver/i2s.h>

#define I2S_NUM I2S_NUM_0
#define I2S_BCK_IO 27  // Bit Clock (BCLK)
#define I2S_WS_IO 26   // Word Select (LRC)
#define I2S_DO_IO 25   // Data Out (DIN)

void setup() {
  // Configure I2S
  i2s_config_t i2s_config = {
    .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_TX), // Master mode, TX only
    .sample_rate = 44100,                               // 44.1kHz sample rate
    .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT,       // 16-bit audio
    .channel_format = I2S_CHANNEL_FMT_RIGHT_LEFT,       // Stereo
    .communication_format = I2S_COMM_FORMAT_I2S,       // I2S standard
    .intr_alloc_flags = 0,                              // Default interrupt flags
    .dma_buf_count = 8,                                 // Number of buffers
    .dma_buf_len = 64                                   // Size of each buffer
  };

  // Configure I2S pins
  i2s_pin_config_t pin_config = {
    .bck_io_num = I2S_BCK_IO,
    .ws_io_num = I2S_WS_IO,
    .data_out_num = I2S_DO_IO,
    .data_in_num = I2S_PIN_NO_CHANGE // No input needed
  };

  // Install and start I2S driver
  i2s_driver_install(I2S_NUM, &i2s_config, 0, NULL);
  i2s_set_pin(I2S_NUM, &pin_config);
}

void loop() {
  // Example: Generate a sine wave for testing
  size_t bytes_written;
  static int16_t sample_data[64];
  static int phase = 0;
  for (int i = 0; i < 64; i++) {
    sample_data[i] = (int16_t)(2000 * sin((phase++) * 2 * PI / 64));
  }
  i2s_write(I2S_NUM, sample_data, sizeof(sample_data), &bytes_written, portMAX_DELAY);
}
