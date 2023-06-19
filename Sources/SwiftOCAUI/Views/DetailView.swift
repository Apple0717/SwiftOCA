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

import SwiftUI
import SwiftOCA

public protocol OcaViewRepresentable: OcaRoot {
    var viewType: any OcaView.Type { get }
}

public struct OcaDetailView: OcaView {
    @StateObject var object: OcaRoot

    public init(_ connection: AES70OCP1Connection, object: OcaObjectIdentification) {
        self._object = StateObject(wrappedValue: connection.resolve(object: object)! )
    }
    
    public init(_ object: OcaRoot) {
        self._object = StateObject(wrappedValue: object)
    }
    
    public var body: some View {
        let metatype = type(of: object)
        
        if metatype == OcaMute.self {
            OcaMuteView(object)
        } else if metatype == OcaBlock.self {
            OcaBlockNavigationStackView(object)
        } else if metatype == OcaMatrix.self {
            OcaMatrixNavigationSplitView(object)
        } else if let object = object as? OcaViewRepresentable {
            // use type erasure as last resort
            AnyView(object.viewType.init(object))
        } else {
            OcaPropertyTableView(object)
        }
    }
}
