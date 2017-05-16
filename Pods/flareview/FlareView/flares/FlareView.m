//The MIT License (MIT)
//
//Copyright (c) 2016 Stanly Moses <stanlyhardy@yahoo.com>
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.


#import "FlareView.h"

@implementation FlareView

static FlareView *sharedFlareViewCenter = nil;

+ (FlareView *)sharedCenter {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ // make sure sharedCenter has been initialed once in a life time
        if (!sharedFlareViewCenter) {
            sharedFlareViewCenter = [[super allocWithZone:NULL] init];
        }
    });
    return sharedFlareViewCenter;
}

-(void) flarify: (UIView* ) childView inParentView:(UIView*) rootView withColor : (UIColor *)fillColor {
    
    childView.userInteractionEnabled = NO; // prevent user presses continuously
    flareColor = fillColor;
    childView.transform = CGAffineTransformMakeTranslation(0, 20);
    childView.transform = CGAffineTransformMakeScale(0.01, 0.01);
    
    CGRect vortexFrame = CGRectMake(childView.frame.origin.x, childView.frame.origin.y, childView.frame.size.width, childView.frame.size.height);
    UIView* vortexView = [[UIView alloc] initWithFrame : vortexFrame];
    
    CAShapeLayer *vortexLayer = [CAShapeLayer layer];
    vortexView.bounds = childView.bounds;
    //set colors
    [vortexLayer setStrokeColor:[flareColor CGColor]];
    [vortexLayer setFillColor:[[UIColor clearColor] CGColor]];
    [vortexLayer setPath:[[UIBezierPath bezierPathWithOvalInRect:vortexView.bounds] CGPath]];
    [vortexView.layer addSublayer:vortexLayer];
    [rootView addSubview:vortexView];
    
    //Animate circle
    [vortexView setTransform : CGAffineTransformMakeScale(0, 0)];
    
    [UIView animateWithDuration : 0.75
                      animations:^{
                          [vortexView setTransform : CGAffineTransformMakeScale(1.3, 1.3)];
                      }
                      completion:^(BOOL finished)
     {
         vortexView.hidden = YES;
         //start next animation
         [self createFlares:childView rootView:rootView];
     }];
    
}

-(void) createFlares: (UIView*) childView rootView: (UIView *) rootView
{
    // set to initial value for childView before animation
    childView.hidden = false;
    childView.alpha = 1.0;
    
    [childView setTransform:CGAffineTransformMakeScale(0, 0)];
    //animate icon
    [UIView animateWithDuration:0.3/1.5 animations:^{
        childView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3/2 animations:^{
            childView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration : 0.3 / 2.0
                              animations:^{
                                  childView.transform = CGAffineTransformIdentity;
                              } completion:^(BOOL finished) {
                                  [UIView animateWithDuration:0.15 animations:^{
                                      childView.alpha = 0.0;
                                  } completion:^(BOOL finished) {
                                      childView.hidden = true;
                                      childView.transform = CGAffineTransformIdentity;
                                      childView.alpha = 1.0;
                                  }];
                              }];
        }];
    }];
    
    
    //add circles around the icon
    int numberOfFlares = 20;
    CGPoint center = childView.center;
    float radius= 55;
    BOOL isBurlyFlare = YES;;
    
    for (int i = 0; i<numberOfFlares; i++) {
        
        //x(t) = r cos(t) + j => r = radius; t= M_PI/numberOfCircles*i*2; j = center.x
        //y(t) = r sin(t) + j => r = radius; t= M_PI/numberOfCircles*i*2; j = center.y
        
        
        float x = radius*cos(M_PI/numberOfFlares*i*2) + center.x;
        float y = radius*sin(M_PI/numberOfFlares*i*2) + center.y;
        
        float circleRadius = 10;
        if (isBurlyFlare) {
            circleRadius = 5;
            isBurlyFlare = NO;
        }else{
            isBurlyFlare = YES;
        }
        
        UIView* vortexView = [[UIView alloc] initWithFrame:CGRectMake(x, y, circleRadius, circleRadius)];
        CAShapeLayer *circleLayer = [CAShapeLayer layer];
        [circleLayer setStrokeColor:[flareColor CGColor]];
        [circleLayer setFillColor:[flareColor CGColor]];
        [circleLayer setPath:[[UIBezierPath bezierPathWithOvalInRect:vortexView.bounds] CGPath]];
        [vortexView.layer addSublayer:circleLayer];
        [rootView addSubview:vortexView];
        
        //animate circles
        [UIView animateWithDuration:0.8 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [vortexView setTransform:CGAffineTransformMakeTranslation(radius/3*cos(M_PI/numberOfFlares*i*2), radius/3*sin(M_PI/numberOfFlares*i*2))];
            [vortexView setTransform:CGAffineTransformScale(vortexView.transform, 0.01, 0.01)];
        } completion:^(BOOL finished) {
            [vortexView setTransform:CGAffineTransformMakeScale(0, 0)];
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                // animate it to the identity transform (100% scale)
                childView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished){
                // if you want to do something once the animation finishes, put it here
                childView.userInteractionEnabled = YES;
            }];
        }];
        
        
    }
}
@end
