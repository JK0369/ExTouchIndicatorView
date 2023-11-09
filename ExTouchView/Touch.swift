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
                default:
                    // .moved, .stationary, .regionEntered, .regionMoved, .regionExited:
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
            
            let view = TouchView()
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
            touchEntity.view.center = touchEntity.touch.location(in: self)
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
    public init() {
        super.init(frame: .init(x: 0, y: 0, width: 50, height: 50))
        backgroundColor = .blue.withAlphaComponent(0.3)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2
    }
}

// MARK: TouchEntity

fileprivate class TouchEntity: Hashable {
    let touch: UITouch
    let view: TouchView
    
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

