//
//  StoreConnector.swift
//  Pods
//
//  Created by Steven Chan on 30/12/15.
//
//

import UIKit

public protocol StoreDelegate {

    func storeDidUpdateState(_ lastState: ReduxAppState)

}

open class StoreConnector {
    typealias Disconnect = () -> Void

    var connections: [Int: Disconnect] = [Int: Disconnect]()

    public init () {}

    public func connect(_ store: ReduxStore, keys: [String], delegate: StoreDelegate) {
        let address: Int = unsafeBitCast(store, to: Int.self)

        var lastState: ReduxAppState?
        if let storeState = store.getState() as? ReduxAppState {
            lastState = storeState
        }

        connections[address] = store.subscribe {
            if let storeState = store.getState() as? ReduxAppState {

                let k: [String] = keys.filter {
                    if let storeValue = storeState.get($0),
                        let lastValue = lastState?.get($0) {
                            return !storeValue.equals(lastValue)
                    }
                    return false
                }

                if k.count > 0 && lastState != nil {
                    delegate.storeDidUpdateState(lastState!)
                }

                lastState = storeState
            }
        }
    }

    public func disconnect(_ store: ReduxStore) {
        let address: Int = unsafeBitCast(store, to: Int.self)
        connections[address]!()
        connections.removeValue(forKey: address)
    }
}

public extension UIViewController {
    fileprivate struct AssociatedKeys {
        static var connector: StoreConnector?
    }

    var storeConnector: StoreConnector? {
        get {
            return objc_getAssociatedObject(
                self,
                &AssociatedKeys.connector
            ) as? StoreConnector
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.connector,
                    newValue as AnyObject,
                    objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
        }
    }

    func connect(_ store: ReduxStore, keys: [String], delegate: StoreDelegate) {
        if storeConnector == nil {
            storeConnector = StoreConnector()
        }

        storeConnector?.connect(store, keys: keys, delegate: delegate)
    }

    func disconnect(_ store: ReduxStore) {
        storeConnector?.disconnect(store)
    }
}
