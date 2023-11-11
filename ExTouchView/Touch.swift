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
            if !touchesEnabled {
                touchInfoSet.forEach({ $0.view.removeFromSuperview() })
            }
        }
    }
    
    private var touchInfoSet = Set<TouchInfo>()
    
    open override func sendEvent(_ event: UIEvent) {
        defer { super.sendEvent(event) }
        
        guard let allTouches = event.allTouches else { return }
        
        var beganTouches = Set<UITouch>()
        var endedTouches = Set<UITouch>()
        
        allTouches
            .forEach { touch in
                switch touch.phase {
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
    
    private func getTouchInfo(forTouch touch: UITouch) -> TouchInfo? {
        touchInfoSet.first(where: { $0.touch == touch })
    }
    
    private func handleTouchesBegan(touches: Set<UITouch>) {
        touches
            .forEach { touch in
                let view = TouchView()
                view.layer.zPosition = .greatestFiniteMagnitude
                let touchInfo = TouchInfo(touch: touch, view: view)
                
                touchInfoSet.insert(touchInfo)
                addSubview(view)
            }
    }
    
    private func handleTouchesMoved(touches: Set<UITouch>) {
        touches
            .forEach { touch in
                let touchInfo = getTouchInfo(forTouch: touch)
                touchInfo?.view.center = touchInfo?.touch.location(in: self) ?? .zero
            }
    }
    
    func handleTouchesEnded(touches: Set<UITouch>) {
        touches
            .compactMap { getTouchInfo(forTouch: $0) }
            .forEach { touchInfo in
                touchInfo.view.removeFromSuperview()
                touchInfoSet.remove(touchInfo)
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

// MARK: TouchInfo

private class TouchInfo: Hashable {
    let touch: UITouch
    let view: TouchView
    
    init(touch: UITouch, view: TouchView) {
        self.touch = touch
        self.view = view
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(touch.hashValue)
    }
    
    public static func ==(lhs: TouchInfo, rhs: TouchInfo) -> Bool {
        lhs.touch == rhs.touch
    }
}

