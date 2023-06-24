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

public struct OcaList2D<Element> {
    public let nX, nY: Int
    public private(set) var items: [Element]

    public init(nX: Int, nY: Int, defaultValue: Element) {
        self.nX = nX
        self.nY = nY
        self.items = Array(repeating: defaultValue, count: nX * nY) as! [Element]
    }
    
    public init(nX: OcaUint16, nY: OcaUint16, defaultValue: Element) {
        self.init(nX: Int(nX), nY: Int(nY), defaultValue: defaultValue)
    }
    
    private func indexIsValid(x: Int, y: Int) -> Bool {
        return x >= 0 && x < nX && y >= 0 && y < nY
    }

    public subscript(x: Int, y: Int) -> Element {
        get {
            assert(indexIsValid(x: x, y: y), "Index out of range")
            return items[(x * nY) + y]
        }
        set {
            assert(indexIsValid(x: x, y: y), "Index out of range")
            items[(x * nY) + y] = newValue
        }
    }
}

extension OcaList2D: Codable where Element: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.nX = Int(try container.decode(OcaUint16.self))
        self.nY = Int(try container.decode(OcaUint16.self))
    
        self.items = [Element]()
        self.items.reserveCapacity(Int(nX * nY))
        for index in 0..<nX*nY {
            self.items.insert(try container.decode(Element.self), at: index)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(OcaUint16(self.nX))
        try container.encode(OcaUint16(self.nY))
        for index in 0..<nX*nY {
            try container.encode(self.items[index])
        }
    }
}

extension OcaList2D: Equatable where Element: Equatable {
}

extension OcaList2D: Hashable where Element: Hashable {
}