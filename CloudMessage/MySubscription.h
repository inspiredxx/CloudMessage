//
//  MySubscription.h
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-23.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "EGORefreshTableHeaderView.h"

@interface MySubscription : UITableViewController <EGORefreshTableHeaderDelegate>
{
    User *user;
    UIActivityIndicatorView *activityIndicator;
    NSMutableArray *_mySubscriptionData;
    EGORefreshTableHeaderView *_refreshHeaderView;
    BOOL _reloading;
}

- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;

@end
