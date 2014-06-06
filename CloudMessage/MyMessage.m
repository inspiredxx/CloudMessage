//
//  MyMessage.m
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-23.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import "MyMessage.h"
#import "ASIFormDataRequest.h"
#import "SVProgressHUD.h"
#import "SBJSON.h"
#import "PublicDefinition.h"
#import "LoginViewController.h"
#import "AppDelegate.h"
#import "MessageContent.h"
#import "CMNavBarNotificationView.h"

@interface MyMessage ()
{
    NSMutableArray *_myMessageData;
    NSInteger _messageCount;
    NSInteger _unreadMessageCount;
    NSInteger _messageIndex;
    BOOL flag;
    CGFloat lastOffsetY;
    BOOL isDecelerating;
    NSMutableDictionary *_userDefaultsDic;
}

@end

@implementation MyMessage

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    //登录验证
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:ACCESS_TOKEN];
    if (accessToken == nil) {
        NSLog(@"\n登录\n");
        LoginViewController *loginViewController = [[[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil] autorelease];
        [self presentViewController:loginViewController animated:YES completion:^{
            NSLog(@"\nLogin VC\n");
            user = [User sharedUser];
            [self dataInit];
            [self.tableView reloadData];
        }];
    } else {
        user = [User sharedUser];
        [self dataInit];
    }

}

- (void)dataInit
{
    NSArray *messageCountArray = [NSArray arrayWithArray:[User getMessageCount]];
    NSLog(@"\nMessage count: %d\nUnread count: %d\n", [[messageCountArray objectAtIndex:0] intValue], [[messageCountArray objectAtIndex:1] intValue]);
    
    //读取用户配置
    //    _userDefaultsDic = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:[User getUid]]];
    //读取消息数目
    //    if ([_userDefaultsDic objectForKey:MESSAGE_COUNT] == nil) {
    //        _messageCount = 0;
    //    } else {
    //        _messageCount = [[_userDefaultsDic objectForKey:MESSAGE_COUNT] intValue];
    //        NSLog(@"\nMessage count: %d\n", _messageCount);
    //    }
    _messageCount = [[messageCountArray objectAtIndex:0] intValue];
    _messageIndex = MAX(0, _messageCount-25);
    
    //读取本地消息
    _myMessageData = [[NSMutableArray alloc] initWithArray:[User getMessageInfoByLimit: _messageCount-_messageIndex offset:_messageIndex]];
    //按照时间排序
    [_myMessageData sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        if ([[obj1 objectForKey:@"include_time"] compare:[obj2 objectForKey:@"include_time"]] == NSOrderedDescending) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
    
    //初始化未读消息数目
    //    if ([_userDefaultsDic objectForKey:UNREAD_MESSAGE_COUNT] == nil) {
    //        _unreadMessageCount = 0;
    //        [UIApplication sharedApplication].applicationIconBadgeNumber = nil;
    //    } else {
    //        _unreadMessageCount = [[_userDefaultsDic objectForKey:UNREAD_MESSAGE_COUNT] intValue];
    //        if (_unreadMessageCount > 0) {
    //            AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    //            [[[app.tabBarController.tabBar items]objectAtIndex:0] setBadgeValue:[NSString stringWithFormat:@"%d", _unreadMessageCount]];
    //            [UIApplication sharedApplication].applicationIconBadgeNumber = _unreadMessageCount;
    //        }
    //    }
    _unreadMessageCount = [[messageCountArray objectAtIndex:1] intValue];
    if (_unreadMessageCount > 0){
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [[[app.tabBarController.tabBar items]objectAtIndex:0] setBadgeValue:[NSString stringWithFormat:@"%d", _unreadMessageCount]];
        [UIApplication sharedApplication].applicationIconBadgeNumber = _unreadMessageCount;
    }
    
    flag = YES;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    for (UIView *view in self.tabBarController.view.subviews)
    {
        [UIView animateWithDuration:0.1 animations:^{
            if([view isKindOfClass:[UITabBar class]] == NO)
            {
                NSLog(@"\n%@ /*480*/568\n", view.description);
                [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, /*480*/568)];
            }
        }];
    }
    
    NSLog(@"获取我的消息！");

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    NSLog(@"\nSave message count: %d\n", _messageCount);
//    [_userDefaultsDic setObject:[NSString stringWithFormat:@"%d", _messageCount] forKey:MESSAGE_COUNT];
//    NSLog(@"\nSave unread message count: %d\n", _unreadMessageCount);
//    [_userDefaultsDic setObject:[NSString stringWithFormat:@"%d", _unreadMessageCount] forKey:UNREAD_MESSAGE_COUNT];
//    [_userDefaultsDic setObject:_myMessageData forKey:MY_SUBSCRIPTION];
//    [[NSUserDefaults standardUserDefaults] setObject:_userDefaultsDic forKey:[User getUid]];
//    [[NSUserDefaults standardUserDefaults] synchronize];
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)getMoreTableViewDataSource
{
    NSLog(@"\n加载更多\n");
    NSArray *loadedData = nil;
    if (_messageIndex > 0) {
        _isLoading = YES;
//        _messageIndex = MAX(0, _messageIndex - 25);
        loadedData = [[NSArray alloc] initWithArray:[User getMessageInfoByLimit:_messageIndex-MAX(0, _messageIndex-25) offset:MAX(0, _messageIndex-25)]];
        
        _messageIndex -= [loadedData count];
        NSLog(@"\n_messageIndex: %d", _messageIndex);
    }
    [self doneGettingTableViewData:loadedData];    
}

- (void)doneGettingTableViewData:(NSArray *)data
{
    NSLog(@"\n加载完成\n");
    if ([data count] == 0) {
        [CMNavBarNotificationView notifyWithText:@"没有更多消息了" detail:nil andDuration:0.2];
         NSLog(@"\n没有更多消息了\n");
    } else {
        [CMNavBarNotificationView notifyWithText:@"加载完成" detail:[NSString stringWithFormat:@"读取%d条消息", [data count]] andDuration:0.3];
        [_myMessageData addObjectsFromArray:data];
        //按照时间排序
        [_myMessageData sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
            if ([[obj1 objectForKey:@"include_time"] compare:[obj2 objectForKey:@"include_time"]] == NSOrderedDescending) {
                return NSOrderedAscending;
            } else {
                return NSOrderedDescending;
            }
        }];
        [self.tableView reloadData];
    }
    _isLoading = NO;
	[_refreshFooterView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    [self hideTabBar:NO];
    [_refreshFooterView removeFromSuperview];
    _refreshFooterView = nil;
}

#pragma mark
#pragma Navigation hide Scroll
/*
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
    isDecelerating = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    isDecelerating = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(self.scrollForHideNavigation != scrollView)
        return;
    if(scrollView.frame.size.height >= scrollView.contentSize.height)
        return;
    
    if(scrollView.contentOffset.y > -self.navigationController.navigationBar.frame.size.height && scrollView.contentOffset.y < 0)
        scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
    else if(scrollView.contentOffset.y >= 0)
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    if(lastOffsetY < scrollView.contentOffset.y && scrollView.contentOffset.y >= -self.navigationController.navigationBar.frame.size.height){//moving up
        
        if(self.navigationController.navigationBar.frame.size.height + self.navigationController.navigationBar.frame.origin.y  > 0){//not yet hidden
            float newY = self.navigationController.navigationBar.frame.origin.y - (scrollView.contentOffset.y - lastOffsetY);
            if(newY < -self.navigationController.navigationBar.frame.size.height)
                newY = -self.navigationController.navigationBar.frame.size.height;
            self.navigationController.navigationBar.frame = CGRectMake(self.navigationController.navigationBar.frame.origin.x,
                                                                       newY,
                                                                       self.navigationController.navigationBar.frame.size.width,
                                                                       self.navigationController.navigationBar.frame.size.height);
        }
    }else
        if(self.navigationController.navigationBar.frame.origin.y < [UIApplication sharedApplication].statusBarFrame.size.height  &&
           (self.scrollForHideNavigation.contentSize.height > self.scrollForHideNavigation.contentOffset.y + self.scrollForHideNavigation.frame.size.height)){//not yet shown
            float newY = self.navigationController.navigationBar.frame.origin.y + (lastOffsetY - scrollView.contentOffset.y);
            if(newY > [UIApplication sharedApplication].statusBarFrame.size.height)
                newY = [UIApplication sharedApplication].statusBarFrame.size.height;
            self.navigationController.navigationBar.frame = CGRectMake(self.navigationController.navigationBar.frame.origin.x,
                                                                       newY,
                                                                       self.navigationController.navigationBar.frame.size.width,
                                                                       self.navigationController.navigationBar.frame.size.height);
        }
    
    lastOffsetY = scrollView.contentOffset.y;
}
 */

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
//    NSLog(@"\nscroll content: %f\n", scrollView.contentSize.height);
//    NSLog(@"\nTableView ContentSize: %f\n", self.tableView.contentSize.height);
    [self hideTabBar:YES];
    CGFloat height = MAX(self.tableView.contentSize.height, self.tableView.frame.size.height);
    if (_refreshFooterView == nil) {
		_refreshFooterView = [[EGORefreshTableFooterView alloc] initWithFrame:CGRectMake(0.0f, height, self.tableView.frame.size.width, self.view.bounds.size.height)];
		_refreshFooterView.delegate = self;
        [self.tableView addSubview:_refreshFooterView];
	} else {
        [self.tableView reloadData];
        [_refreshFooterView setFrame:CGRectMake(0.0f, height, self.tableView.frame.size.width, self.view.bounds.size.height)];        
    }
	
	//  update the last update date
	[_refreshFooterView refreshLastUpdatedDate];
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{    
	
	[_refreshFooterView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	[_refreshFooterView egoRefreshScrollViewDidEndDragging:scrollView];
	if (_isLoading == NO) {
        NSLog(@"\nNo\n");
        [self hideTabBar:NO];
    }
	
}

- (void) hideTabBar:(BOOL) hidden
{
    for(UIView *view in self.tabBarController.view.subviews)
    {
        [UIView animateWithDuration:0.2 animations:^{
            if([view isKindOfClass:[UITabBar class]])
            {
                if (hidden) {
                    [view setFrame:CGRectMake(view.frame.origin.x, /*480*/568, view.frame.size.width, view.frame.size.height)];
                } else {
                    [view setFrame:CGRectMake(view.frame.origin.x, /*480*/568-49, view.frame.size.width, view.frame.size.height)];
                }
            }
            else
            {
//                if (hidden) {
//                    [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 480)];
//                } else {
//                    [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 480-49)];
//                }
            }
        }];
    }
}

#pragma mark -
#pragma mark EGORefreshTableDelegate Methods

- (void)egoRefreshTableDidTriggerRefresh:(EGORefreshPos)aRefreshPos
{
    [self getMoreTableViewDataSource];
}

- (BOOL)egoRefreshTableDataSourceIsLoading:(UIView*)view
{
    return _isLoading;
}

- (NSDate*)egoRefreshTableDataSourceLastUpdated:(UIView*)view
{
    return [NSDate date];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_myMessageData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    NSDictionary *obj = [_myMessageData objectAtIndex:[indexPath row]];
    if (obj != nil) {
        cell.textLabel.text = [obj objectForKey:@"title"];
        if ([[obj objectForKey:@"read_flag"] isEqual:@"false"]) {
//            NSLog(@"这是一条未读消息");
            [cell.textLabel setTextColor:[UIColor redColor]];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"未读 %@ %@", [obj objectForKey:@"include_time"], [obj objectForKey:@"abstract"]];
            [cell.detailTextLabel setTextColor:[UIColor redColor]];
        } else {
            [cell.textLabel setTextColor:[UIColor blackColor]];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", [obj objectForKey:@"include_time"], [obj objectForKey:@"abstract"]];
            [cell.detailTextLabel setTextColor:[UIColor blackColor]];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"删除消息");
    NSDictionary *obj = [_myMessageData objectAtIndex:[indexPath row]];
    [_myMessageData removeObject:obj];
    [User deleteMessageByMid:[obj objectForKey:@"mid"]];
    if ([[obj objectForKey:@"read_flag"] isEqualToString:@"false"]) {
        _unreadMessageCount --;
        [UIApplication sharedApplication].applicationIconBadgeNumber = _unreadMessageCount;
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [[[app.tabBarController.tabBar items]objectAtIndex:0] setBadgeValue:[NSString stringWithFormat:@"%d", _unreadMessageCount]];
    }
    _messageCount --;
    [_myMessageData removeAllObjects];
    _myMessageData = [[NSMutableArray alloc] initWithArray:[User getMessageInfoByLimit:_messageCount-_messageIndex offset:_messageIndex]];
    //按照时间排序
    [_myMessageData sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        if ([[obj1 objectForKey:@"include_time"] compare:[obj2 objectForKey:@"include_time"]] == NSOrderedDescending) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
//    _messageCount = [_myMessageData count];
    NSLog(@"\n_messageCount: %d\n", _messageCount);
    [self.tableView reloadData];
    //保存消息数
    [_userDefaultsDic setObject:[NSString stringWithFormat:@"%d", _unreadMessageCount] forKey:UNREAD_MESSAGE_COUNT];
    [_userDefaultsDic setObject:[NSString stringWithFormat:@"%d", _messageCount] forKey:MESSAGE_COUNT];
    [[NSUserDefaults standardUserDefaults] setObject:_userDefaultsDic forKey:[User getUid]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //消息数通知
    NSString *detailStr = [NSString stringWithFormat:@"%d条未读，共%d条", _unreadMessageCount, _messageCount];
    [CMNavBarNotificationView notifyWithText:@"已删除！" andDetail:detailStr];
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if (notification != nil) {
        notification.repeatInterval = 0;
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.alertBody = detailStr;
        notification.alertAction = @"查看";
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //获取消息具体内容
//    NSDictionary *data = [User getMessageContentByMid:[[_myMessageData objectAtIndex:[indexPath row]] objectForKey:@"mid"]];
    if ([[[_myMessageData objectAtIndex:[indexPath row]] objectForKey:@"read_flag"]  isEqual: @"true"]) {
        //从数据库读取消息
        NSDictionary *data = [User getMessageContentByMid:[[_myMessageData objectAtIndex:[indexPath row]] objectForKey:@"mid"]];
        if (data == nil) {
            NSLog(@"\nNot found in DB\n\n");
            //重新下载
            goto Download;
        }
        MessageContent *messageContent = [[MessageContent alloc] initWithNibName:@"MessageContent" bundle:nil];
        messageContent.title = [data objectForKey:@"title"];
        messageContent.hidesBottomBarWhenPushed = YES;
        NSString *includeTime = [[NSString stringWithString:[data objectForKey:@"include_time"]] substringToIndex:19];
        NSString *content = [[NSString alloc] initWithFormat:@"<b><center><font size=4>%@</b></center></font><br>%@<br>%@", [data objectForKey:@"title"], includeTime, [data objectForKey:@"content"]];
        messageContent.content = content;
        //        NSLog(@"\nContent: %@\n", content);
        [self.navigationController pushViewController:messageContent animated:YES];
    } else {
    Download:
        //未读消息
        NSLog(@"\n下载消息具体内容\n");
        ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://59.77.134.226:80/mobile_get_message_by_mid"]];
        
        [request setRequestMethod:@"POST"];
        NSString *postBody = @"{\"mid\":\"myMid\"}";
        //    NSLog(@"%@", [_myMessageData objectAtIndex:[indexPath row]]);
        postBody = [postBody stringByReplacingOccurrencesOfString:@"myMid" withString:[[_myMessageData objectAtIndex:[indexPath row]] objectForKey:@"mid"]];
        
        NSLog(@"postBody: %@", postBody);
        [request setPostBody:(NSMutableData *)[postBody dataUsingEncoding:NSUTF8StringEncoding]];
        
        request.delegate = self;
        [request startAsynchronous];
        //标记为已读
        NSString *readFlag = [[NSString alloc] initWithString:@"true"];
        NSMutableDictionary *obj = [[NSMutableDictionary alloc] initWithDictionary:[_myMessageData objectAtIndex:[indexPath row]]];
        NSLog(@"\nObj: %@\n", obj);
        [obj removeObjectForKey:@"read_flag"];
        [obj setObject:readFlag forKey:@"read_flag"];
        [_myMessageData replaceObjectAtIndex:[indexPath row] withObject:obj];
        //修改数据库数据标记为已读
        NSLog(@"\nUpdate: %@\n", obj);
        [User updateMessageContentByMid:[obj objectForKey:@"mid"] forField:@"read_flag" withValue:@"true"];
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [notification release];
}

#pragma mark - Mosquitto client delegate

- (void) didConnect: (NSUInteger)code
{
    NSLog(@"\nConnect to mosquitto!\n");
}

- (void) didDisconnect
{
    
}

- (void) didPublish: (NSUInteger)messageId
{
    
}

- (void) didReceiveMessage: (MosquittoMessage*)mosq_msg
{
    NSLog(@"\nReceive!!!!!!!!\n");
    _messageCount ++;
    _unreadMessageCount ++;
    
    //未读消息通知
    NSString *detailStr = [NSString stringWithFormat:@"您有%d条未读消息", _unreadMessageCount];
    [CMNavBarNotificationView notifyWithText:@"新消息！" andDetail:detailStr];
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if (notification != nil) {
        notification.repeatInterval = 0;
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.alertBody = detailStr;
        notification.alertAction = @"查看";
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
    NSLog(@"\nMessage count: %d\n", _messageCount);
    NSLog(@"\nMessage: %@\n", mosq_msg.payload);
    SBJSON *json = [[[SBJSON alloc] init] autorelease];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithDictionary:[json objectWithString:mosq_msg.payload]];

    //未读标记
    NSString *readFlag = [[NSString alloc] initWithString:@"false"];
    [data setObject:readFlag forKey:@"read_flag"];
    //新消息信息写进数据库
    [User insertMessageInfoBySn:_messageCount-1 message:data];
    [_myMessageData addObject:data];
    [_myMessageData sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        if ([[obj1 objectForKey:@"include_time"] compare:[obj2 objectForKey:@"include_time"]] == NSOrderedDescending) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
//    NSLog(@"\nMyMessageData:\n%@\n", _myMessageData);
    [UIApplication sharedApplication].applicationIconBadgeNumber = _unreadMessageCount;
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [[[app.tabBarController.tabBar items]objectAtIndex:0] setBadgeValue:[NSString stringWithFormat:@"%d", _unreadMessageCount]];
    
    [_userDefaultsDic setObject:[NSString stringWithFormat:@"%d", _messageCount] forKey:MESSAGE_COUNT];
    [_userDefaultsDic setObject:[NSString stringWithFormat:@"%d", _unreadMessageCount] forKey:UNREAD_MESSAGE_COUNT];
    [[NSUserDefaults standardUserDefaults] setObject:_userDefaultsDic forKey:[User getUid]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.tableView reloadData];
}

- (void) didSubscribe: (NSUInteger)messageId grantedQos:(NSArray*)qos
{
    NSLog(@"\n订阅推送成功！\n");
}

- (void) didUnsubscribe: (NSUInteger)messageId
{
    NSLog(@"\n退订推送成功！\n");
}

#pragma mark -
#pragma mark ASIHTTPRequestDelegate

- (void)requestStarted:(ASIHTTPRequest *)request
{
    NSLog(@"请求开始了");
    [activityIndicator startAnimating];
    [SVProgressHUD showWithStatus:@"正在获取消息内容"];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSLog(@"请求结束了");
    [activityIndicator stopAnimating];

    
    NSString *str = request.responseString;
    if ([str length] == 0) {
        NSLog(@"str为空！");
    }
    //NSLog(@"str is ---> %@",str);
    
    SBJSON *json = [[[SBJSON alloc] init] autorelease];
    NSDictionary *dic = [json objectWithString:str];
    //    NSLog(@"dic = %@",dic);
    NSString *code = [dic objectForKey:@"code"];
    NSString *msg = [dic objectForKey:@"msg"];
    NSLog(@"code: %@", code);
    if ([code intValue] == 0) {
        _unreadMessageCount --;
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        if (_unreadMessageCount < 1) {
            //没有未读消息
            [[[app.tabBarController.tabBar items]objectAtIndex:0] setBadgeValue:nil];
            
            [UIApplication sharedApplication].applicationIconBadgeNumber = nil;
        } else {
            [[[app.tabBarController.tabBar items]objectAtIndex:0] setBadgeValue:[NSString stringWithFormat:@"%d", _unreadMessageCount]];
            
            [UIApplication sharedApplication].applicationIconBadgeNumber = _unreadMessageCount;
        }
        NSDictionary *data = [[NSDictionary alloc] initWithDictionary:[dic objectForKey:@"data"]];
//        NSLog(@"\n消息内容：%@\n", data);
        [User insertMessageContent:data];
        
        [SVProgressHUD dismissWithSuccess:@"获取消息内容成功！"];
        
        MessageContent *messageContent = [[MessageContent alloc] initWithNibName:@"MessageContent" bundle:nil];
        messageContent.title = [data objectForKey:@"title"];
//        messageContent.hidesBottomBarWhenPushed = YES;
        NSString *includeTime = [[NSString stringWithString:[data objectForKey:@"include_time"]] substringToIndex:19];
        NSString *content = [[NSString alloc] initWithFormat:@"<b><center><font size=4>%@</b></center></font><br>%@<br>%@", [data objectForKey:@"title"], includeTime, [data objectForKey:@"content"]];
        messageContent.content = content;
        messageContent.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:messageContent animated:YES];
        [self.tableView reloadData];

    } else {
        NSLog(@"msg: %@", msg);
    }
    
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    
    NSLog(@"请求失败了");
    //    NSLog([[request error] localizedDescription]);
}

@end
