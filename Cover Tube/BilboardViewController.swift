//
//  BilboardViewController.swift
//  Cover Tube
//
//  Created by June Suh on 5/13/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import UIKit

class BilboardViewController:  UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self

        // Do any additional setup after loading the view.
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Set the number of items in your collection view.
        return 18
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Access
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BillboardCell", for: indexPath) as! BillboardViewControllerCell
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

}
