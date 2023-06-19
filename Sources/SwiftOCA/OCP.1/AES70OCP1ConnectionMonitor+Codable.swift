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

import Foundation
import BinaryCoder

private extension Ocp1Message {
    func encode(type messageType: OcaMessageType) throws -> Data {
        let encoder = BinaryEncoder(config: BinaryCodingConfiguration.ocp1Configuration)
        var messageData = try encoder.encode(self)
        
        if messageType != .ocaKeepAlive {
            /// replace `commandSize: OcaUint32` with actual command size
            precondition(messageData.count < OcaUint32.max)
            messageData.encodeInteger(OcaUint32(messageData.count), index: 0)
        }
        
        return messageData
    }
}

extension AES70OCP1Connection {
    func encodeOcp1MessagePdu(_ messages: [Ocp1Message],
                              type messageType: OcaMessageType) throws -> Data {
        var messagePduData = Data([Ocp1SyncValue])
        
        let header = Ocp1Header(pduType: messageType, messageCount: OcaUint16(messages.count))
        let encoder = BinaryEncoder(config: BinaryCodingConfiguration.ocp1Configuration)
        messagePduData += try encoder.encode(header)

        try messages.forEach {
            messagePduData += try $0.encode(type: messageType)
        }
        /// MinimumPduSize == 7
        /// 0 `syncVal: OcaUint8`
        /// 1`protocolVersion: OcaUint16`
        /// 3 `pduSize: OcaUint32` (size of PDU not including syncVal)
        precondition(messagePduData.count < OcaUint32.max)
        messagePduData.encodeInteger(OcaUint32(messagePduData.count - 1), index: 3)
        return messagePduData
    }
}

extension AES70OCP1Connection.Monitor {
    func decodeOcp1MessagePdu(from ocp1EncodedData: Data, messages: inout [Data]) throws -> OcaMessageType {
        precondition(ocp1EncodedData.count >= Self.MinimumPduSize)
        precondition(ocp1EncodedData[0] == Ocp1SyncValue)
        
        /// MinimumPduSize == 7
        /// 0 `syncVal: OcaUint8`
        /// 1`protocolVersion: OcaUint16`
        /// 3 `pduSize: OcaUint32` (size of PDU not including syncVal)

        guard ocp1EncodedData.count >= Self.MinimumPduSize + 3 else {
            throw Ocp1Error.invalidPduSize
        }
        
        var header = Ocp1Header()
        header.protocolVersion = ocp1EncodedData.decodeInteger(index: 1)
        guard header.protocolVersion == Ocp1ProtocolVersion else {
            throw Ocp1Error.invalidProtocolVersion
        }
        
        header.pduSize = ocp1EncodedData.decodeInteger(index: 3)
        precondition(header.pduSize <= ocp1EncodedData.count - 1)
        
        /// MinimumPduSize +3 == 10
        /// 7 `messageType: OcaUint8`
        /// 8 `messageCount: OcaUint16`
        guard let messageType = OcaMessageType(rawValue: ocp1EncodedData[7]) else {
            throw Ocp1Error.invalidMessageType
        }

        let messageCount: OcaUint16 = ocp1EncodedData.decodeInteger(index: 8)
        
        var cursor = Self.MinimumPduSize + 3 // start of first message
        
        for _ in 0..<messageCount {
            precondition(cursor < ocp1EncodedData.count)
            var messageData = ocp1EncodedData.subdata(in: cursor..<Int(header.pduSize) + 1) // because this includes sync byte
                
            if messageType != .ocaKeepAlive {
                let messageSize: OcaUint32 = messageData.decodeInteger(index: 0)
                
                guard messageSize <= messageData.count else {
                    throw Ocp1Error.invalidMessageSize
                }
                
                messageData = messageData.prefix(Int(messageSize))
                cursor += Int(messageSize)
            }
            
            messages.append(messageData)
            
            if messageType == .ocaKeepAlive {
                break
            }
        }
        
        return messageType
    }
    
    func decodeOcp1Message(from messageData: Data, type messageType: OcaMessageType) throws -> Ocp1Message {
        let decoder = BinaryDecoder(config: BinaryCodingConfiguration.ocp1Configuration)
        let message: Ocp1Message

        switch messageType {
        case .ocaCmd:
            message = try decoder.decode(Ocp1Command.self, from: messageData)
        case .ocaCmdRrq:
            message = try decoder.decode(Ocp1Command.self, from: messageData)
        case .ocaNtf:
            message = try decoder.decode(Ocp1Notification.self, from: messageData)
        case .ocaRsp:
            message = try decoder.decode(Ocp1Response.self, from: messageData)
        case .ocaKeepAlive:
            if messageData.count == 2 {
                message = try decoder.decode(Ocp1KeepAlive1.self, from: messageData)
            } else if messageData.count == 4 {
                message = try decoder.decode(Ocp1KeepAlive2.self, from: messageData)
            } else {
                throw Ocp1Error.invalidKeepAlivePdu
            }
        }
        
        return message
    }
}
