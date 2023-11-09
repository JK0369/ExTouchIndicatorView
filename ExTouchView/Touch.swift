//
//  Touch.swift
//  ExTouchView
//
//  Created by 김종권 on 2023/11/09.
//

import UIKit

open class TouchesWindow: UIWindow {
    public var touchesColor = UIColor(white: 0, alpha: 0.5)
    public var touchesRadius = 20.0
    
    public var touchesEnabled: Bool = false {
        didSet {
            if touchesEnabled && toucheEntitySet == nil {
                toucheEntitySet = Set<TouchEntity>()
            } else if !touchesEnabled && toucheEntitySet != nil {
                toucheEntitySet.forEach({ $0.view.removeFromSuperview() })
                toucheEntitySet = nil
            }
        }
    }
    
    private var toucheEntitySet: Set<TouchEntity>!
    
    open override func sendEvent(_ event: UIEvent) {
        if toucheEntitySet != nil, let allTOuches = event.allTouches {
            var beganTouches = Set<UITouch>()
            var endedTouches = Set<UITouch>()
            
            for touch in allTOuches {
                switch (touch.phase) {
                case .began:
                    beganTouches.insert(touch)
                case .ended, .cancelled:
                    endedTouches.insert(touch)
                case .moved, .stationary, .regionEntered, .regionMoved, .regionExited:
                    // no-op
                    break
                @unknown default:
                    // no-op
                    break
                }
            }
            
            handleTouchesBegan(touches: beganTouches)
            handleTouchesMoved(touches: allTOuches)
            handleTouchesEnded(touches: endedTouches)
        }
        
        super.sendEvent(event)
    }
    
    private func getTouchEntity(forTouch touch: UITouch) -> TouchEntity? {
        for touchEntity in toucheEntitySet {
            if touchEntity.touch == touch {
                return touchEntity
            }
        }
        
        return nil
    }
    
    private func handleTouchesBegan(touches: Set<UITouch>) {
        for touch in touches {
            let alpha = touchesColor.dmz_alpha
            let forceColor = touchesColor.withAlphaComponent(alpha/2)
            
            let view = TouchView(radius: touchesRadius)
            view.setCoreColor(touchesColor)
            view.setForceColor(forceColor)
            view.layer.zPosition = CGFloat(Float.greatestFiniteMagnitude)
            
            let touchEntity = TouchEntity(touch: touch, view: view)
            
            toucheEntitySet.insert(touchEntity)
            
            addSubview(view)
        }
    }
    
    private func handleTouchesMoved(touches: Set<UITouch>) {
        for touch in touches {
            var forceRadius: CGFloat = 0
            if dmz_forceTouchAvailable {
                forceRadius = (touch.force - 0.5) / (touch.maximumPossibleForce - 0.5)
                forceRadius = max(0, forceRadius)
            }
            
            let touchEntity = getTouchEntity(forTouch:touch)!
            touchEntity.hasBeenMoved = (touchEntity.hasBeenMoved || (touch.force == 0 && touch.phase == .moved))
            touchEntity.view.center = touchEntity.touch.location(in: self)
            touchEntity.view.setForceRadius(touchEntity.hasBeenMoved == false ? forceRadius : 0)
        }
    }
    
    func handleTouchesEnded(touches: Set<UITouch>) {
        for touch in touches {
            let touchEntity = getTouchEntity(forTouch:touch)!
            touchEntity.view.removeFromSuperview()
            toucheEntitySet.remove(touchEntity)
        }
    }
}

// MARK: UIColor alpha extension

fileprivate extension UIColor {
    var dmz_alpha: CGFloat {
        return CIColor(color: self).alpha
    }
}

// MARK: UIWindow force touch extension

fileprivate extension UIWindow {
    var dmz_forceTouchAvailable: Bool {
        if #available(iOS 9.0, *) {
            return traitCollection.forceTouchCapability == .available
        }
        return false
    }
}

// MARK: TouchView

fileprivate class TouchView : UIView {
    private let core: UIView
    private let force: UIView
    
    public init(radius: CGFloat) {
        let frame = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)
        
        force = UIView(frame: frame)
        force.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        force.layer.masksToBounds = true
        force.layer.cornerRadius = radius
        
        core = UIView(frame: frame)
        core.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        core.layer.masksToBounds = true
        core.layer.cornerRadius = radius
        
        super.init(frame: frame)
        
        addSubview(force)
        addSubview(core)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setCoreColor(_ coreColor: UIColor) {
        core.backgroundColor = coreColor
    }
    
    public func setForceColor(_ forceColor: UIColor) {
        force.backgroundColor = forceColor
    }
    
    public func setForceRadius(_ forceRadius: CGFloat) {
        let scale = 1.0 + 0.6 * forceRadius
        force.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}

// MARK: TouchEntity

fileprivate class TouchEntity: Hashable {
    let touch: UITouch
    let view: TouchView
    var hasBeenMoved: Bool = false
    
    init(touch: UITouch, view: TouchView) {
        self.touch = touch
        self.view = view
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(touch.hashValue)
    }
    
    public static func ==(lhs: TouchEntity, rhs: TouchEntity) -> Bool {
        return lhs.touch == rhs.touch
    }
}

