//
//  MySubscription.m
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-23.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import "MySubscription.h"
#import <ASIHTTPRequest/ASIHTTPRequestHeader.h>
#import "SVProgressHUD.h"
#import "SBJSON.h"
#import "PublicDefinition.h"
#import "AppDelegate.h"
#import "CMNavBarNotificationView.h"
#import "MsgOfSub.h"

@interface MySubscription ()
{
    BOOL isNeedToSubscribe; //是否向推送服务器订阅
}

@end

@implementation MySubscription

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
    
    if (_refreshHeaderView == nil) {
		
		_refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)];
		_refreshHeaderView.delegate = self;
		[self.tableView addSubview:_refreshHeaderView];
	}
	
	//  update the last update date
	[_refreshHeaderView refreshLastUpdatedDate];
    
    _mySubscriptionData = [[NSMutableArray alloc] initWithArray:[[User runtimeData] objectForKey:MY_SUBSCRIPTION]];
    if (_mySubscriptionData == nil) {
        [User setSubscriptionRefresh:YES];
        [self getMySubscription];
    } else {
//        NSLog(@"\n我的订阅数据： %@\n", _mySubscriptionData);
    }
//    NSDictionary *tmpData = [[NSDictionary alloc] init];
//    [_mySubscriptionData addObject:tmpData];
    
    user = [User sharedUser];
//    [self getMySubscription];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    [SVProgressHUD showWithStatus:@"正在获取订阅列表"];
//    _mySubscriptionData = [[User runtimeData] objectForKey:MY_SUBSCRIPTION];
    if ([User isNeedToRefreshSubscription] == YES) {
        [self getMySubscription];
    }
//    NSLog(@"\nSubscription List:\n%@\n", [User subscriptionListData]);
//    _mySubscriptionData = [[User runtimeData] objectForKey:MY_SUBSCRIPTION];
//    NSLog(@"\nMy Subscription: \n%@\n", _mySubscriptionData);
}

-(void)getMySubscription
{
    NSLog(@"获取我的订阅！");
//    [SVProgressHUD show];
    ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://59.77.134.226:80/mobile_get_resource_list_by_uid"]];
    
    [request setRequestMethod:@"POST"];
    NSString *postBody = @"{\"uid\":\"myUid\"}";
//    NSLog(@"\nusername:%@\naccess_token: %@\nuid: %@", user.username, user.accessToken, user.uid);

    
    postBody = [postBody stringByReplacingOccurrencesOfString:@"myUid" withString:[[NSUserDefaults standardUserDefaults] objectForKey:UID]];
    NSLog(@"postBody: %@", postBody);
    [request setPostBody:(NSMutableData *)[postBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    request.delegate = self;
    [request startAsynchronous];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
    [self getMySubscription];
	_reloading = YES;
	
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
    NSLog(@"\n刷新完毕\n");
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
//    [CMNavBarNotificationView notifyWithText:@"刷新完成" detail:nil andDuration:0.2];
	
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	[self hideTabBar:NO];
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
	
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self hideTabBar:YES];
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
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view{
	
	[self reloadTableViewDataSource];
//	[self performSelector:@selector(doneLoadingTableViewData) withObject:nil afterDelay:3.0];
	
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view{

	return _reloading; // should return if data source model is reloading
	
}

- (NSDate*)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view{
	
	return [NSDate date]; // should return date data source was last changed
	
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_mySubscriptionData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *obj = [_mySubscriptionData objectAtIndex:[indexPath row]];
//    NSLog(@"\ntext: %@\n", [obj objectForKey:@"name"]);
    cell.textLabel.text = [obj objectForKey:@"name"];
    cell.detailTextLabel.text = [obj objectForKey:@"describer"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"退订消息");
//    [SVProgressHUD show];
    ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://59.77.134.226:80/mobile_unsubscribe_resource"]];
    
    [request setRequestMethod:@"POST"];
    NSString *postBody = @"{\"rid\":\"myRid\", \"uid\":\"myUid\", \"access_token\":\"accessToken\"}";
    NSDictionary *obj = [_mySubscriptionData objectAtIndex:[indexPath row]];
    postBody = [postBody stringByReplacingOccurrencesOfString:@"myRid" withString:[obj objectForKey:@"_id"]];
    postBody = [postBody stringByReplacingOccurrencesOfString:@"myUid" withString:[[NSUserDefaults standardUserDefaults] objectForKey:UID]];
    postBody = [postBody stringByReplacingOccurrencesOfString:@"access_token" withString:[[NSUserDefaults standardUserDefaults] objectForKey:ACCESS_TOKEN]];
    NSLog(@"unsubscribe postBody: %@", postBody);
    [request setPostBody:(NSMutableData *)[postBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    request.delegate = self;
    [request startAsynchronous];
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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    NSDictionary *obj = [_mySubscriptionData objectAtIndex:[indexPath row]];
//    NSLog(@"\nobj: %@\n", obj);
    NSLog(@"\nrid: %@\n", [obj objectForKey:@"_id"]);
    
    MsgOfSub *msgOfSub = [[[MsgOfSub alloc] initWithNibName:@"MsgOfSub" bundle:nil] autorelease];
    msgOfSub.title = [obj objectForKey:@"name"];
    msgOfSub.rid = [obj objectForKey:@"_id"];
    msgOfSub.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:msgOfSub animated:YES];
}

#pragma mark -
#pragma mark ASIHTTPRequestDelegate

- (void)requestStarted:(ASIHTTPRequest *)request
{
    NSLog(@"请求开始了");
    [activityIndicator startAnimating];
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
    
    SBJSON *json = [[SBJSON alloc] init];
    NSDictionary *dic = [json objectWithString:str];
//    NSLog(@"dic = %@",dic);
    NSString *code = [dic objectForKey:@"code"];
    NSString *msg = [dic objectForKey:@"msg"];
    NSLog(@"code: %@", code);
    if ([code intValue] == 0) {
        if ([dic objectForKey:@"data"] == nil) {
            //退订响应
//            [SVProgressHUD dismissWithSuccess:@"退订成功！"];
            //重新获取订阅列表
            [self getMySubscription];
        } else {
            //获取订阅列表响应
//        NSLog(@"data: %@", data);
            if (_mySubscriptionData != nil) {                
                [_mySubscriptionData release];
            }
            _mySubscriptionData = [[NSMutableArray alloc] initWithArray:(NSMutableArray *)[dic objectForKey:@"data"]];

            //订阅信息保存到内存
            [User setRuntimeData:_mySubscriptionData forKey:MY_SUBSCRIPTION];
            [User setSubscriptionRefresh:NO];

            [self.tableView reloadData];
//            sleep(1);
            if (_reloading) {
                [self doneLoadingTableViewData];
            }
        }

    } else {
        NSLog(@"msg: %@", msg);
    }
    [dic release];
}

- (void)subscribingFromMosqServer
{    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	MosquittoClient *mosq = [app mosquittoClient];
    
    for (NSDictionary *obj in _mySubscriptionData) {
        [mosq subscribe:[obj objectForKey:@"_id"]];
//        NSLog(@"\nmosq 订阅: %@", [obj objectForKey:@"_id"]);
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    
    NSLog(@"请求失败了");
//    NSLog([[request error] localizedDescription]);
    [SVProgressHUD dismissWithError:@"请求失败，请重试！"];
}

@end
