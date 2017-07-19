//
//  TouchableView.swift
//  MouseApp-Client
//
//  Created by ajay singh thakur on 18/07/17.
//  Copyright © 2017 ajay singh thakur. All rights reserved.
//

import UIKit

class COSTouchSpotView : UIImageView {
    
    var timeStamp : TimeInterval = 0.0
    var shouldAutomaticallyRemoveAfterTimeout : Bool = true
    var isFadingOut : Bool = false
}


class TouchableView: UIView {
    
    //MARK: Properties
    var touchViews = [UITouch:COSTouchSpotView]()

    var touchImage: UIImage?
    var touchAlpha: CGFloat = 0.0
    var fadeDuration = TimeInterval()
    var strokeColor: UIColor?
    var fillColor: UIColor?
    // Ripple Effects
    var rippleImage: UIImage?
    var rippleAlpha: CGFloat = 0.0
    var rippleFadeDuration = TimeInterval()
    var rippleStrokeColor: UIColor?
    var rippleFillColor: UIColor?
    
    
    //stationaryMorphEnabled
    var stationaryMorphEnabled : Bool = true
    
    //
    var timer : Timer?
    var fingerTipRemovalScheduled : Bool = false
    
    //MARK: init method's
    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        self.cosTouchVisualizerWindow_commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isMultipleTouchEnabled = true
        self.cosTouchVisualizerWindow_commonInit()
    }
    
    func cosTouchVisualizerWindow_commonInit() {
        strokeColor = UIColor.black
        fillColor = UIColor.init(red: 150/255, green: 210/255, blue: 226/255, alpha: 1)//UIColor.white
        touchAlpha = 1//0.5
        fadeDuration = 0.3
        
        
        rippleStrokeColor = UIColor.white
        rippleFillColor = UIColor.init(red: 1/255, green: 130/255, blue: 176/255, alpha: 1)//UIColor.blue
        rippleAlpha = 1//0.2
        rippleFadeDuration = 0.2
        
        
        stationaryMorphEnabled = true
    }
    
    //MARK: override touch method's
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            self.touchPhaseBegin(touch)
        }// for loop completed
        //self.scheduleFingerTipRemoval()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            self.touchPhaseMoved(touch)
            self.touchPhaseBegin(touch)
        }
        // self.scheduleFingerTipRemoval()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for touch in touches {
//            //print("touch phase in \(touch.phase.rawValue)")
//            //removeViewForTouch(touch: touch)
//           
//        }
        for touch in touches {
            let view = self.viewForTouch(touch: touch)
            self.removeFingerTip(withHash: view, animated: true)
            //removeViewForTouch(touch: touch)
        }
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let view = self.viewForTouch(touch: touch)
            self.removeFingerTip(withHash: view, animated: true)
            //removeViewForTouch(touch: touch)
        }
    }
    
    // Other methods. . . 
    func createViewForTouch( touch : UITouch ) {
        let newView = TouchSpotView()
        newView.bounds = CGRect(x: 0, y: 0, width: 1, height: 1)
        newView.center = touch.location(in: self)
        
        // Add the view and animate it to a new size.
        addSubview(newView)
        UIView.animate(withDuration: 0.2) {
            newView.bounds.size = CGSize(width: 100, height: 100)
        }
        
        // Save the views internally
        // touchViews[touch] = newView
    }
    
    func viewForTouch (touch : UITouch) -> COSTouchSpotView? {
        return touchViews[touch]
    }
    
    func removeViewForTouch (touch : UITouch ) {
        if let view = touchViews[touch] {
            view.removeFromSuperview()
            touchViews.removeValue(forKey: touch)
        }
    }
}
extension TouchableView {

    //MARK: Touch begin and moved function
    func touchPhaseBegin(_ touch : UITouch) -> Void {
        var touchView = viewForTouch(touch: touch)
        //print(touchView)
        // 1st case
        if touchView != nil && touchView?.isFadingOut == true {
            
            self.timer?.invalidate()
            touchView?.removeFromSuperview()
            touchView = nil
        }
        
        //2nd Case
        if touchView == nil {
            
            let touchImage = self.getTouchImage()
            touchView = COSTouchSpotView.init(image: touchImage)
            self.addSubview(touchView!)
            touchViews[touch] = touchView
        }
        
        //3rd case
        if touchView?.isFadingOut == false {
            
            touchView?.alpha = self.touchAlpha
            touchView?.center = touch.location(in: self)
            touchViews[touch] = touchView
            touchView?.timeStamp = touch.timestamp
            touchView?.shouldAutomaticallyRemoveAfterTimeout = self.shouldAutomaticallyRemoveFingerTip(for: touch)
            
        }
    }
    func touchPhaseMoved(_ touch : UITouch) -> Void {
        let rippleImage = self.getRippleImage()
        let rippleView = COSTouchSpotView.init(image: rippleImage)//viewForTouch(touch: touch)
        self.addSubview(rippleView)
        // self.touchViews[touch] = rippleView
        rippleView.alpha = rippleAlpha
        rippleView.center = touch.location(in: self)
        UIView.animate(withDuration: rippleFadeDuration, delay: 0.0, options: .curveEaseIn, animations: {() -> Void in
            rippleView.alpha = 0.0
            rippleView.frame = rippleView.frame.insetBy(dx: 25, dy: 25)
        }, completion: {(_ finished: Bool) -> Void in
            rippleView.removeFromSuperview()
        })
    }
}
extension TouchableView {
    

    

    //MARK: return image's for touch and moved
    func getTouchImage() -> UIImage? {
       
            let clipPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 50.0, height: 50.0))
            UIGraphicsBeginImageContextWithOptions(clipPath.bounds.size, false, 0)
            let drawPath = UIBezierPath(arcCenter: CGPoint(x: 25.0, y: 25.0), radius: 22.0, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
            drawPath.lineWidth = 2.0
            strokeColor?.setStroke()
            fillColor?.setFill()
            drawPath.stroke()
            drawPath.fill()
            clipPath.addClip()
          let touchImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        
        return touchImage
    }
    
    func getRippleImage() -> UIImage? {
        
            let clipPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 50.0, height: 50.0))
            UIGraphicsBeginImageContextWithOptions(clipPath.bounds.size, false, 0)
            let drawPath = UIBezierPath(arcCenter: CGPoint(x: 25.0, y: 25.0), radius: 22.0, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
            drawPath.lineWidth = 2.0
            rippleStrokeColor?.setStroke()
            rippleFillColor?.setFill()
            drawPath.stroke()
            drawPath.fill()
            clipPath.addClip()
            rippleImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
       
        return rippleImage
    }
   
    


}
extension TouchableView {

    //MARK : Touch Removal option's
    
    //  Converted with Swiftify v1.0.6402 - https://objectivec2swift.com/
    func scheduleFingerTipRemoval() {
        if fingerTipRemovalScheduled {
            return
        }
        fingerTipRemovalScheduled = true
        perform(#selector(self.removeInactiveFingerTips), with: nil, afterDelay: 0.1)
    }
    
    func cancelScheduledFingerTipRemoval() {
        fingerTipRemovalScheduled = true
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.removeInactiveFingerTips), object: nil)
    }

    //  Converted with Swiftify v1.0.6402 - https://objectivec2swift.com/
    func removeInactiveFingerTips() {
        fingerTipRemovalScheduled = false
        let now: TimeInterval = ProcessInfo().systemUptime
        let REMOVAL_DELAY: Double = 0.2
        for touchView  in self.subviews {
            if !(touchView is COSTouchSpotView) {
                continue
            }
            let view = touchView as! COSTouchSpotView
            if view.shouldAutomaticallyRemoveAfterTimeout == true && now > view.timeStamp + REMOVAL_DELAY {
                
                removeFingerTip(withHash: view, animated: true)
                
            }
        }
        if self.subviews.count > 0 {
            scheduleFingerTipRemoval()
        }
    }
    
    
    //
    func removeFingerTip(withHash hash: COSTouchSpotView?, animated: Bool) {
        let touchView: COSTouchSpotView? = hash
        if touchView == nil {
            return
        }
        if (touchView?.isFadingOut)! {
            return
        }
        let animationsWereEnabled: Bool = UIView.areAnimationsEnabled
        if animated {
            UIView.setAnimationsEnabled(true)
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(fadeDuration)
        }
        touchView?.frame = CGRect(x: (touchView?.center.x)! - (touchView?.frame.size.width)!, y: (touchView?.center.y)! - (touchView?.frame.size.height)!, width: (touchView?.frame.size.width)! * 2, height: (touchView?.frame.size.height)! * 2)
        touchView?.alpha = 0.0
        
        if animated {
            UIView.commitAnimations()
            UIView.setAnimationsEnabled(animationsWereEnabled)
        }
        touchView?.isFadingOut = true
        touchView?.perform(#selector(removeFromSuperview), with: nil, afterDelay: fadeDuration)
        
    }
    
    
    func shouldAutomaticallyRemoveFingerTip(for touch: UITouch) -> Bool {
        var view: UIView? = touch.view
        view = view?.hitTest(touch.location(in: view), with: nil)
        while view != nil {
            if (view is UITableViewCell) {
                for recognizer: UIGestureRecognizer in touch.gestureRecognizers! {
                    if (recognizer is UISwipeGestureRecognizer) {
                        return true
                    }
                }
            }
            if (view is UITableView) {
                if touch.gestureRecognizers?.count == 0 {
                    return true
                }
            }
            view = view?.superview
        }
        return false
    }
    
}
