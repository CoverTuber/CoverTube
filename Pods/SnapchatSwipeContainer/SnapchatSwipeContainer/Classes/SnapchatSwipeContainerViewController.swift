//
//  SnapchatSwipeContainerViewController.swift
//  Pods
//
//  Created by Jack Colley on 05/02/2017.
//
//

import UIKit

open class SnapchatSwipeContainerViewController : UIViewController {
    
    /// The left most UIViewController in the container
    public var leftVC: UIViewController!
    
    /// The middle UIViewController in the container - usually the one you want land on
    public var middleVC: UIViewController!
    
    /// The right most UIViewController in the container
    public var rightVC: UIViewController!
    
    /// Use this to set which screen you want to land on - defaults to the middle if not set
    public var initialContentOffset: CGPoint?
    
    /// The UIScrollView that will act as the container
    public var scrollView: UIScrollView!
    
    /// Should the container bounce when it is scrolled past its limits - default false
    public var shouldContainerBounce: Bool = false

    /*
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
    }
    */
    
    open func setupScrollView(viewControllers : [UIViewController] )
    {
        // Create the UIScrollView and add it to the view
        scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = shouldContainerBounce
        
        scrollView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        
        view.addSubview(scrollView)
        
        // Setting the content size for the UIScrollView
        let scrollWidth = 3 * scrollView.frame.width
        
        scrollView.contentSize = CGSize(width: scrollWidth, height: scrollView.frame.height)
        
        // Set left, middle, right view controllers
        leftVC = viewControllers[0]
        middleVC = viewControllers[1]
        rightVC = viewControllers[2]
        
        // Setting the frames for our view controllers
        leftVC.view.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        
        middleVC.view.frame = CGRect(x: view.frame.width, y: 0, width: view.frame.width, height: view.frame.height)
        
        rightVC.view.frame = CGRect(x: 2 * view.frame.width, y: 0, width: view.frame.width, height: view.frame.height)
        
        scrollView.addSubview(leftVC.view)
        scrollView.addSubview(middleVC.view)
        scrollView.addSubview(rightVC.view)
        
        // Setting the contentOffset for the UIScrollView
        if let initialContentOffset = initialContentOffset {
            scrollView.contentOffset = initialContentOffset
        } else {
            let offset = CGPoint(x: middleVC.view.frame.origin.x, y: middleVC.view.frame.origin.y)
            scrollView.contentOffset = offset
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
