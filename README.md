# HAL 9000

A HAL 9000-inspired chat app in a single file. Double-click `HAL Standalone.html` and it runs in your browser. There's nothing to install, and it works offline on Windows, Mac, Linux and Raspberry Pi.

![HAL screenshot](<HAL - screenshot.png>)

## What he does

- Talks out loud. He uses your computer's voice when there is one. On computers whose browser has no voices (Chromium on a Raspberry Pi, most Linux), he uses a voice engine built into the file.
- Sings Daisy Bell with his own vocal synthesizer. Press Stop or Esc to make him stop.
- Refuses to open the pod bay doors.
- Plays chess.
- Memory core: pull his modules out and he winds down. Push them back in and he thanks you.
- Gives ship status and predicts the AE-35 unit fault.
- Remembers your name.

## Optional AI brain

Click **AI** in the top bar to download a small AI model (Llama 3.2 3B, about 2 GB, one time only) that runs in the browser on your graphics card. It needs Chrome or Edge and WebGPU. Raspberry Pis can't run it, so there HAL uses his built-in personality.

## Fully offline AI (Windows)

`HAL Offline` holds the same app plus a local copy of the AI engine. Run `Get HAL Brain.bat` once to download the model into `HAL Offline/brain/`, then start HAL with `Start HAL.bat`. After that it needs no internet, and you can copy the folder to another PC.

## Credits

The built-in voice is [eSpeak](https://espeak.sourceforge.net/) via [meSpeak](https://www.masswerk.at/mespeak/) by Norbert Landsteiner (GPL). The AI engine is [WebLLM](https://github.com/mlc-ai/web-llm) (Apache-2.0).

---
Made by hardwaremack.
