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

struct OcaNavigationSplitView: View {
    @StateObject var object: OcaBlock
    @Binding var oNoPath: NavigationPath
    @State var members: [OcaRoot] = []
    @State var membersMap: [OcaONo:OcaRoot] = [:]
    @State var selectedONo: OcaONo? = nil

    var selectedObject: OcaRoot? {
        guard let selectedONo = selectedONo,
              let object = membersMap[selectedONo] else {
            return nil
        }
        
        return object
    }
    
    public var body: some View {
        NavigationSplitView {
            List(members, selection: $selectedONo) { member in
                OcaNavigationLabel(member)

                /*
                Group {
                    if let member = member as? OcaBlock {
                        NavigationLink(value: member.objectNumber) {
                            OcaNavigationStackView(object: member, oNoPath: $oNoPath)
                        }
                    } else {
                        OcaNavigationLabel(member)
                    }
                }
                 */
            }
        } detail: {
            Group {
                if let selectedObject = selectedObject {
                    OcaDetailView(selectedObject)
                }
            }
                .id(selectedONo)
        }
        .task {
            members = (try? await object.resolveMembers()) ?? []
            membersMap = members.map
        }
    }
}