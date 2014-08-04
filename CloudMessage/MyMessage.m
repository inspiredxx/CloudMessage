//
//  MyMessage.m
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-23.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import "MyMessage.h"
//#import "ASIFormDataRequest.h"
#import <ASIHTTPRequest/ASIHTTPRequestHeader.h>
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
    NSMutableArray *_unReadMessageData;
    NSMutableArray *_readedMessageData;
    NSInteger _messageCount;
    NSInteger _unreadMessageCount;
    NSInteger _messageIndex;
    CGFloat lastOffsetY;
    BOOL isDecelerating;
    NSMutableDictionary *_userDefaultsDic;
    SINavigationMenuView *navBarMenu;
    NSInteger showIndex;
    BOOL showCMNotificationFlag;    //判断是否正在接收中
    //通知显示计时器
    NSTimer *notificationTimer;
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
    
    showCMNotificationFlag = YES;
    
    //清空已有数据
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"behaviorData"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    CGRect frame = CGRectMake(0.0, 0.0, 200.0, self.navigationController.navigationBar.bounds.size.height);
    navBarMenu = [[SINavigationMenuView alloc] initWithFrame:frame title:@"最新资讯"];
    [navBarMenu displayMenuInView:self.tableView];
//    [navBarMenu displayMenuInView:self.navigationController.navigationBar];
    navBarMenu.items = @[@"最新资讯", @"未读资讯", @"已读资讯"];
    navBarMenu.delegate = self;
    self.navigationItem.titleView = navBarMenu;
    //显示全部
    showIndex = 0;
    
    //登录验证
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:ACCESS_TOKEN];
    if (accessToken == nil) {
        NSLog(@"\n登录\n");
        LoginViewController *loginViewController = [[[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil] autorelease];
//        LoginViewController *loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
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
    [self distinguishData];
    
    _unreadMessageCount = [[messageCountArray objectAtIndex:1] intValue];
    //Badge
    if (_unreadMessageCount > 0){
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [[[app.tabBarController.tabBar items]objectAtIndex:0] setBadgeValue:[NSString stringWithFormat:@"%d", _unreadMessageCount]];
        [UIApplication sharedApplication].applicationIconBadgeNumber = _unreadMessageCount;
    }
}

//整理未读、已读资讯
- (void)distinguishData
{
    if (_unReadMessageData == nil) {
        _unReadMessageData = [[NSMutableArray alloc] init];
    } else {
        [_unReadMessageData removeAllObjects];
    }
    if (_readedMessageData == nil) {
        _readedMessageData = [[NSMutableArray alloc] init];
    } else {
        [_readedMessageData removeAllObjects];
    }
    for (NSMutableDictionary *obj in _myMessageData) {
        if ([[obj objectForKey:@"read_flag"] isEqualToString:@"false"]) {
            [_unReadMessageData addObject:obj];
        } else if ([[obj objectForKey:@"read_flag"] isEqualToString:@"true"]) {
            [_readedMessageData addObject:obj];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    //若有未读资讯已经被阅读过则刷新
    if ([User isNeedToRefreshMessageData] == YES) {
        [User setMessageDataRefresh:NO];
        if (_myMessageData != nil) {
            [_myMessageData release];
        }
        _myMessageData = [[NSMutableArray alloc] initWithArray:[User getMessageInfoByLimit: _messageCount-_messageIndex offset:_messageIndex]];
        [self distinguishData];
        [self.tableView reloadData];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
        loadedData = [[NSArray alloc] initWithArray:[User getMessageInfoByLimit:_messageIndex-MAX(0, _messageIndex-25) offset:MAX(0, _messageIndex-25)]];
        
        _messageIndex -= [loadedData count];
        NSLog(@"\n_messageIndex: %d", _messageIndex);
    }
    [self doneGettingTableViewData:loadedData];
    [loadedData release];
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
        [self distinguishData];
        [self.tableView reloadData];
    }
    _isLoading = NO;
	[_refreshFooterView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    [self hideTabBar:NO];
    [_refreshFooterView removeFromSuperview];
    _refreshFooterView = nil;
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
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

#pragma mark - SINavigationMenuDelegate
- (void)didSelectItemAtIndex:(NSUInteger)index
{
    if (index == 0) {
        showIndex = 0;
        [navBarMenu setTitle:@"最新资讯"];
    } else if (index == 1) {
        showIndex = 1;
        [navBarMenu setTitle:@"未读资讯"];
    } else if (index == 2) {
        showIndex = 2;
        [navBarMenu setTitle:@"已读资讯"];
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (showIndex == 0) {
        return [_myMessageData count];
    } else if (showIndex == 1) {
        return [_unReadMessageData count];
    } else if (showIndex == 2) {
        return [_readedMessageData count];
    }
    return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    if (showIndex == 0) {
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
    } else if (showIndex == 1) {
        NSDictionary *obj = [_unReadMessageData objectAtIndex:[indexPath row]];
        if (obj != nil) {
            cell.textLabel.text = [obj objectForKey:@"title"];
            [cell.textLabel setTextColor:[UIColor redColor]];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"未读 %@ %@", [obj objectForKey:@"include_time"], [obj objectForKey:@"abstract"]];
            [cell.detailTextLabel setTextColor:[UIColor redColor]];
        }
    } else if (showIndex == 2) {
        NSDictionary *obj = [_readedMessageData objectAtIndex:[indexPath row]];
        if (obj != nil) {
            cell.textLabel.text = [obj objectForKey:@"title"];
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
    if (_myMessageData != nil) {
        [_myMessageData release];
    }
    _myMessageData = [[NSMutableArray alloc] initWithArray:[User getMessageInfoByLimit:_messageCount-_messageIndex offset:_messageIndex]];
    //按照时间排序
    [_myMessageData sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        if ([[obj1 objectForKey:@"include_time"] compare:[obj2 objectForKey:@"include_time"]] == NSOrderedDescending) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
    [self distinguishData];
    NSLog(@"\n_messageCount: %d\n", _messageCount);
    [self.tableView reloadData];
    //保存消息数
//    [_userDefaultsDic setObject:[NSString stringWithFormat:@"%d", _unreadMessageCount] forKey:UNREAD_MESSAGE_COUNT];
//    [_userDefaultsDic setObject:[NSString stringWithFormat:@"%d", _messageCount] forKey:MESSAGE_COUNT];
//    [[NSUserDefaults standardUserDefaults] setObject:_userDefaultsDic forKey:[User getUid]];
//    [[NSUserDefaults standardUserDefaults] synchronize];
    
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
    [notification release];
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
    @autoreleasepool {
        //获取消息具体内容
        NSMutableArray *messageData = nil;
        if (showIndex == 0) {
            messageData = _myMessageData;
        } else if (showIndex == 1) {
            messageData = _unReadMessageData;
        } else if (showIndex == 2) {
            messageData = _readedMessageData;
        }
        
        if ([[[messageData objectAtIndex:[indexPath row]] objectForKey:@"read_flag"] isEqual: @"true"]) {
            //从数据库读取消息
            NSDictionary *data = [User getMessageContentByMid:[[messageData objectAtIndex:[indexPath row]] objectForKey:@"mid"]];
            if (data == nil) {
                NSLog(@"\nNot found in DB\n\n");
                //重新下载
                goto Download;
            }
            [self pushContent:data];

        } else {
        Download:
            
            /*
            ////////////////////////////////////////
            NSLog(@"\n下载消息具体内容\n");
            NSString *urlString=@"http://59.77.134.226:80/mobile_get_message_by_mid";
            urlString = [urlString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
            NSMutableURLRequest *requestA = [[NSMutableURLRequest alloc] init];
            [requestA setURL:[NSURL URLWithString: urlString]];
            [requestA setCachePolicy:NSURLRequestReloadIgnoringCacheData];
            [requestA setTimeoutInterval: 60];
            [requestA setHTTPShouldHandleCookies:FALSE];
            [requestA setHTTPMethod:@"POST"];
            NSString *postBodyA = @"{\"mid\":\"myMid\"}";
            postBodyA = [postBodyA stringByReplacingOccurrencesOfString:@"myMid" withString:[[messageData objectAtIndex:[indexPath row]] objectForKey:@"mid"]];
            [requestA setHTTPBody:[postBodyA dataUsingEncoding:NSUTF8StringEncoding]];
            NSURLConnection *aSynConnection = nil;
            // 在协议方法中，通过判断aSynConnection，来区分，是哪一个异步请求的返回数据。
            aSynConnection = [[NSURLConnection alloc] initWithRequest:requestA delegate:self];
            
            //标记为已读
            NSString *readFlagA = @"true";
            NSMutableDictionary *objA = [[NSMutableDictionary alloc] initWithDictionary:[messageData objectAtIndex:[indexPath row]]];
            NSLog(@"\nObj: %@\n", objA);
            [objA removeObjectForKey:@"read_flag"];
            [objA setObject:readFlagA forKey:@"read_flag"];
            for (NSDictionary *obj1 in _myMessageData) {
                if ([[obj1 objectForKey:@"mid"] isEqualToString:[objA objectForKey:@"mid"]]) {
                    [_myMessageData removeObject:obj1];
                    [_myMessageData addObject:objA];
                    break;
                }
            }
            //          [_myMessageData replaceObjectAtIndex:[indexPath row] withObject:obj];
            [self distinguishData];
            //修改数据库数据标记为已读
            NSLog(@"\nUpdate: %@\n", objA);
            [User updateMessageContentByMid:[objA objectForKey:@"mid"] forField:@"read_flag" withValue:@"true"];
            [objA release];
            
            return ;
            ////////////////////////////////////////
             */
            
            
            //未读消息
            NSLog(@"\n下载消息具体内容\n");
            ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://59.77.134.226:80/mobile_get_message_by_mid"]];

            [request setRequestMethod:@"POST"];
            NSString *postBody = @"{\"mid\":\"myMid\"}";
            postBody = [postBody stringByReplacingOccurrencesOfString:@"myMid" withString:[[messageData objectAtIndex:[indexPath row]] objectForKey:@"mid"]];
            
            NSLog(@"postBody: %@", postBody);
            [request setPostBody:(NSMutableData *)[postBody dataUsingEncoding:NSUTF8StringEncoding]];
            
            request.delegate = self;
            [request startAsynchronous];
            //标记为已读
            NSString *readFlag = @"true";
            NSMutableDictionary *obj = [[NSMutableDictionary alloc] initWithDictionary:[messageData objectAtIndex:[indexPath row]]];
            NSLog(@"\nObj: %@\n", obj);
            [obj removeObjectForKey:@"read_flag"];
            [obj setObject:readFlag forKey:@"read_flag"];
            for (NSDictionary *obj1 in _myMessageData) {
                if ([[obj1 objectForKey:@"mid"] isEqualToString:[obj objectForKey:@"mid"]]) {
                    [_myMessageData removeObject:obj1];
                    [_myMessageData addObject:obj];
                    break;
                }
            }
            [self distinguishData];
            //修改数据库数据标记为已读
            NSLog(@"\nUpdate: %@\n", obj);
            [User updateMessageContentByMid:[obj objectForKey:@"mid"] forField:@"read_flag" withValue:@"true"];
        }
    }
}

#pragma mark- NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)aResponse
{
    NSLog(@"请求成功！");
    [activityIndicator startAnimating];
    [SVProgressHUD showWithStatus:@"正在获取消息内容"];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"\nA\n");
    
    NSLog(@"请求结束了");
    [activityIndicator stopAnimating];
    
    @autoreleasepool {
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"\ndata: %@", str);
        if ([str length] == 0) {
            NSLog(@"str为空！");
        }
        SBJSON *json = [[[SBJSON alloc] init] autorelease];
        NSDictionary *dic = [json objectWithString:str];
        NSString *code = [dic objectForKey:@"code"];
        NSString *msg = [dic objectForKey:@"msg"];
        NSLog(@"code: %@", code);
        if (code == nil) {
            NSLog(@"\ncode nil!\n");
            NSLog(@"dic: %@\n", dic);
            NSLog(@"str: %@\n", str);
            [SVProgressHUD dismissWithSuccess:@"获取消息内容失败！"];
            return ;
        }
        if ([code intValue] == 0) {
            _unreadMessageCount --;
            //IconBadge
            AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
            if (_unreadMessageCount < 1) {
                //没有未读消息
                [[[app.tabBarController.tabBar items]objectAtIndex:0] setBadgeValue:nil];
                
                [UIApplication sharedApplication].applicationIconBadgeNumber = nil;
            } else {
                [[[app.tabBarController.tabBar items]objectAtIndex:0] setBadgeValue:[NSString stringWithFormat:@"%d", _unreadMessageCount]];
                
                [UIApplication sharedApplication].applicationIconBadgeNumber = _unreadMessageCount;
            }
            NSDictionary *content = [[[NSDictionary alloc] initWithDictionary:[dic objectForKey:@"data"]] autorelease];
            //保存到数据库
            [User insertMessageContent:content];
            [self pushContent:content];
            [SVProgressHUD dismissWithSuccess:@"获取消息内容成功！"];
            
            [self.tableView reloadData];
        } else {
            NSLog(@"msg: %@", msg);
        }

    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{

}

- (void)onRequestTimer:(NSTimer *)timer
{
    ASIFormDataRequest *request = (ASIFormDataRequest *)timer.userInfo;
    [request clearDelegatesAndCancel];
}

//将messageContentVC Push
- (void)pushContent:(NSDictionary *)data
{
    @autoreleasepool {
        MessageContent *messageContent = [[MessageContent alloc] initWithNibName:@"MessageContent" bundle:nil];
        messageContent.title = [data objectForKey:@"title"];
        messageContent.hidesBottomBarWhenPushed = YES;
        NSString *includeTime = [[NSString stringWithString:[data objectForKey:@"include_time"]] substringToIndex:19];
        NSString *content = [[NSString alloc] initWithFormat:@"<b><center><font size=4>%@</b></center></font><br>%@<br>%@", [data objectForKey:@"title"], includeTime, [data objectForKey:@"content"]];
        //          NSString *content = [[NSString alloc] initWithFormat:@"<b><center><font size=4>%@</b></center></font><br>%@<br>%@", [data objectForKey:@"title"], includeTime, [data objectForKey:@"content"]];
        messageContent.content = content;
        messageContent._id = [data objectForKey:@"_id"];
        [content release];
        [self.navigationController pushViewController:messageContent animated:YES];
        NSLog(@"\n%@\n", self.navigationController.description);
        [messageContent release];
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [notification release];
    NSLog(@"\ndidReceiveLocalNotification\n");
}

#pragma mark - Mosquitto client delegate

- (void) didConnect: (NSUInteger)code
{
    NSLog(@"\nConnect to mosquitto!\n");
}

- (void) didDisconnect
{
    NSLog(@"\nDisconnect mosq\n");
}

- (void) didPublish: (NSUInteger)messageId
{
    NSLog(@"\nPublish. messageId: %d\n", messageId);
}

- (void)onNotificationTimer: (NSTimer *)timer
{
    NSInteger unreadMsgCnt = [(NSString *)timer.userInfo intValue];
    if (unreadMsgCnt != _unreadMessageCount) {
        //还在接收
        if ([notificationTimer isValid]) {
            [notificationTimer invalidate];
            notificationTimer = nil;
            NSLog(@"\nnotificationTimer invalidate\n");
            [SVProgressHUD showWithStatus:@"正在接收..."];
        }
        notificationTimer = [NSTimer scheduledTimerWithTimeInterval:0.8 target:self selector:@selector(onNotificationTimer:) userInfo:[NSString stringWithFormat:@"%d", _unreadMessageCount] repeats:NO];
    } else {
        
        NSLog(@"\nwill showNotification\n");
        if ([notificationTimer isValid]) {
            [notificationTimer invalidate];
            notificationTimer = nil;
        }
        showCMNotificationFlag = YES;
        [self showNotification];
        [SVProgressHUD dismiss];
    }
}

- (void)showNotification
{
    NSLog(@"\nshowNotification\n");
    //未读消息通知
    NSString *detailStr = [NSString stringWithFormat:@"您有%d条未读消息", _unreadMessageCount];
    [CMNavBarNotificationView notifyWithText:@"新消息！" detail:detailStr andDuration:2];
    
    UILocalNotification *notification = [[[UILocalNotification alloc] init] autorelease];
    if (notification != nil) {
        notification.repeatInterval = 0;
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.alertBody = detailStr;
        notification.alertAction = @"查看";
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    }
}

//接收到推送数据
- (void) didReceiveMessage: (MosquittoMessage*)mosq_msg
{
    NSLog(@"\nReceive!!!!!!!!\n");
    _messageCount ++;
    _unreadMessageCount ++;
    
    if (showCMNotificationFlag == YES) {
        notificationTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(onNotificationTimer:) userInfo:[NSString stringWithFormat:@"%d", _unreadMessageCount] repeats:NO];
        showCMNotificationFlag = NO;
    }
    NSLog(@"\nMessage count: %d\n", _messageCount);
    NSLog(@"\nMessage: %@\n", mosq_msg.payload);
    SBJSON *json = [[SBJSON alloc] init];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithDictionary:[json objectWithString:mosq_msg.payload]];
    
    //未读标记
    NSString *readFlag = [[NSString alloc] initWithString:@"false"];
    [data setObject:readFlag forKey:@"read_flag"];
    //新消息信息写进数据库
    [User insertMessageInfoBySn:_messageCount-1 message:data];
//        [readFlag release];
    [_myMessageData addObject:data];
    [_myMessageData sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        if ([[obj1 objectForKey:@"include_time"] compare:[obj2 objectForKey:@"include_time"]] == NSOrderedDescending) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
    
    //IconBadge
    [UIApplication sharedApplication].applicationIconBadgeNumber = _unreadMessageCount;
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [[[app.tabBarController.tabBar items]objectAtIndex:0] setBadgeValue:[NSString stringWithFormat:@"%d", _unreadMessageCount]];
    
    [self distinguishData];
    [self.tableView reloadData];
    
    [data release];
    [json release];
    [readFlag release];
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
    @autoreleasepool {
        NSLog(@"请求结束了");
        [activityIndicator stopAnimating];
        
        NSString *str = request.responseString;
        if ([str length] == 0) {
            NSLog(@"str为空！");
        }
        
        SBJSON *json = [[[SBJSON alloc] init] autorelease];
        //    SBJSON *json = [[SBJSON alloc] init];
        NSDictionary *dic = [json objectWithString:str];
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
            NSDictionary *data = [[[NSDictionary alloc] initWithDictionary:[dic objectForKey:@"data"]] autorelease];

            //保存到数据库
            [User insertMessageContent:data];
            
            [self pushContent:data];
            
            [SVProgressHUD dismissWithSuccess:@"获取消息内容成功！"];

            [self.tableView reloadData];
        } else {
            NSLog(@"msg: %@", msg);
        }
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"请求失败了");
    NSLog(@"\n%@\n", [[request error] localizedDescription]);
}

@end
