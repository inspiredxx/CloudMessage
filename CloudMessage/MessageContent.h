//
//  MessageContent.h
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-30.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASValueTrackingSlider.h"

@interface MessageContent : UIViewController <UIWebViewDelegate, UIScrollViewDelegate, ASValueTrackingSliderDataSource>

@property (nonatomic, assign) IBOutlet UIWebView *webView;
@property (nonatomic, retain) NSString *content;

@end
