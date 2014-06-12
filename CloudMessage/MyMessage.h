//
//  MyMessage.h
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-23.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "MosquittoClient.h"
#import "EGORefreshTableFooterView.h"
#import "SINavigationMenuView.h"

@interface MyMessage : UITableViewController <MosquittoClientDelegate, EGORefreshTableDelegate, SINavigationMenuDelegate>
{
    UIActivityIndicatorView *activityIndicator;
    User *user;
    EGORefreshTableFooterView *_refreshFooterView;
    BOOL _isLoading;
}

@property (nonatomic, strong) IBOutlet UIScrollView *scrollForHideNavigation;

- (void)getMoreTableViewDataSource;
- (void)doneGettingTableViewData:(NSArray *)data;

@end
