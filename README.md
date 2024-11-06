# TEN AI Agent Demo

![TENDemoIOS](https://github.com/user-attachments/assets/8ea3df82-61ba-4fa2-ba43-52b85040a27f)

This app is powered by TEN Framework which is used to implement four core technologies: Realtime Communication, Realtime Transcription, a Large Language Model (LLM), and Text to Speech extensions. The TEN Framework makes the workflow super easy! The iOS Demo resembles voice chat demos from OpenAI, where end-users speak to the AI Agent and the Agent speaks back. The TEN Framework makes the workflow super easy! The iOS Demo resembles the web demo and acts as the mobile frontend to the AI Agent. You may ask the Agent any general question.

For more details of the project, view [the guide](docs/GUIDE.md).

![TENagentRun](https://github.com/user-attachments/assets/1e7136e0-ffef-48fd-9c29-6efa797e33d1)
## Prerequisites:
- Agora Developer account
- [TEN Frameworks Agent](https://github.com/TEN-framework/TEN-Agent)
- XCode
- iOS Device

### The implicit requirement by TEN Frameworks:
- Text to Speech Support (e.g. API Key from Azure)
- LLM Support (e.g. OpenAI API key)
    
## Setups
### TEN Agent Server
First you should have gotten the TEN Agent working in your environment.  The playground part is optional and it can be stopped for the test for this application.   You will just need the Server running.
![docker](https://github.com/user-attachments/assets/606c6e75-c95c-4f8b-bea7-f688031ea745)

### Build the iOS App
1.  Clone this GitHub project.
2.  Open the project with Xcode and import the Agora SDK plugin. The project includes the Agora Video SDK as a dependency package. Once Xcode loads the project, the package download should start automatically and finish in a few minutes.
3.  Enter your AppID in the Config file. An AppID with token security enabled is required. Note that this should match your AppID in the .env file of the TEN Agent setup.
4. Enter your TEN server's URL.  If you are running it locally, it is http://localhost:8080.
![TENDemo_—_config_json](https://github.com/user-attachments/assets/b9e93f52-83b3-43ee-a11b-3d0975e252cb)

## Running the App
Build to the iOS Device.

You may also run the app from the Simulator. However, it is recommended to use headphones in this setup, as the Agent’s conversation could be captured through the computer microphone as input and cause confusion.

The App will generate a random channel name whenever the home screen is loaded. You may change the text for your channel name. Then press Join to chat with the Agent.

## References
For reference, it is worthwhile to check out the following resources:
* [TEN Framework docs](https://doc.theten.ai/)
* [Agora SDK API references](https://api-ref.agora.io/en/voice-sdk/ios/4.x/documentation/agorartckit).  
* [iOS quickstart guide](https://docs.agora.io/en/video-calling/get-started/get-started-sdk?platform=ios) 

## License
[MIT License](https://github.com/icywind/TEN-AI-Demo-IOS/blob/main/LICENSE)
