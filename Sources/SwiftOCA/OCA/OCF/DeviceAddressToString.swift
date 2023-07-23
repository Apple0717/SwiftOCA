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

func DeviceAddressToString(_ deviceAddress: UnsafePointer<sockaddr>) -> String {
    switch deviceAddress.pointee.sa_family {
    case sa_family_t(AF_INET):
        return deviceAddress
            .withMemoryRebound(to: sockaddr_in.self, capacity: 1) { cSockAddrIn4 -> String in
                var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                var addr = cSockAddrIn4.pointee.sin_addr
                inet_ntop(AF_INET, &addr, &buffer, socklen_t(buffer.count))
                return String(cString: buffer) +
                    ":\(UInt16(bigEndian: cSockAddrIn4.pointee.sin_port))"
            }
    case sa_family_t(AF_INET6):
        return deviceAddress
            .withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { cSockAddrIn6 -> String in
                var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                var addr = cSockAddrIn6.pointee.sin6_addr
                inet_ntop(AF_INET6, &addr, &buffer, socklen_t(buffer.count))
                return String(cString: buffer) +
                    ":\(UInt16(bigEndian: cSockAddrIn6.pointee.sin6_port.bigEndian))"
            }
    case sa_family_t(AF_LOCAL):
        return deviceAddress
            .withMemoryRebound(to: sockaddr_un.self, capacity: 1) { cSockAddrUn -> String in
                cSockAddrUn.withMemoryRebound(
                    to: UInt8.self,
                    capacity: MemoryLayout.size(ofValue: cSockAddrUn)
                ) { cPath in
                    String(cString: cPath)
                }
            }
    default:
        return "<\(deviceAddress.pointee.sa_family)>"
    }
}
