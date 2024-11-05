# Unlocking AI Potential with Agora TEN Framework for iOS Apps

In the rapidly evolving landscape of mobile applications, integrating artificial intelligence into chat clients has become a game-changer for the user experience. In this guide, we'll  create an interactive AI voice-chat app for iOS, powered by the TEN Framework. By leveraging Agora’s cutting-edge technology, you can enhance real-time communication and seamlessly incorporate AI capabilities, making your app not only functional but also intelligent. Join me as we dive into the key features of the Agora TEN Framework and walk through the process of building your very own AI-powered chat client for iOS.

TEN stands for Transformative Extension Network, where an extension is a service module that connects Agora's Audio, Video, and Data streams into 3rd party AI services. By connecting multiple extensions together, this daisy chain of services, forms an Agent. This enables developers to connect end-users with powerful AI Agents using natural inputs like voice and vision.In this guide, we use the extensions for OpenAI's LLM, Azure's TTS, and Agora's RTC as our AI agent that users can speak to using the iOS chat app. More information about the TEN Framework can be viewed [here](https://doc.theten.ai/).

## Prerequisites  
- TEN Agent  
- Agora Developer account  
- AWS Developer account  
- OpenAI Developer account  
- Understanding of basic Agora RTC  
- Familiar with SwiftUI programming

## Setup  
1. Obtain an Azure TTS key from the Microsoft Azure portal -> Azure AI Services -> [Speech Services]. (https://portal.azure.com/#view/Microsoft_Azure_ProjectOxford/CognitiveServicesHub/~/SpeechServices) Create an API key for your region.  
2. Obtain an OpenAI API key from the [platform dashboard]. (https://platform.openai.com/api-keys)  
3. Obtain an Agora App ID and certificate from [developer console] (onsole.agora.io/projects).  
4. Clone the [TEN Agent project](https://github.com/TEN-framework/TEN-Agent) from GitHub.  
5. Follow [TEN Agent project's instructions](https://github.com/TEN-framework/TEN-Agent?tab=readme-ov-file#how-to-build-ten-agent-locally) to set up the services in your local environment. Use the keys that you obtained from Steps 1-3 to set up the .env file.

You can observe running services from the Docker desktop display, like the following screen shot:  
![docker](https://github.com/user-attachments/assets/da4525b8-ab3a-4579-b318-591d462b5c9e)

Here the server runs on port 8080 from the ten_agent_dev image. ten_agent_demo and ten_agent_playground are different web frontend applications to use with the server. And the graph designer helps you configure different extension workflows in a visualizing way.  
  
## Agent Overview  
Open Graph Editor on http://localhost:3001, and you should see the following graph of the data flow between the agent modules. The default graph camera.va.openai.azure is selected for illustration.  
![graph](https://github.com/user-attachments/assets/d10e5db7-c541-42f3-a7b8-0ce7a67afd3a)

The TEN agents take care of all the inter-module communication for you. The agora_rtc module enables your app client's connection to the Agora SD-RTN cloud and transcribes your spoken words into text. The text is sent to OpenAI's module for generative response. Then the response is sent to Azure's Text-to-Speech (TTS) module for artificial human voice so you can hear the response on your device. We will use this graph for our iOS app implementation.

Once you verify that Web version of the AI frontend on your environment, you are ready to create an iOS version for the next step.

## Get Started  
The completed TEN iOS Demo can be cloned from [this GitHub repo](https://github.com/AgoraIO-Community/TEN-AI-Demo-IOS).  
Note that the Agora iOS RTC engine is required for the package dependence.  
![PM](https://github.com/user-attachments/assets/e73fdcb8-9c56-4cb2-9e61-fd8bc0531d29)

Update the config.json file. Fill in the `appId` from your Agora account and if you are running the Agent on a different port than the default, make sure to update the `serverBaseURL`.
![Config](https://github.com/user-attachments/assets/957f8d8f-9e04-43f1-b1f1-7a7bb789d620)  
  
  
|Field|Description |  
|--|--|  
|agentUid | UID that the AI Agent uses in the RTC channel. |  
|appId|App ID for your project. Get it from your developer console.|  
|channel | Name of the RTC channel. It will get set later in the code.|  
|rtcToken| Put "true" if your AppID uses a token. The code will get it from the server|  
|product|Leave it as "ils" for live streaming|  
|agoarAsrLanguage|Use "en-US" for now|  
|voiceType|male or female|  
|serverBaseURL| For local runs, the URL should be http://localhost:8080.

## Running  
You can immediately run the demo app on the iOS Simulator after providing the required configuration parameters. The channel name is randomly generated each time you enter the main screen. Or you can enter your custom channel name at the text field input.

For running on a device, remember to set up your host machine to allow inbound http(s) connections and change the serverBaseURL parameter for the host IP.

You will experience the demo like this screen capture:

![running](https://private-user-images.githubusercontent.com/1261195/367476950-1e7136e0-ffef-48fd-9c29-6efa797e33d1.gif?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MzAxNTI3NDEsIm5iZiI6MTczMDE1MjQ0MSwicGF0aCI6Ii8xMjYxMTk1LzM2NzQ3Njk1MC0xZTcxMzZlMC1mZmVmLTQ4ZmQtOWMyOS02ZWZhNzk3ZTMzZDEuZ2lmP1gtQW16LUFsZ29yaXRobT1BV1M0LUhNQUMtU0hBMjU2JlgtQW16LUNyZWRlbnRpYWw9QUtJQVZDT0RZTFNBNTNQUUs0WkElMkYyMDI0MTAyOCUyRnVzLWVhc3QtMSUyRnMzJTJGYXdzNF9yZXF1ZXN0JlgtQW16LURhdGU9MjAyNDEwMjhUMjE1NDAxWiZYLUFtei1FeHBpcmVzPTMwMCZYLUFtei1TaWduYXR1cmU9ZmMxNjM0MjEzODZjYWI2ZGRjY2RmZjEwNGFkMDJkZTI2MDViYzkyYTdhYTUzZTk2MDE0ZDE5MGE3OTQ3MzEwZiZYLUFtei1TaWduZWRIZWFkZXJzPWhvc3QifQ.jZqSaOKlppWHlLlR78q_QDKZjVHroAIRETrYObUaQa0)

## Frontend-Backend Communication  
The server provides four endpoints for RESTful API messages. They are defined as the following:  
|Endpoint|Prerequisite |Request Model class|Response Model class  
|--|--|--|--|  
|/token/generate | none|AgoraRTCTokenRequest|AgoraRTCTokenResponse  
|/ping | session stated |ServicePingRequest|AgoraServerCommandResponse  
|/start |no session |ServiceStartRequest|AgoraServerCommandResponse  
|/stop | session stated |ServiceStopRequest|AgoraServerCommandResponse

The following are sample request and response data in the POST body for each message type.

### Token  
An RTC token can be generated by this server. You may request tokens from the server at any time.

**Request**  
```json  
{  
  "uid": 0,  
  "request_id": "F5504DDF-EBBB-41FE-A3C2-27FF78BCA14D",  
  "channel_name": "agora_astra"  
}  
```  
**Response**  
```json  
{
  "code": "0",
  "data": {
    "appId": "3cf5beb6c72341639f5b214c59f763d6",
    "channel_name": "agora_astra",
    "token": "007eJxSYKhllF39M7asPDFsTpPuZRNes06WnUs/hbv9mvTVIcdbWFGBwTglzTQpNcks2dzI2MTAzNgyzTTJyNAk2dQyzdzMONlsq8PetIZARob2yY+ZGRkYGVgYGBlAfCYwyQwmWcAkN0Nien5RYnxicUlRIgMDIAAA///4TCOn",
    "uid": 0
  },
  "msg": "success"
}
```  
### Ping  
Ping is a message that keeps the connection between the client and server alive. The message should only be sent after the session started (i.e., the start message is successful).  
**Request**  
```json  
{  
"request_id": "F5504DDF-EBBB-41FE-A3C2-27FF78BCA14R",  
"channel_name": "agora_astra"  
}  
```

**Response**  
```json  
{  
"code": "0",  
"data": null,  
"msg": "success"  
}  
```

### Start  
The Start message holds controlling information about the session. Note that properties fields pertain to each extension vendor, and they can have different key-value definitions.

**Request**  
```json  
{
  "request_id": "065dc961-4376-4e0a-b580-a83d603e026e",
  "channel_name": "agora_70xfys",
  "remote_stream_id": 1234,
  "graph_name": "camera.va.openai.azure",
  "properties": {
    "agora_rtc": {
      "agora_asr_language": "en-US"
    },
    "openai_chatgpt": {
      "model": "gpt-4o",
      "greeting": "ASTRA agent connected. How can I help you today?",
      "checking_vision_text_items": "[\"Let me take a look...\",\"Let me check your camera...\",\"Please wait for a second...\"]"
    },
    "azure_tts": {
      "azure_synthesis_voice_name": "en-US-BrianNeural"
    }
  }
}  
```

**Response**  
```json  
{  
  "code": "0",  
  "data": null,  
  "msg": "success"  
}  
```

  
### Stop  
You can only stop a session on a channel when there is one running.

**Request**  
```json  
{  
  "request_id": "e58280da-e2f2-4c0b-a9d1-87edd172edbf",  
  "channel_name": "agora_astra"  
}  
```  
**Response**  
```json  
{  
  "code": "0",  
  "data": null,  
  "msg": "success"  
}  
```

**NetworkManager**  
We implemented a NetworkManager class to handle the communication between the app and the server. The messages are serialized and deserialized at this level. At the application level, the following wrapper methods are provided in AgoraManager:  
- startSession  
- stopSession  
- pingSession

## App Implementation  
### Voice and Video Chat  
Voice and video chat with the AI agent is very straight-forward. The AI agent acts as a remote user in the case of a chat room to the local user.

It is assumed that you understand the basics of implementing an Agora RTC client on iOS. If not, please check out the quick start guide and API-Examples in the resources section. Similar patterns are followed for steps like joining a channel, getting a token, checking for errors, ending the chat session, etc.

In the other examples, we need to deploy a token server, e.g., the recommended [GoLang token server](git@github.com:AgoraIO-Community/agora-token-service.git). However, since the TEN agent server includes a token generator, we will benefit from it and don't need to worry about setting up a separate server for this application.

The only thing that we need to do in addition to a normal RTC call is to add the TEN agent services to the application. To do so, the following logic is required:  
1. Call startSession() when joining a channel.  
2. start a recurring timer, which calls pingSession() at each interval.  
3. Call stopSession() when leaving the channel.

**The Result**  
Speak to the app for your question, as if you type to ask ChatGPT. The AI agent will speak back to you.

You can also prompt the AI agent with a question like "What do you see from my camera?" The AI agent will then try to read from a screenshot from your camera and give a description of the objects in the picture as a deep learning result.

### Agora Manager  
The AgoraManager class is the main controller that handles the Agora RTC logic and the TEN Agent interactions.

Here we will highlight how Agora Manager supports the two advanced features in this application:  
* Transcription Display  
* Sound Visualization

### Transcription Display  
The TEN agent uses the data stream from the RTC channel for the transcription of the conversation. To do that, register an event handler on the AgoraRtcEngineDelegate:  
```swift
open func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
    do {
        let stt = try sttStreamDecoder.parseStream(data: data)
        let msg = IChatItem(userId: uid, text: stt.text, time: stt.textTS, isFinal: stt.isFinal, isAgent: 0 == stt.streamID)
        streamTextProcessor.addChatItem(item: msg)
    } catch let error {
        print("failed to parse textStream \(error.localizedDescription)")
    }
}
```
**Explanation**  
The transcript is separated into chunks and sent into sequential messages. Each chunk is sent as a message in JSON format, which can be deserialized into a STTStreamText struct. Example message:  
```json  
{
"text": "TEN agent connected. Happy to chat with you today.",  
"is_final": true,  
"stream_id": 0,  
"data_type": "transcribe",  
"text_ts": 1730308168743
}  
```  
The struct is translated into a view model, IChatItem, that the stream text processor uses to make the transcript ready for display as a whole.
Note in version 0.5.0, the data stream message is wrapped in a format of 
```
<id>|<idx>|<total>|<content part>
```
where the content part is a part of a long base64 encoded text.  The number of parts is in <total\>, and the <idx\> is the part number.  We use a STTStreamDecoder class to decode the string into STTStreamText struct.


**Stream Text Processor**  
The stream text processor keeps track of the incoming transcript chunks and stores them in a list (sttWords). When addChatItem() is called, the processor processes the message with its time and the isFinal field to determine where to put the message in the list. The final result will update the observed object *messages* in AgoraManager. Later, ChatView uses *messages* to generate the transcription view. It is worth reading the code comments to understand the sorting logic here:  

```swift
struct StreamTextProcessor {
    let agoraManager : AgoraManager
    var sttWords : [IChatItem] = []
    mutating func addChatItem(item:IChatItem) {
        let lastNonFinal = sttWords.lastIndex(where: {item.userId == $0.userId && !$0.isFinal} )
        if let lastFinal = sttWords.lastIndex(where: {item.userId == $0.userId && $0.isFinal} ) {
            // has last final item
            if (item.time <= sttWords[lastFinal].time) {
                // discard
                // print("addChatItem, time < last final item, discard!:" + item.text)
                return;
            } else {
                // newer time stamp
                if (lastNonFinal != nil) {
                    // this is a longer version of the last non final words, update last item(none final)
                    sttWords[lastNonFinal!] = item
                } else {
                    // add new item
                    sttWords.append(item)
                }
            }
        } else {
            // no last final Item
            if (lastNonFinal != nil) {
              // update last item(none final)
              sttWords[lastNonFinal!] = item
            } else {
              // add new item
              sttWords.append(item)
            }
        }
        sttWords.sort(by: {$0.time < $1.time})
        agoraManager.messages = sttWords.map({ ChatMessage(speaker: $0.isAgent ? "Agent":"You", message: $0.text)})
    }
}
```
**Transcription View**  
The transcription view is contained in the ChatView. For now, it is a simple one-to-one chat room design. Speaker A and Speaker B will each take a left side and right side text alignment for the display. When there are more parties involved, an expansion to a more flexible design should be considered.  
  
### Sound Visualization  
In this app, a human user will be shown by camera capture if the camera is enabled and being used. Or the user will be represented by a placeholder image with his/her UID printed on it. The AI speaker is represented by a sound visualizer. We will use the audio stream of only that user to generate the graphic. Note that, in the default situation, audio streams from all remote users are mixed into one stream on the Agora cloud before being delivered to the frontend device. We will like to capture the audio stream before the mixing for a more precise visualization.

To capture the raw data of that audio stream, we do the following:

1. Enable the audio frame delegate for before-mixing playback audio frame.  
```swift  
agoraEngine.setAudioFrameDelegate(self)  
agoraEngine.setPlaybackAudioFrameBeforeMixingParametersWithSampleRate(44100, channel: 1)  
```

2. Add event handler onPlaybackAudioFrame to the AgoraAudioFrameDelegate.  

```swift
extension AgoraManager: AgoraAudioFrameDelegate {
    open func onPlaybackAudioFrame(beforeMixing frame: AgoraAudioFrame, channelId: String, uid: UInt) -> Bool {
        /** The buffer of the sample audio data. When the audio frame uses a stereo
         channel, the data buffer is interleaved. The size of the data buffer is as
         follows: `buffer` = `samplesPerChannel` × `channels` × `bytesPerSample`.
         */
        let bufferBytes = frame.samplesPerChannel * frame.channels * frame.bytesPerSample
        if let buffer = frame.buffer {
            let sampleArray = mapBufferToFloatArray(buffer: buffer, bufferSize: bufferBytes)
            let normalizedSamples = normalizeFrequencies(frequencies: sampleArray)
            let energy = sqrt(normalizedSamples.reduce(0) { $0 + $1 * $1 })
            Task {
                await MainActor.run {
                    self.soundSamples[currentSample] = energy
                    currentSample = (currentSample+1)%VisualizerSamples
                }
            }
        }
        return true
    }
}
```  
**Explanation**  
The raw audio stream arrives in 32 bit PCM audio format. We normalize the sample gain with a minimum and a maximum value. Then we define our relative energy level by calculating the sum of the squares of all elements in the sample array. Lastly, since soundSample is an observed object for the Sound Visualizer view to consume, we enclose its value update in a task running on the main thread.

**Sound Visualizer**  
The sound visualizer view uses a set of vertical bars to show the strength of audio energy. Note that in the event handler sample code shown above, we use a currentSample index to mark the iteration of the incoming audio frame. This creates a movement of energy level as the user speaks.

### Putting it Together  
Let's review what we discussed in this tutorial. First, we listed the essential frontend-backend networking models. Based on this information, a network manager is created to bridge the communication between the app and the server. Then we implement the voice and video chat using Agora's powerful engine. From the engine, we use two advanced features: data streaming and raw audio frame capturing to show the transcription and the AI agent's voice energy level. A simple voice- and video-enabled AI assistant app is created!

## Resources  
* [iOS SDK QuickStart guide](https://docs.agora.io/en/video-calling/get-started/get-started-sdk)  
* [AgoraIO iOS API-Examples](https://github.com/AgoraIO/API-Examples/tree/main/iOS/APIExample)  
* [TEN Agent](https://github.com/TEN-framework/TEN-Agent)
