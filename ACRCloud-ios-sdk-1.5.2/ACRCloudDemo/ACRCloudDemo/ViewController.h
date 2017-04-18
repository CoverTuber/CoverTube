//
//  ViewController.h
//  ACRCloudDemo
//
//  Created by olym on 15/3/29.
//  Copyright (c) 2015年 ACRCloud.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UILabel *volumeLabel;
@property (weak, nonatomic) IBOutlet UILabel *costLabel;
@property (weak, nonatomic) IBOutlet UITextView *resultView;

- (IBAction)startRecognition:(id)sender;

- (IBAction)stopRecognition:(id)sender;
@end

