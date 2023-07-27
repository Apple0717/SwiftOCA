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
import SwiftOCA

public class OcaTimeSource: OcaAgent {
    override public class var classID: OcaClassID { OcaClassID("1.2.16") }

    override public class var classVersion: OcaClassVersionNumber { 1 }

    @OcaDeviceProperty(
        propertyID: OcaPropertyID("3.1"),
        getMethodID: OcaMethodID("3.1")
    )
    public var availability: OcaTimeSourceAvailability = .unavailable

    @OcaDeviceProperty(
        propertyID: OcaPropertyID("3.2"),
        getMethodID: OcaMethodID("3.2"),
        setMethodID: OcaMethodID("3.3")
    )
    public var `protocol`: OcaTimeProtocol = .undefined

    @OcaDeviceProperty(
        propertyID: OcaPropertyID("3.3"),
        getMethodID: OcaMethodID("3.4"),
        setMethodID: OcaMethodID("3.5")
    )
    public var parameters: OcaSDPString = ""

    @OcaDeviceProperty(
        propertyID: OcaPropertyID("3.4"),
        getMethodID: OcaMethodID("3.6"),
        setMethodID: OcaMethodID("3.7")
    )
    public var referenceType: OcaTimeReferenceType = .undefined

    @OcaDeviceProperty(
        propertyID: OcaPropertyID("3.5"),
        getMethodID: OcaMethodID("3.8"),
        setMethodID: OcaMethodID("3.9")
    )
    public var referenceID = ""

    @OcaDeviceProperty(
        propertyID: OcaPropertyID("3.6"),
        getMethodID: OcaMethodID("3.10")
    )
    public var syncStatus: OcaTimeSourceSyncStatus = .undefined

    open func reset() async throws {
        throw Ocp1Error.status(.notImplemented)
    }

    override open func handleCommand(
        _ command: Ocp1Command,
        from controller: AES70OCP1Controller
    ) async throws -> Ocp1Response {
        switch command.methodID {
        case OcaMethodID("3.1"):
            try await reset()
            return Ocp1Response()
        default:
            return try await super.handleCommand(command, from: controller)
        }
    }
}
