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

@testable import SwiftOCA
@testable import SwiftOCADevice
import XCTest

class MyBooleanActuator: SwiftOCADevice.OcaBooleanActuator {
    override open class var classID: OcaClassID { OcaClassID(parent: super.classID, 65280) }
}

extension OcaGetPortNameParameters: Equatable {
    public static func == (lhs: OcaGetPortNameParameters, rhs: OcaGetPortNameParameters) -> Bool {
        lhs.portID == rhs.portID
    }
}

extension Ocp1Parameters: Equatable {
    public static func == (lhs: Ocp1Parameters, rhs: Ocp1Parameters) -> Bool {
        lhs.parameterData == rhs.parameterData && lhs.parameterCount == rhs.parameterCount
    }
}

extension Ocp1Command: Equatable {
    public static func == (lhs: SwiftOCA.Ocp1Command, rhs: SwiftOCA.Ocp1Command) -> Bool {
        lhs.commandSize == rhs.commandSize &&
            lhs.handle == rhs.handle &&
            lhs.targetONo == rhs.targetONo &&
            lhs.methodID == rhs.methodID &&
            lhs.parameters == rhs.parameters
    }
}

final class SwiftOCADeviceTests: XCTestCase {
    func testSingleFieldOcp1Encoding() async throws {
        let parameters = OcaGetPortNameParameters(portID: OcaPortID(mode: .input, index: 2))
        let encodedParameters: [UInt8] = try Ocp1Encoder().encode(parameters)
        XCTAssertEqual(encodedParameters, [0x01, 0x00, 0x02])

        let command = Ocp1Command(
            commandSize: 0,
            handle: 100,
            targetONo: 5000,
            methodID: OcaMethodID("2.6"),
            parameters: Ocp1Parameters(
                parameterCount: _ocp1ParameterCount(value: parameters),
                parameterData: Data(encodedParameters)
            )
        )
        let encodedCommand: [UInt8] = try Ocp1Encoder().encode(command)
        XCTAssertEqual(
            encodedCommand,
            [0, 0, 0, 0, 0, 0, 0, 100, 0, 0, 19, 136, 0, 2, 0, 6, 1, 1, 0, 2]
        )

        let decodedCommand = try Ocp1Decoder().decode(Ocp1Command.self, from: encodedCommand)
        XCTAssertEqual(command, decodedCommand)

        let decodedParameters = try Ocp1Decoder()
            .decode(OcaGetPortNameParameters.self, from: decodedCommand.parameters.parameterData)
        XCTAssertEqual(parameters, decodedParameters)
    }

    func testMultipleFieldOcp1Encoding() async throws {
        let parameters = OcaBoundedPropertyValue<OcaInt64>(value: -100, minValue: -200, maxValue: 0)
        let encodedParameters: [UInt8] = try Ocp1Encoder().encode(parameters)
        XCTAssertEqual(
            encodedParameters,
            [255, 255, 255, 255, 255, 255, 255, 156, 255, 255, 255, 255, 255, 255, 255, 56, 0, 0, 0,
             0, 0, 0, 0, 0]
        )

        let command = Ocp1Command(
            commandSize: 0,
            handle: 101,
            targetONo: 5001,
            methodID: OcaMethodID("4.1"),
            parameters: Ocp1Parameters(
                parameterCount: _ocp1ParameterCount(value: parameters),
                parameterData: Data(encodedParameters)
            )
        )
        let encodedCommand: [UInt8] = try Ocp1Encoder().encode(command)
        XCTAssertEqual(
            encodedCommand,
            [0, 0, 0, 0, 0, 0, 0, 101, 0, 0, 19, 137, 0, 4, 0, 1, 3, 255, 255, 255, 255, 255, 255,
             255, 156, 255, 255, 255, 255, 255, 255, 255, 56, 0, 0, 0, 0, 0, 0, 0, 0]
        )

        let decodedCommand = try Ocp1Decoder().decode(Ocp1Command.self, from: encodedCommand)
        XCTAssertEqual(command, decodedCommand)

        let decodedParameters = try Ocp1Decoder()
            .decode(
                OcaBoundedPropertyValue<OcaInt64>.self,
                from: decodedCommand.parameters.parameterData
            )
        XCTAssertEqual(parameters, decodedParameters)
    }

    func testUnicodeStringEncoding() async throws {
        let string = "✨Unicode✨"
        let encodedString =
            Data([0, 9, 226, 156, 168, 85, 110, 105, 99, 111, 100, 101, 226, 156, 168])

        let ocp1Encoder = Ocp1Encoder()
        XCTAssertEqual(try ocp1Encoder.encode(string), encodedString)

        let ocp1Decoder = Ocp1Decoder()
        XCTAssertEqual(try ocp1Decoder.decode(String.self, from: encodedString), string)
    }

    func testUnicodeScalarEncoding() async throws {
        let string = "🍎"
        let encodedString = Data([0, 1, 0xF0, 0x9F, 0x8D, 0x8E])

        let ocp1Encoder = Ocp1Encoder()
        XCTAssertEqual(try ocp1Encoder.encode(string), encodedString)

        let ocp1Decoder = Ocp1Decoder()
        XCTAssertEqual(try ocp1Decoder.decode(String.self, from: encodedString), string)
    }

    func testAsciiStringEncoding() async throws {
        let string = "ASCII"
        let encodedString = Data([0, 5, 0x41, 0x53, 0x43, 0x49, 0x49])

        let ocp1Encoder = Ocp1Encoder()
        XCTAssertEqual(try ocp1Encoder.encode(string), encodedString)

        let ocp1Decoder = Ocp1Decoder()
        XCTAssertEqual(try ocp1Decoder.decode(String.self, from: encodedString), string)
    }

    func testEmptyStringEncoding() async throws {
        let string = ""
        let encodedString = Data([0, 0])

        let ocp1Encoder = Ocp1Encoder()
        XCTAssertEqual(try ocp1Encoder.encode(string), encodedString)

        let ocp1Decoder = Ocp1Decoder()
        XCTAssertEqual(try ocp1Decoder.decode(String.self, from: encodedString), string)
    }

    func testLoopbackDevice() async throws {
        let device = OcaDevice.shared
        try await device.initializeDefaultObjects()
        let listener = try await OcaLocalDeviceEndpoint()

        let matrix = try await SwiftOCADevice
            .OcaMatrix<MyBooleanActuator>(
                rows: 4,
                columns: 2,
                deviceDelegate: device
            )

        for x in 0..<matrix.members.nX {
            for y in 0..<matrix.members.nY {
                let coordinate = OcaVector2D(x: OcaMatrixCoordinate(x), y: OcaMatrixCoordinate(y))
                let actuator = try await MyBooleanActuator(
                    role: "Actuator \(x),\(y)",
                    deviceDelegate: device
                )
                try matrix.add(member: actuator, at: coordinate)
            }
        }

        let deviceMembers = await device.rootBlock.actionObjects
        let connection = await OcaLocalConnection(listener)
        Task { await listener.run() }
        try await connection.connect()

        let deviceExpectation = XCTestExpectation(description: "Check device properties")
        var oNo = await connection.deviceManager.objectNumber
        XCTAssertEqual(oNo, OcaDeviceManagerONo)
        oNo = await connection.subscriptionManager.objectNumber
        XCTAssertEqual(oNo, OcaSubscriptionManagerONo)
        let path = await matrix.objectNumberPath
        XCTAssertEqual(path, [OcaRootBlockONo, matrix.objectNumber])
        deviceExpectation.fulfill()
        await fulfillment(of: [deviceExpectation], timeout: 1)

        let controllerExpectation = XCTestExpectation(description: "Check controller properties")
        let members = try await connection.rootBlock.resolveActionObjects()
        XCTAssertEqual(members.map(\.objectNumber), deviceMembers.map(\.objectNumber))
        controllerExpectation.fulfill()

        await fulfillment(of: [controllerExpectation], timeout: 1)

        try await connection.disconnect()
    }
}

/// https://github.com/apple/swift-corelibs-xctest/issues/436
extension XCTestCase {
    /// Wait on an array of expectations for up to the specified timeout, and optionally specify
    /// whether they
    /// must be fulfilled in the given order. May return early based on fulfillment of the waited on
    /// expectations.
    ///
    /// - Parameter expectations: The expectations to wait on.
    /// - Parameter timeout: The maximum total time duration to wait on all expectations.
    /// - Parameter enforceOrder: Specifies whether the expectations must be fulfilled in the order
    ///   they are specified in the `expectations` Array. Default is false.
    /// - Parameter file: The file name to use in the error message if
    ///   expectations are not fulfilled before the given timeout. Default is the file
    ///   containing the call to this method. It is rare to provide this
    ///   parameter when calling this method.
    /// - Parameter line: The line number to use in the error message if the
    ///   expectations are not fulfilled before the given timeout. Default is the line
    ///   number of the call to this method in the calling file. It is rare to
    ///   provide this parameter when calling this method.
    ///
    /// - SeeAlso: XCTWaiter
    func fulfillment(
        of expectations: [XCTestExpectation],
        timeout: TimeInterval,
        enforceOrder: Bool = false
    ) async {
        await withCheckedContinuation { continuation in
            // This function operates by blocking a background thread instead of one owned by
            // libdispatch or by the
            // Swift runtime (as used by Swift concurrency.) To ensure we use a thread owned by
            // neither subsystem, use
            // Foundation's Thread.detachNewThread(_:).
            Thread.detachNewThread { [self] in
                wait(for: expectations, timeout: timeout, enforceOrder: enforceOrder)
                continuation.resume()
            }
        }
    }
}
