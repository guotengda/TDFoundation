//
//  Timer.swift
//  
//
//  Created by Sherlock on 2024/1/5.
//

import Foundation

/// GCD Timer.
/// For example:
///
///     TDTimer(interval: delay, handler: { (timer) in
///          self.containers[type.hudIdentify()]?.0.hide(animated: true, completion: completion)
///     })
public class TDTimer {
    
    public typealias TDTimerHandler = (TDTimer) -> Void
    
    private let internalTimer: DispatchSourceTimer
    public private(set) var isRunning = false
    private let repeats: Bool
    private var handler: TDTimerHandler
    
    public init(interval: DispatchTimeInterval, repeats: Bool = false, queue: DispatchQueue = .main, handler: @escaping TDTimerHandler) {
        self.handler = handler
        self.repeats = repeats
        internalTimer = DispatchSource.makeTimerSource(queue: queue)
        internalTimer.setEventHandler { [weak self] in
            if let strongSelf = self {
                handler(strongSelf)
            }
        }
        
        if repeats {
            internalTimer.schedule(deadline: .now() + interval, repeating: interval)
        } else {
            internalTimer.schedule(deadline: .now() + interval)
        }
    }
    
    deinit {
        if !self.isRunning {
            internalTimer.resume()
        }
    }
    
    public func fire() {
        if repeats {
            handler(self)
        } else {
            handler(self)
            isRunning = true
        }
    }
    
    public func start() {
        if !isRunning {
            internalTimer.resume()
            isRunning = true
        }
    }
    
    public func suspend() {
        if isRunning {
            internalTimer.suspend()
            isRunning = false
        }
    }
    
    public func rescheduleRepeating(interval: DispatchTimeInterval) {
        if repeats {
            internalTimer.schedule(deadline: .now() + interval, repeating: interval)
        }
    }
    
    public func rescheduleHandler(handler: @escaping TDTimerHandler) {
        self.handler = handler
        internalTimer.setEventHandler { [weak self] in
            if let strongSelf = self {
                handler(strongSelf)
            }
        }
    }
}

extension TDTimer {
    public static func repeaticTimer(interval: DispatchTimeInterval, isWallTime: Bool = false, queue: DispatchQueue = .main, handlder: @escaping TDTimerHandler) -> TDTimer {
        return TDTimer(interval: interval, repeats: true, queue: queue, handler: handlder)
    }
}

/// GCD Count Down Timer.
/// For example:
///
///     TDCountDownTimer(interval: .seconds(1), times: 120) { [weak self] (_, times) in
///          self?.timerRepeat(expire: times)
///     })
public class TDCountDownTimer {
    
    private let internalTimer: TDTimer
    private var leftTimes: Int
    private var originalTimes: Int
    private var handler: (TDCountDownTimer, _ surplus: Int) -> Void
    
    public var isRunning: Bool {
        return internalTimer.isRunning
    }
    
    public init(interval: DispatchTimeInterval, times: Int, isWallTime: Bool = false, queue: DispatchQueue = .main, handler: @escaping ((TDCountDownTimer, _ surplus: Int) -> Void)) {
        self.leftTimes = times
        self.originalTimes = times
        self.handler = handler
        self.internalTimer = TDTimer.init(interval: interval, repeats: true, queue: queue, handler: { _ in})
        self.internalTimer.rescheduleHandler { [weak self] (_) in
            if let strongSelf = self {
                if strongSelf.leftTimes > 0 {
                    strongSelf.leftTimes -= 1
                    strongSelf.handler(strongSelf, strongSelf.leftTimes)
                } else {
                    strongSelf.internalTimer.suspend()
                }
            }
        }
    }
    
    public func start() {
        internalTimer.start()
    }
    
    public func suspend() {
        internalTimer.suspend()
    }
    
    @discardableResult
    public func reCountDown(_ newTimes: Int? = nil) -> Self {
        if let newTimes = newTimes {
            originalTimes = newTimes
        }
        
        leftTimes = originalTimes
        return self
    }
    
    @discardableResult
    public func reSetConfig(newTimes: Int? = nil, interval: DispatchTimeInterval, handler: @escaping ((TDCountDownTimer, _ surplus: Int) -> Void)) -> Self {
        suspend()
        reCountDown(newTimes)
        self.handler = handler
        internalTimer.rescheduleRepeating(interval: interval)
        internalTimer.rescheduleHandler { [weak self] (_) in
            if let strongSelf = self {
                if strongSelf.leftTimes > 0 {
                    strongSelf.leftTimes -= 1
                    strongSelf.handler(strongSelf, strongSelf.leftTimes)
                } else {
                    strongSelf.internalTimer.suspend()
                }
            }
        }
        
        return self
    }
}

public extension DispatchTimeInterval {
    
    static func fromSeconds(_ seconds: Double) -> DispatchTimeInterval {
        return .milliseconds(Int(seconds * 1000))
    }
}
