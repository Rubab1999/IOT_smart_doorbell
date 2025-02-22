## Smart Doorbell Project by : Dareen Khair, Ruba Baba & Maged Ghantous.
The Smart Doorbell is a modern IoT solution that enhances home security and convenience. It combines hardware components with a mobile application to provide real-time monitoring and control of your doorbell system.


## Details about the project :

#### On visitor's side:
* you press the button to ring the bell and let the house owner know you are here, the doorbell sends your request to owner with the picture, then you get an answer on screen (accept/deny/auto deny) with a message from owner (text message, this is optional, owner can decide not to send a message so you will get access/deny only).
* The smart doorbell has a red lamp. when there is no internet connection, the lamp will start blinking, to let you know that there is no connection.

#### On house owner's side:
you have a mobile application for monitoring the doorbell, doorbell account.
* Your smart doorbell has a unique id (you get when you buy the doorbell), you can download smart doorbell app, and sign up to create the account for your doorbell (sign up with your email and doorbell id), you get a verification email to verify you email. then the doorbell account is verified and you can login!.
* when someone rings the bell, you get a notification, when you enter the app, you see the visitor's request. you then can choose to give him access/deny, with an option to add a message to the visitor, if 1 minute passes and you didnt give any answer, the app gives automatic deny answer to the visitor.
* The doorbell also has a password, that you can access/update from app, with this password you can enter the house (enter password to the doorbell and if the password is correct it will give you access), if you enter the password incorrectly 3 times, the doorbell wont let you enter a password again, the doorbell in this case handles only visitors.  you can enable password again only from the app!.
* In your doorbell account, you can see a log of today's visitors, each visitor and the exact time he rang the bell. this log gets empty at the end of the day (00:00). you can save any visitor info to history page where you can find info of visitors you saved from all times.  
*  you have a profile page for your smart doorbell, where you can see your doorbell id, doorbell password with ability to change it, button to enable doorbell password in case you wrote password wrong 3 times.
*  when there is no wifi, the app will change to no wifi mode.

## Folder description :
* ESP32: source code for the esp side (firmware).
* smart_doorbell : dart code for our Flutter app.
* UNIT TESTS: tests for individual hardware components (input / output devices)
* PARAMETERS: contains description of configurable parameters
* SECRETS: passwords,keys..
* ASSETS: app icon pic, 3D printed parts used in this project(path).
* DOCUMENTATION: includes updated user story, and documentation file that explains our work with camera/firebase storage problem.
   
## Arduino/ESP32 libraries used in this project :
* #include <TFT_eSPI.h>
* #include <WiFi.h>
* #include <HTTPClient.h>
* #include <Keypad.h>
* #include <ArduinoJson.h>
* #include <driver/i2s.h>
* #include <math.h>

## Hardware we used :
* 1 esp32
* 1 matrix
* 1 1.6 inch COLOR SPI LCD 240X280 (screen)
* 1 4x3 keypad
* max98357 audio amplifier
* 1 button
* 1 small led light

## Connections diagram :
<img width="759" alt="Daigram" src="https://github.com/user-attachments/assets/afd9e20c-7f55-4f5d-a622-3384289da753" />

## Project Poster :
* TODO: until 2/3/25




