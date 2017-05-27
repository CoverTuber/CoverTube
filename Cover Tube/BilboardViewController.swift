//
//  BilboardViewController.swift
//  Cover Tube
//
//  Created by June Suh on 5/13/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit

class BilboardViewController:  UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate
{

    @IBOutlet weak var collectionView: UICollectionView!
    
    // var playlist : [Playlist]?
    
    var isMoreDataLoading: Bool = false
    
    // MARK: View Controller Life Cycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /*
         Add notification
         */
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.reloadCollectionView),
                                               name: FetchedPopularVideoNotificationName,
                                               object: nil)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: Collection view functions
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Set the number of items in your collection view.
        return YouTube.shared.bilboardVideos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Access
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BillboardCell", for: indexPath) as! BillboardViewControllerCell
        
        let video = YouTube.shared.bilboardVideos[indexPath.item]
        print("bilboard dequeue -> video = \(video.title)")
        
        cell.title.text = video.title
        cell.uploader.text = "uploader"
        cell.views.text = String(5)
        // Do any custom modifications you your cell, referencing the outlets you defined in the Custom cell file.
        //cell.backgroundColor = UIColor.whiteColor()
        //cell.label.text = "item \(indexPath.item)"
        
        
        
        return cell
    }
    
    //These flow functions fix the space in between the cells apparetly
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        
        return 4
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        
        return 1
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Handle scroll behavior here
        if (!isMoreDataLoading) {
            let scrollViewContentHeight = collectionView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - collectionView.bounds.size.height
            
            if(scrollView.contentOffset.y > scrollOffsetThreshold && collectionView.isDragging) {
                isMoreDataLoading = true
                
                // ... Code to load more results ...
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func reloadCollectionView ()
    {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }

}
