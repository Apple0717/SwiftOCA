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

open class OcaDiagnosticManager: OcaManager {
  override open class var classID: OcaClassID { OcaClassID("1.3.13") }
  override open class var classVersion: OcaClassVersionNumber { 3 }

  public convenience init() {
    self.init(objectNumber: OcaDiagnosticManagerONo)
  }

  public func getLockStatus(_ oNo: OcaONo) async throws -> OcaString {
    try await sendCommandRrq(methodID: OcaMethodID("3.1"), parameters: oNo)
  }
}
