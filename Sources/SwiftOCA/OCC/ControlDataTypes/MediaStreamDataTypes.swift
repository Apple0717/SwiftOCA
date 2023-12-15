//
// Copyright (c) 2023 PADL Software Pty Ltd
//
// Licensed under the Apache License, Version 2.0 (the License);
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

public typealias OcaMediaStreamEndpointID = OcaUint32

public enum OcaMediaStreamEndpointState: OcaUint8, Codable, Sendable {
    case unknown = 0
    case notReady = 1
    case ready = 2
    case connected = 3
    case running = 4
    case errorHalt = 5
}

public enum OcaMediaStreamEndpointCommand: OcaUint8, Codable, Sendable {
    case none = 0
    case setReady = 1
    case connect = 2
    case connectAndStart = 3
    case disconnect = 4
    case stopAndDisconnect = 5
    case start = 6
    case stop = 7
}

public final class OcaMediaStreamEndpoint: Codable, Sendable {
    public let idInternal: OcaMediaStreamEndpointID
    public let idExternal: OcaBlob
    public let direction: OcaIODirection
    public let userLabel: OcaString
    public let networkAssignmentIDs: OcaList<OcaID16>
    public let streamModeCapabilityIDs: OcaList<OcaID16>
    public let clockONo: OcaONo
    public let channelMapDynamic: OcaBoolean
    public let channelMap: OcaMultiMap<OcaUint16, OcaPortID>
    public let alignmentLevel: OcaDBFS
    public let currentStreamMode: OcaMediaStreamMode
    public let securityType: OcaSecurityType
    public let streamCastMode: OcaMediaStreamCastMode
    public let adaptationData: OcaAdaptationData
    public let redundantSetID: OcaID16
    /*
     public let mediaStreamEndpointStatus: OcaMediaStreamEndpointStatus
     public let mediaStreamMode: OcaMediaStreamMode
     public let mediaStreamModeCapability: OcaMediaStreamModeCapability
     public let mediaCoding: OcaMediaCoding
     public let mediaConnection: OcaMediaConnection
     public let mediaClock3: OcaMediaClock3
     public let mediaTransportApplication: OcaMediaTransportApplication
     public let networkInterfaceAssignment: OcaNetworkInterfaceAssignment
     public let mediaTransportNetwork: OcaMediaTransportNetwork
      */

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        idInternal = try container.decode(OcaMediaStreamEndpointID.self, forKey: .idInternal)
        idExternal = try container.decode(OcaBlob.self, forKey: .idExternal)
        direction = try container.decode(OcaIODirection.self, forKey: .direction)
        userLabel = try container.decode(OcaString.self, forKey: .userLabel)
        networkAssignmentIDs = try container.decode([OcaID16].self, forKey: .networkAssignmentIDs)
        streamModeCapabilityIDs = try container.decode(
            [OcaID16].self,
            forKey: .streamModeCapabilityIDs
        )
        clockONo = try container.decode(OcaONo.self, forKey: .clockONo)
        channelMapDynamic = try container.decode(OcaBoolean.self, forKey: .channelMapDynamic)
        channelMap = try container.decode(
            OcaMultiMap<OcaUint16, OcaPortID>.self,
            forKey: .channelMap
        )
        alignmentLevel = try container.decode(OcaDBFS.self, forKey: .alignmentLevel)
        currentStreamMode = try container.decode(
            OcaMediaStreamMode.self,
            forKey: .currentStreamMode
        )
        securityType = try container.decode(OcaSecurityType.self, forKey: .securityType)
        streamCastMode = try container.decode(OcaMediaStreamCastMode.self, forKey: .streamCastMode)
        adaptationData = try container.decode(OcaAdaptationData.self, forKey: .adaptationData)
        redundantSetID = try container.decode(OcaID16.self, forKey: .redundantSetID)
    }
}

public struct OcaMediaStreamEndpointStatus: Codable, Sendable {
    public let state: OcaMediaStreamEndpointState
    public let errorCode: OcaUint16
    /*
     public let streamEndpoint: OcaMediaStreamEndpoint
     public let transportNetwork: OcaMediaTransportNetwork
      */
}

public enum OcaMediaFrameFormat: OcaUint8, Codable, Sendable {
    case undefined = 0
    case rtp = 1
    case aaf = 2
    case crf_milan = 3
    case iec_61883_6 = 4
    case usb_audio_2_0 = 5
    case extensionPoint = 65
}

public struct OcaMediaStreamMode: Codable, Sendable {
    public let frameFormat: OcaMediaFrameFormat
    // public let encodingType: OcaMimeType
    public let samplingRate: OcaFrequency
    public let channelCount: OcaUint16
    public let packetTime: OcaTimeInterval
    public let mediaStreamEndpoint: OcaMediaStreamEndpoint
}

public struct OcaMediaStreamModeCapability: Codable, Sendable {
    public let id: OcaID16
    public let name: OcaString
    public let direction: OcaMediaStreamModeCapabilityDirection
    public let frameFormatList: [OcaMediaFrameFormat]
    public let encodingTypeList: [OcaMimeType]
    public let samplingRateList: [OcaFrequency]
    public let channelCountList: [OcaUint16]
    public let channelCountRange: Range<OcaUint16>
    public let packetTimeList: [OcaTimeInterval]
    public let packetTimeRange: Range<OcaTimeInterval>
    public let mediaStreamEndpoint: OcaMediaStreamEndpoint
}

public enum OcaMediaStreamModeCapabilityDirection: OcaUint8, Codable, Sendable {
    case input = 1
    case output = 2
}

public struct OcaMediaTransportSession: Codable, Sendable {
    public let idInternal: OcaMediaTransportSessionID
    public let idExternal: OcaBlob
    public let userLabel: OcaString
    public let streamingEnabled: OcaBoolean
    public let adaptationData: OcaAdaptationData
    public let connections: [OcaMediaTransportSessionConnection]
    public let connectionStates: [
        OcaMediaTransportSessionConnectionID: OcaMediaTransportSessionConnectionState
    ]
    /*
     public let transportSessionConnection: OcaMediaTransportSessionConnection
     public let transportSessionAgent: OcaMediaTransportSessionAgent
     */
}

public struct OcaMediaTransportSessionConnection: Codable, Sendable {
    public let id: OcaMediaTransportSessionConnectionID
    public let localEndpointID: OcaMediaStreamEndpointID
    public let remoteEndpointID: OcaBlob
    /*
     public let mediaTransportSession: OcaMediaTransportSession
     */
}

public typealias OcaMediaTransportSessionConnectionID = OcaUint32

public struct OcaMediaTransportSessionConnectionState: Codable, Sendable {
    public let localEndpointState: OcaMediaStreamEndpointState
    public let remoteEndpointState: OcaMediaStreamEndpointState
}

public typealias OcaMediaTransportSessionID = OcaUint32

public enum OcaMediaTransportSessionState: OcaUint8, Codable, Sendable {
    case unconfigured = 1
    case configured = 2
    case connectedNotStreaming = 3
    case connectedStreaming = 4
    case error = 5
}

public struct OcaMediaTransportSessionStatus: Codable, Sendable {
    public let state: OcaMediaTransportSessionState
    public let adaptationData: OcaBlob
}

public struct OcaMediaTransportTimingParameters: Codable, Sendable {
    public let minReceiveBufferCapacity: OcaTimeInterval
    public let maxReceiveBufferCapacity: OcaTimeInterval
    public let transmissionTimeVariation: OcaTimeInterval
}

public enum OcaNetworkAdvertisingService: OcaUint8, Codable, Sendable {
    case dnsSD = 0
    case mDNS_DNSSD = 1
    case nmos = 2
    case expansionBase = 128
}

public struct OcaNetworkAdvertisingMechanism: Codable, Sendable {
    public let service: OcaNetworkAdvertisingService
    public let parameters: OcaParameterRecord
    public let networkInterfaceAssignment: OcaNetworkInterfaceAssignment
}

public struct OcaNetworkInterfaceAssignment: Codable, Sendable {
    public let id: OcaID16
    public let networkInterfaceONo: OcaONo
    public let networkBindingParameters: OcaBlob
    public let securityKeyIdentities: [OcaString]
    public let advertisingMechanisms: [OcaNetworkAdvertisingMechanism]
    /*
     public let advertisingMechanism: OcaNetworkAdvertisingMechanism
     public let mediaStreamEndpoint: OcaMediaStreamEndpoint
     public let networkInterface: OcaNetworkInterface
     public let networkApplication: OcaNetworkApplication
      */
}

public enum OcaNetworkInterfaceCommand: OcaUint8, Codable, Sendable {
    case start = 0
    case stop = 1
    case restart = 2
}

public enum OcaNetworkInterfaceState: OcaUint8, Codable, Sendable {
    case notReady = 0
    case ready = 1
    case fault = 2
}

public struct OcaNetworkInterfaceStatus: Codable, Sendable {
    public let state: OcaNetworkInterfaceState
    public let adaptationData: OcaAdaptationData
}
