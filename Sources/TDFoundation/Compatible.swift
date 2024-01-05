//
//  Compatible.swift
//  
//
//  Created by Sherlock on 2024/1/5.
//

import Foundation
import TDStability

// MARK: - Compatible for Foundation
extension String: Compatible {}
extension Date: Compatible {}
extension Int64: Compatible {}
extension DispatchQueue: Compatible {}
extension NotificationCenter: Compatible {}

// MARK: NotificationCenter

extension TD where Base: NotificationCenter {
    
    /// Convenience for 'addObserver(forName:object:queue:using:)'
    ///
    /// Use to add observer for a Notification.Name callback by a closure and doesn't need to run 'removeObserver(_:)' when deinit
    ///
    /// For example:
    ///
    ///     NotificationCenter.default.td.addObserver(self, name: Notification.Name.td.TableView.finishPull, object: nil) { (target, noti) in
    ///         target?.//do something
    ///     }
    ///
    /// - Parameters:
    ///   - observer: the receiver of notification. in closure, observer is weak reference
    ///   - name: the name of the notification for which to register the observer; that is, only notifications with this name are used to add the block to the operation queue.
    ///   - anObject: the object whose notifications the observer wants to receive; that is, only notifications sent by this sender are delivered to the observer.
    ///   - queue: the operation queue to which block should be added. If you pass nil, the block is run synchronously on the posting thread.
    ///   - handler: The block to be executed when the notification is received. The block is copied by the notification center and (the copy) held until the observer registration is removed
    /// - Returns: the object which is 'true' observer for NotificationCenter
    @discardableResult
    public func addObserver<T: AnyObject>(_ observer: T, name: Notification.Name, object anObject: Any?, queue: OperationQueue? = OperationQueue.main, handler: @escaping (_ observer: T?, _ notification: Notification) -> Void) -> AnyObject {
        let observation = base.addObserver(forName: name, object: anObject, queue: queue) { [weak observer] noti in handler(observer, noti) }
        TDObserveationRemover.init(observation).makeRetainBy(observer)
        return observation
    }
}

private class TDObserveationRemover: NSObject {
    
    let observation: NSObjectProtocol
    
    init(_ obs: NSObjectProtocol) { observation = obs; super.init() }
    deinit { NotificationCenter.default.removeObserver(observation) }
    
    func makeRetainBy(_ owner: AnyObject) { TD_observationRemoversForObject(owner).add(self) }
}

private var kTDObservationRemoversForObject = "\(#file)+\(#line)"
private func TD_observationRemoversForObject(_ object: AnyObject) -> NSMutableArray {
    return objc_getAssociatedObject(object, &kTDObservationRemoversForObject) as? NSMutableArray ?? NSMutableArray.init().then {
        objc_setAssociatedObject(object, &kTDObservationRemoversForObject, $0, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: DispatchQueue

extension DispatchQueue {
    
    fileprivate static var _onceTracker = [String].init()
}

extension TD where Base: DispatchQueue {
    
    /// Safely to use 'DispatchQueue.queue.async {}' on any queue, it can check whether is main queue
    /// If is in main queue, the closure will execute immediately, other will execute asynchronously
    ///
    /// - Parameter block: the closure whick need to run
    public func safeAsync(_ block: @escaping () -> Void) {
        if base === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            base.async {
                block()
            }
        }
    }
    
    /// Convenience function to call 'dispatch_once' on the encapsulated closure.
    ///
    /// - Parameters:
    ///   - token: the tag marked as one for closure.
    ///   - block: the closure will run once
    static func once(token: String, block: ()-> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        guard Base._onceTracker.contains(token) else { return }
        Base._onceTracker.append(token)
        block()
    }
}

// MARK: String

extension TD where Base == String {

    public func substring(from index: Int, count: Int) -> String {
        if base.count > index && base.count >= index + count {
            let startIndex = base.index(base.startIndex, offsetBy: index)
            let endIndex = base.index(base.startIndex, offsetBy: index + count)
            let subString = base[startIndex..<endIndex]
            
            return String(subString)
        } else {
            return ""
        }
    }
    
    public func toData() -> Data { return base.data(using: .utf8) ?? Data.init() }
    
    /// Check 'self' is an URLString by regular expression '(http|https)://([\\w-]+\\.)+[\\w-]+(/[\\w-./?%&=]*)?$'
    public var isURL: Bool {
        return NSPredicate(format: "SELF MATCHES %@", "(http|https)://([\\w-]+\\.)+[\\w-]+(/[\\w-./?%&=]*)?$").evaluate(with:base)
    }
    
    /// Check 'self' is all numbers by 'Scanner'
    public var isAllDigit: Bool {
        var value: Int = 0
        let scanner = Scanner(string: base)
        return scanner.scanInt(&value) && scanner.isAtEnd
    }
    
    /// Check 'self' length are satisfied with size. use closed interval
    ///
    /// - Parameter tuple: the size of 'self' need to satisfy. less than 0 is not limited  like: (3, 6) or (-1, 12)
    /// - Returns: true is satified, false is not
    public func check(forLength tuple:(Int, Int)) -> Bool {
        guard tuple.0 <= tuple.1 || tuple.1 < 0 else { return false }
        return (tuple.0 < 0 ? true : base.count >= tuple.0) && (tuple.1 < 0 ? true : base.count <= tuple.1)
    }
    
    /// Returns a new string made by removing from both ends of the String characters contained whitespaces
    public func trimWhitespace() -> String {
        return base.trimmingCharacters(in: .whitespaces)
    }
}


