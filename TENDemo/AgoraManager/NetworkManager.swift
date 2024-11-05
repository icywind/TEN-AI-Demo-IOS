//
//  NetworkManager.swift
//  TENDemo
//
//  Created by Rick Cheng on 8/13/24.
//

import Foundation

/// A class to handle communication to the TEN Server
open class NetworkManager {
    /// Description - ApiRequestToken
    ///    Request the server to generate a token based on channel and uid.
    ///  The caller should handle the exception from this networking action.
    /// - Returns: rtc token string
    static func ApiRequestToken(uid : UInt) async throws -> String {
        // Get the shared AppConfig instance
        let config = AppConfig.shared
        
        // Create an AgoraRTCTokenRequest object with a unique request ID, channel name, and user ID
        let data = AgoraRTCTokenRequest(requestId: genUUID(),
                                        channelName: config.channel,
                                        uid: uid)
        
        // Construct the API endpoint URL
        let endpoint = config.serverBaseURL + "/token/generate"
        
        // Make a server API request and decode the response
        let response = try await ServerApiRequest(apiurl:endpoint, data: data)
        let decoded = try JSONDecoder().decode(AgoraRTCTokenResponse.self, from: response)
        
        // Return the token from the decoded response
        return decoded.data.token
    }
    
    /// Starts the service by sending a request to the server.
    ///
    /// - Throws: An error if the request fails.
    /// - Returns: The data returned by the server.
    static func ApiRequestStartService(uid : UInt) async throws -> Data {
        // Get the shared AppConfig instance
        let config = AppConfig.shared
        let voice = Settings.shared.getVoiceName(voiceType:config.voiceType)
        
        // Create a ServerStartProperties object with configuration for Agora RTC, OpenAI ChatGPT, and Azure TTS
        let startProperties = ServerStartProperties(agoraRtc: ["agora_asr_language": "en-US"],
                                                    openaiChatGPT: [
                                                        "model": "gpt-4o",
                                                        "greeting": "TEN agent connected. Happy to chat with you today.",
                                                        "checking_vision_text_items": "[\"Let me take a look...\",\"Let me check your camera...\",\"Please wait for a second...\"]"
                                                    ],
                                                    azureTTS: ["azure_synthesis_voice_name": voice])
        
        // Create a ServiceStartRequest object with request ID, channel name, OpenAI proxy URL, remote stream ID, graph name, voice type, and start properties
        let data = ServiceStartRequest(requestId: genUUID(),
                                       channelName: config.channel,
                                       userUID: uid,
                                       graphName : "camera_va_openai_azure",
                                       language: config.agoraAsrLanguage,
                                       voiceType: config.voiceType.description,
                                       properties: startProperties
        )
        
        // Construct the API endpoint URL
        let endpoint = config.serverBaseURL + "/start"
        
        // Make a server API request and return the response data
        return try await ServerApiRequest(apiurl: endpoint, data: data)
    }
    
    /// Stops the service by sending a request to the server.
    ///
    /// - Throws: An error if the request fails.
    /// - Returns: The data returned by the server.
    static func ApiRequestStopService() async throws -> Data {
        // Get the shared AppConfig instance
        let config = AppConfig.shared
        
        // Create a ServiceStopRequest object with request ID and channel name
        let data = ServiceStopRequest(requestId: genUUID(),
                                      channelName: config.channel)
        
        // Construct the API endpoint URL
        let endpoint = config.serverBaseURL + "/stop"
        
        // Make a server API request and return the response data
        return try await ServerApiRequest(apiurl: endpoint, data: data)
    }
    
    /// Sends a ping request to the server to check service status.
    ///
    /// - Throws: An error if the request fails.
    /// - Returns: The data returned by the server.
    static func ApiRequestPingService() async throws -> Data {
        // Get the shared AppConfig instance
        let config = AppConfig.shared
        
        // Create a ServicePingRequest object with request ID and channel name
        let data = ServicePingRequest(requestId: genUUID(),
                                      channelName: config.channel)
        
        // Construct the API endpoint URL
        let endpoint = config.serverBaseURL + "/ping"
        
        // Make a server API request and return the response data
        return try await ServerApiRequest(apiurl: endpoint, data: data)
    }
    
    /// Makes a server API request with the specified URL and data.
    ///
    /// - Parameters:
    ///   - apiurl: The URL of the API endpoint.
    ///   - data: The data to be sent in the request body.
    /// - Throws: An error if the request fails.
    /// - Returns: The data returned by the server.
    private static func ServerApiRequest(apiurl:String, data: Codable) async throws -> Data {
        // Create a URL object from the API endpoint URL
        let url = URL(string:apiurl)!
        
        // Create a URLRequest object with the specified URL and HTTP method
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set the Content-Type header to application/json
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode the data into JSON format
        let body = try JSONEncoder().encode(data)

        // Convert JSON data to a string for debug
//        if let jsonString = String(data: body, encoding: .utf8) {
//            print(jsonString)
//        }
//        
        // Set the request body to the encoded JSON data
        request.httpBody = body
        
        // Make a data task with the URLSession and resume it
        return try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.dataTask(with: request) { (data1, response, error) in
                // Handle errors
                if let error = error {
                    continuation.resume(with: .failure(error))
                } else if let data = data1 {
                    // Resume the continuation with the data
                    continuation.resume(with: .success(data))
                }
            }
            task.resume()
        }
    }
}
