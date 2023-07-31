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

open class OcaNetworkManager: OcaManager {
    override public class var classID: OcaClassID { OcaClassID("1.3.6") }

    @OcaProperty(
        propertyID: OcaPropertyID("3.1"),
        getMethodID: OcaMethodID("3.1")
    )
    public var networks: OcaProperty<OcaList<OcaONo>>.State

    @OcaProperty(
        propertyID: OcaPropertyID("3.2"),
        getMethodID: OcaMethodID("3.2")
    )
    public var streamNetworks: OcaProperty<OcaList<OcaONo>>.State

    @OcaProperty(
        propertyID: OcaPropertyID("3.3"),
        getMethodID: OcaMethodID("3.3")
    )
    public var controlNetworks: OcaProperty<OcaList<OcaONo>>.State

    @OcaProperty(
        propertyID: OcaPropertyID("3.4"),
        getMethodID: OcaMethodID("3.4")
    )
    public var mediaTransportNetworks: OcaProperty<OcaList<OcaONo>>.State

    convenience init() {
        self.init(objectNumber: OcaNetworkManagerONo)
    }
}
