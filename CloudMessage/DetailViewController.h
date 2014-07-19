//
//  DetailViewController.h
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-23.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "EGORefreshTableHeaderView.h"

@interface DetailViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, EGORefreshTableHeaderDelegate>
{
    UIActivityIndicatorView *activityIndicator;
    NSArray *_resourceData;
    User *user;
    EGORefreshTableHeaderView *_refreshHeaderView;
    BOOL _reloading;
}

- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;

@property (assign) NSString *cid;
@property int level;    //菜单级别

@end
