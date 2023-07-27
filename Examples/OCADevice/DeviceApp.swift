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

import FlyingSocks
import Foundation
import SwiftOCA
import SwiftOCADevice

@main
public enum DeviceApp {
    static var testActuator: SwiftOCADevice.OcaBooleanActuator?

    public static func main() async throws {
        var device: AES70OCP1Device!
        var localAddress = sockaddr_in.inet(port: 65000)

        withUnsafeBytes(of: &localAddress) { bytes in
            let data = Data(bytes: bytes.baseAddress!, count: bytes.count)
            device = AES70OCP1Device(address: data)
        }

        testActuator = try await SwiftOCADevice.OcaBooleanActuator(
            role: "Test Actuator",
            deviceDelegate: device
        )
        try await device.start()
    }
}
