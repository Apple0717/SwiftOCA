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

public struct OcaGetPathParameters: Codable, OcaParameterCountReflectable {
    public static var responseParameterCount: OcaUint8 { 2 }

    public var namePath: OcaNamePath
    public var oNoPath: OcaONoPath

    public init(namePath: OcaNamePath, oNoPath: OcaONoPath) {
        self.namePath = namePath
        self.oNoPath = oNoPath
    }
}

open class OcaAgent: OcaRoot {
    override public class var classID: OcaClassID { OcaClassID("1.2") }

    @OcaProperty(
        propertyID: OcaPropertyID("2.1"),
        getMethodID: OcaMethodID("2.1"),
        setMethodID: OcaMethodID("2.2")
    )
    public var label: OcaProperty<OcaString>.State

    @OcaProperty(
        propertyID: OcaPropertyID("2.2"),
        getMethodID: OcaMethodID("2.3")
    )
    public var owner: OcaProperty<OcaONo>.State

    var path: (OcaNamePath, OcaONoPath) {
        get async throws {
            let responseParams: OcaGetPathParameters

            responseParams = try await sendCommandRrq(methodID: OcaMethodID("2.4"))

            return (responseParams.namePath, responseParams.oNoPath)
        }
    }
}
