//
//  MsgOfSub.h
//  CloudMessage
//
//  Created by SoftwareLab on 14-6-12.
//  Copyright (c) 2014年 SoftwareLab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGORefreshTableHeaderView.h"

@interface MsgOfSub : UITableViewController <EGORefreshTableHeaderDelegate, NSURLConnectionDelegate>
{
    UIActivityIndicatorView *activityIndicator;
    EGORefreshTableHeaderView *_refreshHeaderView;
    BOOL _reloading;
}

@property (nonatomic, assign) NSString *rid;

@end
