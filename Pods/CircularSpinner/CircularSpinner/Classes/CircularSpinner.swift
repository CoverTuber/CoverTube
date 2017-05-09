//
//  CircularSpinner.swift
//  CircularSpinnerExample
//
//  Created by Matteo Tagliafico on 15/09/16.
//  Copyright © 2016 Matteo Tagliafico. All rights reserved.
//

// Modified by June Suh 2017/05/06 to not have singular object

import UIKit

@objc public protocol CircularSpinnerDelegate: NSObjectProtocol {
    @objc optional func circularSpinnerTitleForValue(_ value: Float) -> NSAttributedString
}


@objc public enum CircularSpinnerType: Int {
    case determinate
    case indeterminate
}

open class CircularSpinner: UIView {
    
    // MARK: - outlets
    /*
    @IBOutlet fileprivate weak var circleView: UIView!
    @IBOutlet fileprivate weak var circleViewWidth: NSLayoutConstraint! {
        didSet {
            layoutIfNeeded()
        }
    }
 */
    
    @IBOutlet public weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var dismissButton: UIButton!
    
    // MARK: - properties
    open weak var delegate: CircularSpinnerDelegate?
    fileprivate var mainView: UIView!
    fileprivate let nibName = "CircularSpinner"
    
    fileprivate var backgroundCircleLayer = CAShapeLayer()
    fileprivate var progressCircleLayer = CAShapeLayer()
    
    var indeterminateDuration: Double = 1.5
    
    fileprivate var startAngle: CGFloat {
        return 3.5 * CGFloat( Double.pi / 4 )
    }
    fileprivate var endAngle: CGFloat {
        return 0.5 * CGFloat(Double.pi / 4)
    }
    fileprivate var arcCenter: CGPoint {
        return CGPoint(x: bounds.size.width / 2.0, y : bounds.size.height / 2.0)
            // convert(circleView.center, to: circleView)
    }
    fileprivate var arcRadius: CGFloat {
        return (min(bounds.width, bounds.height) * 0.8) / 2
    }
    
    fileprivate var oldStrokeEnd: Float?
    fileprivate var backingValue: Float = 0
    open override var frame: CGRect {
        didSet {
            if frame == CGRect.zero { return }
            
            backgroundCircleLayer.frame = bounds
            progressCircleLayer.frame = bounds
            // circleView.center = center
        }
    }
    open var value: Float {
        get {
            return backingValue
        }
        set {
            backingValue = min(1, max(0, newValue))
        }
    }
    open var type: CircularSpinnerType = .determinate {
        didSet {
            configureType()
        }
    }
    open static var dismissButton: Bool = true
    open var showDismissButton = dismissButton {
        didSet {
            appearanceDismissButton()
        }
    }
    open static var trackLineWidth: CGFloat = 6
    private var lineWidth = trackLineWidth {
        didSet {
            appearanceBackgroundLayer()
            appearanceProgressLayer()
        }
    }
    
    private var bgColor = UIColor(colorLiteralRed: 220.0/255, green: 220.0/255, blue: 220.0/255, alpha: 1)
        {
        didSet {
            appearanceBackgroundLayer()
        }
    }
    
    private var pgColor = UIColor(colorLiteralRed: 47.0/255, green: 177.0/255, blue: 254.0/255, alpha: 1) {
        didSet {
            appearanceProgressLayer()
        }
    }
    
    
    // MARK: - view lifecycle
    public override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func xibSetup() {
        mainView = loadViewFromNib()
        mainView.frame = bounds
        mainView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        addSubview(mainView)
    }
    
    fileprivate func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return view
    }
    
    
    // MARK: - drawing methods
    open override func draw(_ rect: CGRect) {
        backgroundCircleLayer.path = getCirclePath()
        progressCircleLayer.path = getCirclePath()
        // updateFrame()
    }
    
    fileprivate func getCirclePath() -> CGPath {
        return UIBezierPath(arcCenter: arcCenter, radius: arcRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true).cgPath
    }
    
    
    // MARK: - configure
    fileprivate func configure() {
        backgroundColor = UIColor.clear
        
        // configureCircleView()
        configureBackgroundLayer()
        configureProgressLayer()
        configureDismissButton()
        configureType()
    }
    
    /*
    fileprivate func configureCircleView() {
        circleViewWidth.constant = arcRadius * 2
    }
    */
    
    fileprivate func configureBackgroundLayer() {
        layer.addSublayer(backgroundCircleLayer)
        // circleView.layer.addSublayer(backgroundCircleLayer)
        appearanceBackgroundLayer()
    }
    
    fileprivate func configureProgressLayer() {
        layer.addSublayer(progressCircleLayer)
        // circleView.layer.addSublayer(progressCircleLayer)
        appearanceProgressLayer()
    }
    
    fileprivate func configureDismissButton() {
        appearanceDismissButton()
    }
    
    fileprivate func configureType() {
        switch type {
        case .indeterminate:
            startInderminateAnimation()
        default:
            oldStrokeEnd = nil
            updateTitleLabel()
        }
    }
    
    
    
    // MARK: - appearance
    fileprivate func appearanceBackgroundLayer() {
        backgroundCircleLayer.lineWidth = lineWidth
        backgroundCircleLayer.fillColor = UIColor.clear.cgColor
        backgroundCircleLayer.strokeColor = bgColor.cgColor
        backgroundCircleLayer.lineCap = kCALineCapRound
    }
    
    fileprivate func appearanceProgressLayer() {
        progressCircleLayer.lineWidth = lineWidth
        progressCircleLayer.fillColor = UIColor.clear.cgColor
        progressCircleLayer.strokeColor = pgColor.cgColor
        progressCircleLayer.lineCap = kCALineCapRound
    }
    
    fileprivate func appearanceDismissButton() {
        dismissButton.isHidden = !showDismissButton
    }
    
    
    // MARK: - methods
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        // updateFrame()
    }
    
    fileprivate func generateAnimation() -> CAAnimationGroup {
        let headAnimation = CABasicAnimation(keyPath: "strokeStart")
        headAnimation.beginTime = indeterminateDuration / 3
        headAnimation.fromValue = 0
        headAnimation.toValue = 1
        headAnimation.duration = indeterminateDuration / 1.5
        headAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let tailAnimation = CABasicAnimation(keyPath: "strokeEnd")
        tailAnimation.fromValue = 0
        tailAnimation.toValue = 1
        tailAnimation.duration = indeterminateDuration / 1.5
        tailAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let groupAnimation = CAAnimationGroup()
        groupAnimation.duration = indeterminateDuration
        groupAnimation.repeatCount = Float.infinity
        groupAnimation.animations = [headAnimation, tailAnimation]
        return groupAnimation
    }
    
    fileprivate func generateRotationAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0
        animation.toValue = 2 * M_PI
        animation.duration = indeterminateDuration
        animation.repeatCount = Float.infinity
        return animation
    }
    
    fileprivate func startInderminateAnimation() {
        progressCircleLayer.add(generateAnimation(), forKey: "strokeLineAnimation")
        // circleView.layer.add(generateRotationAnimation(), forKey: "rotationAnimation")
        layer.add(generateRotationAnimation(), forKey: "rotationAnimation")
    }
    
    fileprivate func stopInderminateAnimation() {
        progressCircleLayer.removeAllAnimations()
        // circleView.layer.removeAllAnimations()
        layer.removeAllAnimations()
    }
    
    
    // MARK: - update
    open func setValue(_ value: Float, animated: Bool) {
        guard self.type == .determinate else { return }
        
        self.value = value
        updateTitleLabel()
        setStrokeEnd(animated: animated) {
            if value >= 1 {
                self.hide()
            }
        }
    }
    
    fileprivate func updateTitleLabel() {
        if let attributeStr = delegate?.circularSpinnerTitleForValue?(value) {
            self.titleLabel.attributedText = attributeStr
        } else {
            self.titleLabel.text = "\(Int(value * 100))%"
        }
    }
    
    fileprivate func setStrokeEnd(animated: Bool, completed: (() -> Void)? = nil) {
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setCompletionBlock({
            completed?()
        })
        
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.duration = animated ? 0.66 : 0
        strokeAnimation.repeatCount = 1
        strokeAnimation.fromValue = oldStrokeEnd ?? 0
        strokeAnimation.toValue = self.value
        strokeAnimation.isRemovedOnCompletion = false
        strokeAnimation.fillMode = kCAFillModeRemoved
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        progressCircleLayer.add(strokeAnimation, forKey: "strokeLineAnimation")
        progressCircleLayer.strokeEnd = CGFloat(self.value)
        CATransaction.commit()
        
        oldStrokeEnd = self.value
    }
    
    
    // MARK: - actions
    @IBAction fileprivate func dismissButtonTapped(_ sender: UIButton?) {
        self.hide()
    }
}


// MARK: - API
extension CircularSpinner {
    
    open func show(_ title: String = "", animated: Bool = true, type: CircularSpinnerType = .determinate, showDismissButton: Any? = nil, delegate: CircularSpinnerDelegate? = nil)
    {
        self.type = type
        self.delegate = delegate
        self.titleLabel.text = title
        self.showDismissButton = (showDismissButton as? Bool) ?? CircularSpinner.dismissButton
        self.value = 0
        // self.updateFrame()
        
        if self.superview == nil {
            self.alpha = 0
            
            UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseOut, animations: {
                self.alpha = 1
                }, completion: nil)
        }
        
        // NotificationCenter.default.addObserver(self, selector: #selector(updateFrame), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
    }
    
    open func hide(_ completion: (() -> Void)? = nil) {
        self.stopInderminateAnimation()
        
        NotificationCenter.default.removeObserver(self)
        
        DispatchQueue.main.async(execute: {
            if self.superview == nil {
                return
            }
            
            UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseOut, animations: {
                self.alpha = 0
                }, completion: { _ in
                    self.alpha = 1
                    self.removeFromSuperview()
                    completion?()
            })
        })
    }
}
