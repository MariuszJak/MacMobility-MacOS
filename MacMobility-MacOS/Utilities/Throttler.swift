//
//  Throttler.swift
//  MacMobility-MacOS
//
//  Created by Mariusz Jakowienko on 25/08/2025.
//

import Foundation
import Combine

class Throttler<T> {
    private var cancellable: AnyCancellable?
    private let subject = PassthroughSubject<T, Never>()
    var action: ((T) -> Void)?

    init(seconds: Double = 1) {
        cancellable = subject
            .throttle(for: .seconds(seconds), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] value in
                self?.action?(value)
            }
    }

    func send(_ value: T) {
        subject.send(value)
    }
}
