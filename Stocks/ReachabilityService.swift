//
//  ReachabilityService.swift
//  Stocks
//
//  Created by Никита Зименко on 05.09.2021.
//

import Foundation
import Network

final class ReachabilityService {

    public private(set) var isConnected: Bool = true
    private let monitor = NWPathMonitor()

    init() {
        setupMonitor()
    }
}

// MARK: - Private

private extension ReachabilityService {

    func setupMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            print("[reachability] status: \(connected)")
            self?.isConnected = connected
         }

        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }
}
