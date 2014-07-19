//
//  DetailViewController.m
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-23.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import "DetailViewController.h"
#import <ASIHTTPRequest/ASIHTTPRequestHeader.h>
#import "SBJSON.h"
#import "SVProgressHUD.h"
#import "PublicDefinition.h"
#import "AppDelegate.h"

@interface DetailViewController ()
{
    BOOL isSubscribingNow;
}

@end

@implementation DetailViewController

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
    user = [User sharedUser];

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
    
    _resourceData = [[User runtimeData] objectForKey:_cid];
    if (_resourceData == nil) {
        [self getResourceData];
    } else {
        NSLog(@"\ndata cached:\n%@\n", _resourceData);
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)getResourceData
{
    NSLog(@"\ncid: %@\n", self.cid);
    NSLog(@"获取分类源信息！");
    ASIFormDataRequest *request;
    NSString *postBody = nil;
//    postBody = [[NSString alloc] init];
    if (self.level == 2) {
        request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://59.77.134.226:80/mobile_get_category_by_pid"]];
        postBody = @"{\"pid\":\"myPid\"}";
        postBody = [postBody stringByReplacingOccurrencesOfString:@"myPid" withString: self.cid];
    } else {
        request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://59.77.134.226:80/mobile_get_resource_by_cid"]];
        postBody = @"{\"cid\":\"myCid\", \"uid\":\"myUid\"}";
        postBody = [postBody stringByReplacingOccurrencesOfString:@"myCid" withString: self.cid];
        postBody = [postBody stringByReplacingOccurrencesOfString:@"myUid" withString: UID];
    }
    NSLog(@"postBody: %@", postBody);
    [request setPostBody:(NSMutableData *)[postBody dataUsingEncoding:NSUTF8StringEncoding]];
    [request setRequestMethod:@"POST"];
    
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
    [self getResourceData];
	_reloading = YES;
	
}

- (void)doneLoadingTableViewData{
	
	//  model should call this when its done loading
    NSLog(@"\n刷新完毕\n");
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
	
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	
	[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	
	[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
	
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
    return [_resourceData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [[_resourceData objectAtIndex:[indexPath row]] objectForKey:@"name"];
    cell.detailTextLabel.text = [[_resourceData objectAtIndex:[indexPath row]] objectForKey:@"describer"];
    
    if (self.level == 3) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(280, 8, 30, 30)];
        //判断该消息源是否订阅
        NSArray *mySubscriptionData = [[User runtimeData] objectForKey:MY_SUBSCRIPTION];
        [imageView setImage:[UIImage imageNamed:@"action_bar_pending.png"]];
        for (NSDictionary *obj in mySubscriptionData) {
            if ([[obj objectForKey:@"_id"] isEqual:[[_resourceData objectAtIndex:[indexPath row]] objectForKey:@"_id"]]) {
//                NSLog(@"\n%@ 订阅过！\n", [[_resourceData objectAtIndex:[indexPath row]] objectForKey:@"name"]);
                [imageView setImage:[UIImage imageNamed:@"action_bar_cancel.png"]];
                imageView.tag = 0;
            }
        }
        [cell.contentView addSubview:imageView];
    }
    return cell;
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
    if (self.level < 3) {
        //还有子节点
        DetailViewController *detailVC = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
        detailVC.title = [[_resourceData objectAtIndex:[indexPath row]] objectForKey:@"name"];
        detailVC.cid = [[_resourceData objectAtIndex:[indexPath row]] objectForKey:@"_id"];
        detailVC.level = self.level + 1;
        [self.navigationController pushViewController:detailVC animated:YES];
    } else {
        //叶节点        
        //判断该消息源是否订阅
        NSArray *mySubscriptionData = [[User runtimeData] objectForKey:MY_SUBSCRIPTION];
        for (NSDictionary *obj in mySubscriptionData) {
            if ([[obj objectForKey:@"_id"] isEqual:[[_resourceData objectAtIndex:[indexPath row]] objectForKey:@"_id"]]) {
                NSLog(@"\n%@ 订阅过！\n", [[_resourceData objectAtIndex:[indexPath row]] objectForKey:@"name"]);
                isSubscribingNow = NO;
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"退订" message:@"是否退订？" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
                [alertView show];
                return;
            }
        }

        //未订阅过
        isSubscribingNow = YES;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"订阅" message:@"是否订阅？" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        [alertView show];
        
    }
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {        
        if (isSubscribingNow == YES) {
            //确定订阅            
            int row = [[self.tableView indexPathForSelectedRow] row];
            NSLog(@"\n订阅: %@\n", [[_resourceData objectAtIndex:row] objectForKey:@"name"]);
            
            ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://59.77.134.226:80/mobile_subscribe_resource"]];
            
            [request setRequestMethod:@"POST"];
            NSString *postBody = @"{\"rid\":\"myRid\", \"uid\":\"myUid\", \"token\":\"myToken\", \"auth_pwd\":\"myPwd\", \"reason\":\"myReason\"}";
            postBody = [postBody stringByReplacingOccurrencesOfString:@"myRid" withString:[[_resourceData objectAtIndex:row] objectForKey:@"_id"]];
            postBody = [postBody stringByReplacingOccurrencesOfString:@"myUid" withString:[[NSUserDefaults standardUserDefaults] objectForKey:UID]];
            postBody = [postBody stringByReplacingOccurrencesOfString:@"myToken" withString:[[NSUserDefaults standardUserDefaults] objectForKey:ACCESS_TOKEN]];
            NSLog(@"postBody: %@", postBody);
            [request setPostBody:(NSMutableData *)[postBody dataUsingEncoding:NSUTF8StringEncoding]];
            
            request.delegate = self;
            [request startAsynchronous];
        } else {
            //确定退订
            int row = [[self.tableView indexPathForSelectedRow] row];
            NSLog(@"\n退订: %@\n", [[_resourceData objectAtIndex:row] objectForKey:@"name"]);
            
            ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://59.77.134.226:80/mobile_unsubscribe_resource"]];
            
            [request setRequestMethod:@"POST"];
            NSString *postBody = @"{\"rid\":\"myRid\", \"uid\":\"myUid\", \"access_token\":\"accessToken\"}";
            postBody = [postBody stringByReplacingOccurrencesOfString:@"myRid" withString:[[_resourceData objectAtIndex:row] objectForKey:@"_id"]];
            postBody = [postBody stringByReplacingOccurrencesOfString:@"myUid" withString:[[NSUserDefaults standardUserDefaults] objectForKey:UID]];
            postBody = [postBody stringByReplacingOccurrencesOfString:@"myToken" withString:[[NSUserDefaults standardUserDefaults] objectForKey:ACCESS_TOKEN]];
            NSLog(@"postBody: %@", postBody);
            [request setPostBody:(NSMutableData *)[postBody dataUsingEncoding:NSUTF8StringEncoding]];
            
            request.delegate = self;
            [request startAsynchronous];
        }        
    }
    
}

#pragma mark -
#pragma mark ASIHTTPRequestDelegate

- (void)requestStarted:(ASIHTTPRequest *)request
{
    NSLog(@"请求开始了");
    [activityIndicator startAnimating];
    [SVProgressHUD show];
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
    
//    SBJSON *json = [[[SBJSON alloc] init] autorelease];
    SBJSON *json = [[SBJSON alloc] init];
    NSDictionary *dic = [json objectWithString:str];
//    NSLog(@"dic = %@",dic);
    
    NSString *code = [dic objectForKey:@"code"];
    NSString *msg = [dic objectForKey:@"msg"];
    NSLog(@"code: %@", code);
    if ([code intValue] == 0) {
        if ([dic objectForKey:@"data"] == nil) {
            //订阅/退订请求的返回
            NSLog(@"\n订阅/退订成功\n");
            //向推送服务器订阅/退订
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            MosquittoClient *mosq = [app mosquittoClient];

            if (isSubscribingNow == YES) {                
                NSLog(@"\nmosq 订阅: %@\n", [[_resourceData objectAtIndex:[[self.tableView indexPathForSelectedRow] row]] objectForKey:@"_id"]);
                [mosq subscribe:[[_resourceData objectAtIndex:[[self.tableView indexPathForSelectedRow] row]] objectForKey:@"_id"] withQos:1];
                [SVProgressHUD showSuccessWithStatus:@"订阅成功"];
            } else {
                NSLog(@"\nmosq 退订: %@\n", [[_resourceData objectAtIndex:[[self.tableView indexPathForSelectedRow] row]] objectForKey:@"name"]);
                [mosq unsubscribe:[[_resourceData objectAtIndex:[[self.tableView indexPathForSelectedRow] row]] objectForKey:@"_id"]];
                [SVProgressHUD showSuccessWithStatus:@"退订成功"];
            }

            [user getMySubscription];
            [User setSubscriptionRefresh:YES];            
            //清除旧图片
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];
            for (id obj in [cell.contentView subviews]) {
                [obj removeFromSuperview];
            }
            [self.tableView reloadData];
        } else {
            _resourceData = [[NSArray alloc] initWithArray:[dic objectForKey:@"data"]];
            [User setRuntimeData:_resourceData forKey:_cid];

            [self.tableView reloadData];
            if (_reloading == YES) {
                [self doneLoadingTableViewData];
            }
            [SVProgressHUD dismiss];
        }
    } else {
        NSLog(@"msg: %@", msg);
        if ([code intValue] == 1) {
            //已经订阅过
            [SVProgressHUD dismissWithSuccess:@"您已订阅过"];
        }
        [SVProgressHUD dismissWithError:@"订阅失败"];
    }    
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    
    NSLog(@"请求失败了");
    //    NSLog([[request error] localizedDescription]);
}

@end
