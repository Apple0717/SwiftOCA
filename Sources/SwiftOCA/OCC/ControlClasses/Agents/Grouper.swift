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

open class OcaGrouper: OcaAgent {
    override public class var classID: OcaClassID { OcaClassID("1.2.2") }
    override public class var classVersion: OcaClassVersionNumber { 3 }

    public struct AddGroupParameters: Ocp1ParametersReflectable {
        public let index: OcaUint16
        public let proxyONo: OcaONo

        public init(index: OcaUint16, proxyONo: OcaONo) {
            self.index = index
            self.proxyONo = proxyONo
        }
    }

    public struct SetEnrollmentParameters: Ocp1ParametersReflectable {
        public let enrollment: OcaGrouperEnrollment
        public let isMember: OcaBoolean

        public init(enrollment: OcaGrouperEnrollment, isMember: OcaBoolean) {
            self.enrollment = enrollment
            self.isMember = isMember
        }
    }

    @OcaProperty(
        propertyID: OcaPropertyID("3.1"),
        getMethodID: OcaMethodID("3.12"),
        setMethodID: OcaMethodID("3.13")
    )
    public var actuatorOrSensor: OcaProperty<Bool>.PropertyValue

    @OcaProperty(
        propertyID: OcaPropertyID("3.2"),
        getMethodID: OcaMethodID("3.4")
    )
    public var groups: OcaProperty<OcaGrouperGroup>.PropertyValue

    @OcaProperty(
        propertyID: OcaPropertyID("3.3"),
        getMethodID: OcaMethodID("3.8")
    )
    public var citizens: OcaProperty<OcaGrouperCitizen>.PropertyValue

    @OcaProperty(
        propertyID: OcaPropertyID("3.4")
    )
    public var enrollments: OcaProperty<OcaGrouperEnrollment>.PropertyValue

    @OcaProperty(
        propertyID: OcaPropertyID("3.3"),
        getMethodID: OcaMethodID("3.14"),
        setMethodID: OcaMethodID("3.15")
    )
    public var mode: OcaProperty<OcaGrouperMode>.PropertyValue

    func getGroupMemberList(index: OcaUint16) async throws -> [OcaGrouperCitizen] {
        try await sendCommandRrq(methodID: OcaMethodID("3.11"), parameters: index)
    }
}
