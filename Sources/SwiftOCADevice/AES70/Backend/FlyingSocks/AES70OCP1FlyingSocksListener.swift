//
//  AES70OCP1FlyingSocksListener.swift
//
//  Copyright (c) 2022 Simon Whitty. All rights reserved.
//  Portions Copyright (c) 2023 PADL Software Pty Ltd. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#if os(macOS) || os(iOS)

@_implementationOnly
import FlyingSocks
@_spi(Private) @_implementationOnly
import func FlyingSocks.withThrowingTimeout
import Foundation
import SwiftOCA

@AES70Device
public final class AES70OCP1FlyingSocksListener: AES70Listener {
    public var controllers: [AES70Controller] {
        _controllers
    }

    let pool: AsyncSocketPool

    private let address: sockaddr_storage
    private let timeout: TimeInterval
    private let logger: Logging? = AES70OCP1FlyingSocksListener.defaultLogger()
    private var _controllers = [AES70OCP1FlyingSocksController]()

    public convenience init(
        address: Data,
        timeout: TimeInterval = 15
    ) async throws {
        var storage = sockaddr_storage()
        _ = withUnsafeMutableBytes(of: &storage) { dst in
            address.withUnsafeBytes { src in
                memcpy(dst.baseAddress!, src.baseAddress!, src.count)
            }
        }
        try await self.init(address: storage, timeout: timeout)
    }

    public convenience init(
        path: String,
        timeout: TimeInterval = 15
    ) async throws {
        let address = sockaddr_un.unix(path: path).makeStorage()
        try await self.init(address: address, timeout: timeout)
    }

    private init(
        address: sockaddr_storage,
        timeout: TimeInterval = 15
    ) async throws {
        self.address = address
        self.timeout = timeout
        pool = Self.defaultPool(logger: logger)

        try await AES70Device.shared.add(listener: self)
    }

    var listeningAddress: Socket.Address? {
        try? state?.socket.sockname()
    }

    public func start() async throws {
        let socket = try await preparePoolAndSocket()
        do {
            #if canImport(Darwin)
            try? await startBonjour()
            #endif
            let task = Task { try await start(on: socket, pool: pool) }
            state = (socket: socket, task: task)
            defer { state = nil }
            try await task.getValue(cancelling: .whenParentIsCancelled)
        } catch {
            logger?.logCritical("server error: \(error.localizedDescription)")
            try? socket.close()
            throw error
        }
    }

    func preparePoolAndSocket() async throws -> Socket {
        do {
            try await pool.prepare()
            return try makeSocketAndListen()
        } catch {
            logger?.logCritical("server error: \(error.localizedDescription)")
            throw error
        }
    }

    var waiting: Set<Continuation> = []
    private(set) var state: (socket: Socket, task: Task<(), Error>)? {
        didSet { isListeningDidUpdate(from: oldValue != nil) }
    }

    public func stop(timeout: TimeInterval = 0) async {
        guard let (socket, task) = state else { return }
        try? socket.close()
        try? await task.getValue(cancelling: .afterTimeout(seconds: timeout))
        #if canImport(Darwin)
        stopBonjour()
        #endif
    }

    func makeSocketAndListen() throws -> Socket {
        let socket = try Socket(domain: Int32(address.ss_family))
        try socket.setValue(true, for: .localAddressReuse)
        #if canImport(Darwin)
        try socket.setValue(true, for: .noSIGPIPE)
        #endif
        try socket.bind(to: address)
        try socket.listen()
        logger?.logListening(on: socket)
        return socket
    }

    func start(on socket: Socket, pool: AsyncSocketPool) async throws {
        let asyncSocket = try AsyncSocket(socket: socket, pool: pool)

        return try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await pool.run()
            }
            group.addTask {
                try await self.listenForControllers(on: asyncSocket)
            }
            try await group.next()
        }
    }

    private func listenForControllers(on socket: AsyncSocket) async throws {
        #if compiler(>=5.9)
        if #available(macOS 14.0, iOS 17.0, tvOS 17.0, *) {
            try await listenForControllersDiscarding(on: socket)
        } else {
            try await listenForControllersFallback(on: socket)
        }
        #else
        try await listenForControllersFallback(on: socket)
        #endif
    }

    #if compiler(>=5.9)
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, *)
    private func listenForControllersDiscarding(on socket: AsyncSocket) async throws {
        try await withThrowingDiscardingTaskGroup { [logger] group in
            for try await socket in socket.sockets {
                group.addTask {
                    await self.handleController(AES70OCP1FlyingSocksController(
                        socket: socket,
                        logger: logger
                    ))
                }
            }
        }
        throw SocketError.disconnected
    }
    #endif

    @available(macOS, deprecated: 17.0, renamed: "listenForControllersDiscarding(on:)")
    @available(iOS, deprecated: 17.0, renamed: "listenForControllersDiscarding(on:)")
    @available(tvOS, deprecated: 17.0, renamed: "listenForControllersDiscarding(on:)")
    private func listenForControllersFallback(on socket: AsyncSocket) async throws {
        try await withThrowingTaskGroup(of: Void.self) { [logger] group in
            for try await socket in socket.sockets {
                group.addTask {
                    try await self.handleController(AES70OCP1FlyingSocksController(
                        socket: socket,
                        logger: logger
                    ))
                }
            }
        }
        throw SocketError.disconnected
    }

    private func handleController(_ controller: AES70OCP1FlyingSocksController) async {
        logger?.logControllerAdded(controller)
        _controllers.append(controller)
        do {
            for try await (message, rrq) in await controller.messages {
                var response: Ocp1Response?

                await controller.updateLastMessageReceivedTime()

                switch message {
                case let command as Ocp1Command:
                    logger?.logCommand(command, on: controller)
                    let commandResponse = await AES70Device.shared.handleCommand(
                        command,
                        timeout: timeout,
                        from: controller
                    )
                    response = Ocp1Response(
                        handle: command.handle,
                        statusCode: commandResponse.statusCode,
                        parameters: commandResponse.parameters
                    )
                case let keepAlive as Ocp1KeepAlive1:
                    await controller
                        .setKeepAliveInterval(UInt64(keepAlive.heartBeatTime) * NSEC_PER_SEC)
                case let keepAlive as Ocp1KeepAlive2:
                    await controller
                        .setKeepAliveInterval(UInt64(keepAlive.heartBeatTime) * NSEC_PER_MSEC)
                default:
                    throw Ocp1Error.invalidMessageType
                }

                if rrq, let response {
                    try await controller.sendMessage(response, type: .ocaRsp)
                }
                if let response {
                    logger?.logResponse(response, on: controller)
                }
            }
        } catch {
            logger?.logError(error, on: controller)
        }
        _controllers.removeAll(where: { $0 == controller })
        try? await controller.close()
        logger?.logControllerRemoved(controller)
    }

    static func defaultPool(logger: Logging? = nil) -> AsyncSocketPool {
        #if canImport(Darwin)
        return .kQueue(logger: logger)
        #elseif canImport(CSystemLinux)
        return .ePoll(logger: logger)
        #else
        return .poll(logger: logger)
        #endif
    }

    #if canImport(Darwin)
    private var netService: CFNetService?

    private func createNetService() async -> CFNetService? {
        // FIXME: add support for UDP, WS, etc

        let serviceType = "_oca._tcp"
        let serviceName = await (AES70Device.shared.deviceManager?.deviceName ?? "SwiftOCA") + "@" +
            Host.current()
            .localizedName!
        let domain = ""

        guard let port else { return nil }
        return CFNetServiceCreate(
            nil,
            domain as CFString,
            serviceType as CFString,
            serviceName as CFString,
            Int32(port)
        ).takeRetainedValue()
    }

    private func startBonjour() async throws {
        netService = await createNetService()
        if let netService {
            try scheduleNetService(netService)
        }
    }

    private func scheduleNetService(_ netService: CFNetService) throws {
        var error = CFStreamError()
        var clientContext = CFNetServiceClientContext()
        CFNetServiceSetClient(netService, registerCallback, &clientContext)
        CFNetServiceScheduleWithRunLoop(
            netService,
            CFRunLoopGetCurrent(),
            CFRunLoopMode.commonModes!.rawValue
        )
        guard CFNetServiceRegisterWithOptions(netService, 0, &error) else {
            stopBonjour()
            throw Ocp1Error.bonjourRegistrationFailed
        }
    }

    private func stopBonjour() {
        if let netService {
            CFNetServiceUnscheduleFromRunLoop(
                netService,
                CFRunLoopGetCurrent(),
                CFRunLoopMode.commonModes!.rawValue
            )
            CFNetServiceSetClient(netService, nil, nil)
            self.netService = nil
        }
    }

    private var port: UInt16? {
        var address = address
        var port: UInt16?

        switch address.ss_family {
        case sa_family_t(AF_INET):
            withUnsafePointer(to: &address) {
                $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                    port = UInt16(bigEndian: $0.pointee.sin_port)
                }
            }
        case sa_family_t(AF_INET6):
            withUnsafePointer(to: &address) {
                $0.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) {
                    port = UInt16(bigEndian: $0.pointee.sin6_port)
                }
            }
        default:
            port = nil
        }
        return port
    }
    #endif
}

extension Logging {
    func logControllerAdded(_ controller: AES70OCP1FlyingSocksController) {
        logInfo("\(controller.identifier) controller added")
    }

    func logControllerRemoved(_ controller: AES70OCP1FlyingSocksController) {
        logInfo("\(controller.identifier) controller removed")
    }

    func logCommand(_ command: Ocp1Command, on controller: AES70OCP1FlyingSocksController) {
        logInfo("\(controller.identifier) command: \(command)")
    }

    func logResponse(_ response: Ocp1Response, on controller: AES70OCP1FlyingSocksController) {
        logInfo("\(controller.identifier) command: \(response)")
    }

    func logError(_ error: Error, on controller: AES70OCP1FlyingSocksController) {
        logError("\(controller.identifier) error: \(error.localizedDescription)")
    }

    func logListening(on socket: Socket) {
        logInfo(Self.makeListening(on: try? socket.sockname()))
    }

    static func makeListening(on addr: Socket.Address?) -> String {
        var comps = ["starting server"]
        guard let addr = addr else {
            return comps.joined()
        }

        switch addr {
        case let .ip4(address, port: port):
            if address == "0.0.0.0" {
                comps.append("port: \(port)")
            } else {
                comps.append("\(address):\(port)")
            }
        case let .ip6(address, port: port):
            if address == "::" {
                comps.append("port: \(port)")
            } else {
                comps.append("\(address):\(port)")
            }
        case let .unix(path):
            comps.append("path: \(path)")
        }
        return comps.joined(separator: " ")
    }
}

extension AES70OCP1FlyingSocksListener {
    public var isListening: Bool { state != nil }

    func waitUntilListening(timeout: TimeInterval = 5) async throws {
        try await withThrowingTimeout(seconds: timeout) {
            try await self.doWaitUntilListening()
        }
    }

    private func doWaitUntilListening() async throws {
        guard !isListening else { return }
        let continuation = Continuation()
        waiting.insert(continuation)
        defer { waiting.remove(continuation) }
        return try await continuation.value
    }

    func isListeningDidUpdate(from previous: Bool) {
        guard isListening else { return }
        let waiting = waiting
        self.waiting = []

        for continuation in waiting {
            continuation.resume()
        }
    }

    typealias Continuation = CancellingContinuation<(), Never>
}

#if canImport(Darwin)
private func registerCallback(
    _ theService: CFNetService,
    _ error: UnsafeMutablePointer<CFStreamError>?,
    _ info: UnsafeMutableRawPointer?
) {
    debugPrint("registered network service \(theService)")
}
#endif

#endif
