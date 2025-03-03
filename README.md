🎙️ Real-Time Speech Translation App

An iOS application that enables real-time speech transcription, translation, and text-to-speech playback using Apple's Speech, Translation, and AVFoundation frameworks. Supports multiple languages and Bluetooth speaker connectivity.

📌 Features

✅ Real-time speech transcription using Apple's Speech API
✅ Instant translation into a selected target language
✅ Text-to-Speech (TTS) playback of the translated text
✅ Bluetooth speaker support for translated audio
✅ Offline language translation support (when languages are downloaded)

🚀 Installation & Setup

Follow these steps to set up the project on your Mac and run it on your iPhone.

🔹 1. Prerequisites

Ensure you have the following installed on your Mac:
macOS Monterey (or later)
Xcode 15 (or later)
An Apple Developer Account (needed to run on a physical device)
A physical iPhone (Real-time speech recognition does not work in the simulator)

🔹 2. Clone the Repository

Open Terminal and run:
git clone https://github.com/Ant-Smalls/ClarityAudioApp.git
cd AudioPlayer

🔹 3. Open in Xcode

Open Xcode
Click File > Open, then select the project folder
Open AudioPlayer.xcodeproj

🔹 4. Link Your Apple Developer Account

In Xcode, go to Signing & Capabilities
Select your team under "Signing"
Ensure "Automatically manage signing" is enabled
If prompted, sign into your Apple Developer Account

🔹 5. Enable Required Permissions

This app requires Microphone, Speech Recognition, and Bluetooth permissions.
Go to Info.plist and add:
<key>NSSpeechRecognitionUsageDescription</key>
<string>App requires access to speech recognition for real-time transcription.</string>

<key>NSMicrophoneUsageDescription</key>
<string>App requires access to the microphone for voice input.</string>

<key>NSBluetoothAlwaysUsageDescription</key>
<string>App requires Bluetooth access to connect to external speakers.</string>

🔹 6. Build & Run on Your iPhone

** Make Sure you are on Developer Mode (Settings -> Privacy and Security -> Developer Mode) **

Plug in your iPhone
Select your iPhone as the build target in Xcode
Click Run (▶️) to install and launch the app

📥 Downloading Offline Language Packs

To use offline translation, download the required language packs:
Go to Settings → Apps → Translate -> Downloaded languages

Tap install:
English (en)
Spanish (es)
German (de)
Portuguese (Brazil) (pt-BR)
Japanese (ja)

Restart your iPhone to ensure the system registers them.

🔊 Connecting a Bluetooth Speaker

Turn on your Bluetooth speaker
Open Settings → Bluetooth
Pair your iPhone with the speaker
Open the app, and play translated audio — it should now output through your Bluetooth speaker.

📱 Using the App

Open the app
Select the input & output language
Tap "Start Record" and start speaking
Tap "Stop Recording" to finalize transcription & translation
The translated and input text will be displayed in real time
Audio will be generated and automatically played 

🛠 Troubleshooting

⚠️ Play Translated Audio Button does NOT work

⚠️ NOT SURE if the audio will play when no speaker is connected to 

⚠️ Online language support is NOT AVAILABLE, has to be downloaded all languages

⚠️ Translation Failed (Offline Models Not Found)
Ensure the correct language codes are being used (en, es, de, pt, ja)
Go to App > Translate -> Downloaded languages and check if the language packs are downloaded
Restart your iPhone after downloading language packs

⚠️ No Sound from Bluetooth Speaker
Ensure your iPhone is connected to the speaker
Go to Control Center > Audio Output and select the Bluetooth speaker
Ensure volume is turned up on both devices
