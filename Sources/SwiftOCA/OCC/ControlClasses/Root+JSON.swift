//
// Copyright (c) 2024 PADL Software Pty Ltd
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

import AnyCodable
import AsyncExtensions
import Foundation

@_spi(SwiftOCAPrivate)
public let objectNumberJSONKey = "_oNo"
@_spi(SwiftOCAPrivate)
public let classIDJSONKey = "_classID"
@_spi(SwiftOCAPrivate)
public let actionObjectsJSONKey = "_members"

@_spi(SwiftOCAPrivate)
public extension JSONEncoder {
    func reencodeAsValidJSONObject<T: Codable>(_ value: T) throws -> Any {
        let data = try encode(value)
        return try JSONDecoder().decode(AnyDecodable.self, from: data).value
    }
}