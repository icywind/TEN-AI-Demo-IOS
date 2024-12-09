//
//  AgoraManager.swift
//  TENDemo
//
//  Created by Rick Cheng on 8/13/24.
//

import AgoraRtcKit
import SwiftUI

enum SessionStatus {
    case loading;
    case joined;
    case left;
}

/// ``AgoraManager`` is a class that provides an interface to the Agora RTC Engine Kit.
/// It conforms to the `ObservableObject` and `AgoraRtcEngineDelegate` protocols.
///
/// Use AgoraManager to set up and manage Agora RTC sessions, manage the client's role,
/// and control the client's connection to the Agora RTC server.
open class AgoraManager: NSObject, ObservableObject {

    // MARK: - Properties

    /// The Agora App ID for the session.
    let appId: String
    /// The client's role in the session.
    var role: AgoraClientRole = .audience {
        didSet { agoraEngine.setClientRole(role) }
    }

    /// The set of all users in the channel.
    @Published public var allUsers: Set<UInt> = []
    @Published public var userVideoPublishing: Dictionary<UInt, Bool> = [:]
    @Published public var streamMessage : String = "";
    
    @Published var soundSamples = [Float](repeating: .zero, count: VisualizerSamples)
    @Published var messages: [ChatMessage] = []
    @Published var label: String?
    @Published var sessionStatus = SessionStatus.loading

    /// A decoder that retrieves the transcription from the user
    let sttStreamDecoder = STTStreamDecoder()
    
    /// whether this client is launch for chatting with AI (one user only)
    var talkingWithAI = false
    
    /// Integer ID of the local user. (required from protocol)
    public var localUserId: UInt = 0

    /// A processor that analyzes the text stream and place them in order
    private lazy var streamTextProcessor = StreamTextProcessor(agoraManager: self)
    
    private var engine: AgoraRtcEngineKit?
    
    @State private var streamId = 0   /// a handler id for data stream, to be assigned by rtc engine
    private var currentSample : Int = 0  /// use for audio sampling
    
    // MARK: - Agora Engine Functions
    public var agoraEngine: AgoraRtcEngineKit {
        if (engine != nil) {
            return engine!
        }
        let engine = setupEngine()
        self.engine = engine
        return engine
    }

    open func setupEngine() -> AgoraRtcEngineKit {
        let eng = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
        
        if AppConfig.shared.product != .voice && Settings.shared.cameraOn {
            eng.enableVideo()
        } else {
            eng.enableAudio()
        }
        eng.setClientRole(role)
//
// Enable this if a message will be sent via datastream.  For receiving only, it is not needed.
//        let config = AgoraDataStreamConfig()
//        let result = eng.createDataStream(&streamId, config: config)
//        if result != 0 {
//            print("ERROR, StreamCreate FAILED!")
//        }
        ///  Enable the capturing of raw audio frame for individual remote users
        eng.setAudioFrameDelegate(self)
        eng.setPlaybackAudioFrameBeforeMixingParametersWithSampleRate(44100, channel: 1)
        return eng
    }
    
    
    /// Sends a text message using the data stream
    /// - Parameters:
    ///     - message:  The message string.
    open func sendMessage(message:String) -> Void {
        let sendResult = engine?.sendStreamMessage(streamId, data: Data(message.utf8))
        if sendResult != nil {
            print("ERROR: sendMessage - \(String(describing: sendResult))")
        } else {
            print("Sent:\(message)")
        }
    }
    
    /// Joins a channel, starting the connection to an RTC session.
    /// - Parameters:
    ///   - channel: Name of the channel to join.
    ///   - token: Token to join the channel, this can be nil for an weak security testing session.
    ///   - uid: User ID of the local user. This can be 0 to allow the engine to automatically assign an ID.
    ///   - mediaOptions: AgoraRtcChannelMediaOptions object for join settings
    /// - Returns: Error code, 0 = success, &lt; 0 = failure.
    @discardableResult
    open func joinChannel(
        _ channel: String, token: String? = nil, uid: UInt = 0,
        mediaOptions: AgoraRtcChannelMediaOptions? = nil
    ) async -> Int32 {
        if await !AgoraManager.checkForPermissions() {
            await self.updateLabel(key: "invalid-permissions")
            return -3
        }

        if let mediaOptions {
            return self.agoraEngine.joinChannel(
                byToken: token, channelId: channel,
                uid: uid, mediaOptions: mediaOptions
            )
        }
        return self.agoraEngine.joinChannel(
            byToken: token, channelId: channel,
            info: nil, uid: uid
        )
    }

    /// Joins a video call, establishing a connection for video communication.
    /// - Parameters:
    ///   - channel: Name of the channel to join.
    ///   - token: Token to join the channel, this can be nil for a weak security testing session.
    ///   - uid: User ID of the local user. This can be 0 to allow the engine to automatically assign an ID.
    /// - Returns: Error code, 0 = success, &lt; 0 = failure.
    @discardableResult
    func joinVideoCall(
        _ channel: String, token: String? = nil, uid: UInt = 0
    ) async -> Int32 {
        /// See ``AgoraManager/checkForPermissions()``, or Apple's docs for details of this method.
        if await !AgoraManager.checkForPermissions() {
            await self.updateLabel(key: "invalid-permissions")
            return -3
        }

        let opt = AgoraRtcChannelMediaOptions()
        opt.channelProfile = .communication

        return self.agoraEngine.joinChannel(
            byToken: token, channelId: channel,
            uid: uid, mediaOptions: opt
        )
    }

    /// Joins a voice call, establishing a connection for audio communication.
    /// - Parameters:
    ///   - channel: Name of the channel to join.
    ///   - token: Token to join the channel, this can be nil for a weak security testing session.
    ///   - uid: User ID of the local user. This can be 0 to allow the engine to automatically assign an ID.
    /// - Returns: Error code, 0 = success, &lt; 0 = failure.
    @discardableResult
    func joinVoiceCall(
        _ channel: String, token: String? = nil, uid: UInt = 0
    ) async -> Int32 {
        /// See ``AgoraManager/checkForPermissions()``, or Apple's docs for details of this method.
        if await !AgoraManager.checkForPermissions() {
            await self.updateLabel(key: "invalid-permissions")
            return -3
        }

        let opt = AgoraRtcChannelMediaOptions()
        opt.channelProfile = .communication

        return self.agoraEngine.joinChannel(
            byToken: token, channelId: channel,
            uid: uid, mediaOptions: opt
        )
    }

    /// Joins a broadcast stream, enabling broadcasting or audience mode.
    /// - Parameters:
    ///   - channel: Name of the channel to join.
    ///   - token: Token to join the channel, this can be nil for a weak security testing session.
    ///   - uid: User ID of the local user. This can be 0 to allow the engine to automatically assign an ID.
    ///   - isBroadcaster: Flag to indicate if the user is joining as a broadcaster (true) or audience (false).
    ///                    Defaults to true.
    /// - Returns: Error code, 0 = success, &lt; 0 = failure.
    @discardableResult
    func joinBroadcastStream(
        _ channel: String, token: String? = nil,
        uid: UInt = 0, isBroadcaster: Bool = true
    ) async -> Int32 {
        /// See ``AgoraManager/checkForPermissions()``, or Apple's docs for details of this method.
        if isBroadcaster, await !AgoraManager.checkForPermissions() {
            await self.updateLabel(key: "invalid-permissions")
            return -3
        }

        let opt = AgoraRtcChannelMediaOptions()
        opt.channelProfile = .liveBroadcasting
        opt.clientRoleType = isBroadcaster ? .broadcaster : .audience
        opt.audienceLatencyLevel = isBroadcaster ? .ultraLowLatency : .lowLatency

        return self.agoraEngine.joinChannel(
            byToken: token, channelId: channel,
            uid: uid, mediaOptions: opt
        )
    }

    /// Leaves the channel and stops the preview for the session.
    ///
    /// - Parameter leaveChannelBlock: An optional closure that will be called when the client leaves the channel.
    ///      The closure takes an `AgoraChannelStats` object as its parameter.
    ///
    ///
    /// This method also empties all entries in ``allUsers``,
    @discardableResult
    open func leaveChannel(
        leaveChannelBlock: ((AgoraChannelStats) -> Void)? = nil,
        destroyInstance: Bool = true
    ) -> Int32 {
        let leaveErr = self.agoraEngine.leaveChannel(leaveChannelBlock)
        self.agoraEngine.stopPreview()
        defer {
            if destroyInstance {
                AgoraRtcEngineKit.destroy()
                print ("Engine destroyed!")
                engine = nil
            }
        }
        self.allUsers.removeAll()
        return leaveErr
    }

    func switchCamera() {
        self.agoraEngine.switchCamera()
    }
    
    func toggleMute(mute: Bool) {
        self.agoraEngine.muteLocalAudioStream(mute)
    }
    // MARK: - Setup

    /// Initializes a new instance of `AgoraManager` with the specified app ID and client role.
    ///
    /// - Parameters:
    ///   - appId: The Agora App ID for the session.
    ///   - role: The client's role in the session. The default value is `.audience`.
    public init(appId: String, role: AgoraClientRole = .audience) {
        self.appId = appId
        self.role = role
        super.init()
    }

    @MainActor
    func updateLabel(to message: String) {
        self.label = message
    }

    @MainActor
    func updateLabel(key: String, comment: String = "") {
        self.label = NSLocalizedString(key, comment: comment)
    }
}

/// Handling session logic with the TEN Server
extension AgoraManager {
    @discardableResult
    public func startSession(withAI : Bool) async -> Int32 {
        let channel = AppConfig.shared.channel
        var token = AppConfig.shared.rtcToken;
        
        // if intended AppID is token-enable, then the config file should
        // has one non empty entry (copied from console)
        // We will use the server generated version to avoid manual entry
        // from now on.
        if (token != nil && token != "") {
            do {
                token = try await NetworkManager.ApiRequestToken(uid:0)
            } catch let error {
                print("ApiRequestToken:\(error)")
                return -1;
            }
        }
        
        let uid : UInt = 0
        var status : Int32 = 0
        
        switch AppConfig.shared.product {
        case .rtc:
            status = await joinVideoCall(channel, token: token, uid: uid)
        case .ils:
            status = await joinBroadcastStream(
                channel, token: token, uid: uid,
                isBroadcaster: true
            )
        case .voice:
            status = await joinVoiceCall(channel, token: token, uid: uid)
        }
        
        talkingWithAI = withAI

        return status
    }
    
    @discardableResult
    public func stopSession() -> Int32 {
        Task {
            do {
                let _ = try await NetworkManager.ApiRequestStopService()
            } catch let error {
                print ("Error: \(error.localizedDescription)")
            }
        }
        sessionStatus = .left
        return leaveChannel(leaveChannelBlock: nil, destroyInstance: true)
    }
    
    public func pingSession() -> Void {
        Task {
            do {
                let _ = try await NetworkManager.ApiRequestPingService()
            } catch let error {
                print ("Error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Delegate Methods

extension AgoraManager: AgoraRtcEngineDelegate {
    /// The delegate is telling us that the local user has successfully joined the channel.
    /// - Parameters:
    ///    - engine: The Agora RTC engine kit object.
    ///    - channel: The channel name.
    ///    - uid: The ID of the user joining the channel.
    ///    - elapsed: The time elapsed (ms) from the user calling `joinChannel` until this method is called.
    ///
    /// If the client's role is `.broadcaster`, this method also adds the broadcaster's
    /// userId (``localUserId``) to the ``allUsers`` set.
    @MainActor
    open func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        self.localUserId = uid
        if self.role == .broadcaster {
            self.allUsers.insert(uid)
        }
        Task {
            do {
                let _ = try await NetworkManager.ApiRequestStartService(uid:self.localUserId)
                self.sessionStatus = .joined
            } catch let error {
                print ("Error: \(error.localizedDescription)")
            }
        }
    }

    /// The delegate is telling us that a remote user has joined the channel.
    ///
    /// - Parameters:
    /// - engine: The Agora RTC engine kit object.
    /// - uid: The ID of the user joining the channel.
    /// - elapsed: The time elapsed (ms) from the user calling `joinChannel` until this method is called.
    ///
    /// This method adds the remote user to the `allUsers` set.
    open func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print ("User \(uid) joined.")
        self.allUsers.insert(uid)
    }
    
    
    /// The delegate is telling us that a remote user has left the channel.
    ///
    /// - Parameters:
    ///     - engine: The Agora RTC engine kit object.
    ///     - uid: The ID of the user who left the channel.
    ///     - reason: The reason why the user left the channel.
    ///
    /// This method removes the remote user from the `allUsers` set.
    open func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        self.allUsers.remove(uid)
        self.userVideoPublishing.removeValue(forKey: uid)
    }
    
    /// The delegate signals the change of video publishing state for the local user
    ///  - Parameters:
    ///     - engine: The Agora RTC engine kit object.
    ///     - state: The state of the video streaming
    ///     - reason: The reason why the user left the channel.
    ///     - sourceType: the source of the video
    ///
    open func rtcEngine(_ engine: AgoraRtcEngineKit, localVideoStateChangedOf state: AgoraVideoLocalState, reason: AgoraLocalVideoStreamReason, sourceType: AgoraVideoSourceType) {
        print("localVideoStateChangedOf: \(state) \(reason)")
        switch(state) {
        case .encoding:
            userVideoPublishing[localUserId] = true
            break;
        case .stopped:
            userVideoPublishing[localUserId] = false
            break
        case .failed:
            userVideoPublishing[localUserId] = false
            break;
        default:
            break;
        }
     }
    /// The delegate signals the change of video publishing state for the remote user
    ///  - Parameters:
    ///     - engine: The Agora RTC engine kit object.
    ///     - uid: the uid of the remote user
    ///     - state: The state of the video streaming
    ///     - reason: The reason why the user left the channel.
    ///     - elapsed: time since joined
    ///
    open func rtcEngine( _ engine: AgoraRtcEngineKit,
        remoteVideoStateChangedOfUid uid: UInt,
        state: AgoraVideoRemoteState,
        reason: AgoraVideoRemoteReason,
        elapsed: Int
    ) {
        print("remoteVideoStateChangedOfUid:\(uid) \(state) \(reason)")
        switch(state) {
        case .decoding:
            userVideoPublishing[uid] = true;
            break;
        case .stopped:
            userVideoPublishing[uid] = false;
            break;
        default:
            break;
        }
    }
    
    /// The delegate of receiving the data stream data
    ///   - Parameters:
    ///     - engine: The Agora RTC engine kit object.
    ///     - uid: the uid of the remote user
    ///     - streamId: the stream's id
    ///     - data: the data
    open func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
        do {
            // The stream decoder parse the string from the data, and convert base64 encoded text into readable text
            let stt = try sttStreamDecoder.parseStream(data: data)
            let msg = IChatItem(userId: uid, text: stt.text, time: stt.textTS, isFinal: stt.isFinal, isAgent: 0 == stt.streamID)
            streamTextProcessor.addChatItem(item: msg)
        } catch let error {
            print("failed to parse textStream \(error.localizedDescription)")
        }
    }
}

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
