//
//  Touch.swift
//  ExTouchView
//
//  Created by 김종권 on 2023/11/09.
//

import UIKit

open class TouchesWindow: UIWindow {
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
        defer { super.sendEvent(event) }
        
        guard
            toucheEntitySet != nil,
            let allTouches = event.allTouches
        else { return }
        
        var beganTouches = Set<UITouch>()
        var endedTouches = Set<UITouch>()
        
        allTouches
            .forEach { touch in
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
        handleTouchesMoved(touches: allTouches)
        handleTouchesEnded(touches: endedTouches)
        
        super.sendEvent(event)
    }
    
    private func getTouchEntity(forTouch touch: UITouch) -> TouchEntity? {
        toucheEntitySet.first(where: { $0.touch == touch })
    }
    
    private func handleTouchesBegan(touches: Set<UITouch>) {
        for touch in touches {
            let view = TouchView()
            view.layer.zPosition = CGFloat(Float.greatestFiniteMagnitude)
            let touchEntity = TouchEntity(touch: touch, view: view)
            
            toucheEntitySet.insert(touchEntity)
            addSubview(view)
        }
    }
    
    private func handleTouchesMoved(touches: Set<UITouch>) {
        for touch in touches {
            let touchEntity = getTouchEntity(forTouch: touch)
            touchEntity?.view.center = touchEntity?.touch.location(in: self) ?? .zero
        }
    }
    
    func handleTouchesEnded(touches: Set<UITouch>) {
        for touch in touches {
            guard let touchEntity = getTouchEntity(forTouch:touch) else { continue }
            touchEntity.view.removeFromSuperview()
            toucheEntitySet.remove(touchEntity)
        }
    }
}

// MARK: TouchView

private class TouchView : UIView {
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

private class TouchEntity: Hashable {
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
        lhs.touch == rhs.touch
    }
}

