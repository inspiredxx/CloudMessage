//
//  SubscriptionList.m
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-23.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import "SubscriptionList.h"
#import "PublicDefinition.h"
#import "SBJSON.h"
#import <ASIHTTPRequest/ASIHTTPRequestHeader.h>
#import "SVProgressHUD.h"
#import "DetailViewController.h"

@interface SubscriptionList ()

@end

@implementation SubscriptionList
//@synthesize isOpen,selectIndex;

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

    [self getSubscriptionList];
}

- (void)getSubscriptionList
{
    
    NSLog(@"获取分类列表！");
    ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://59.77.134.226:80/mobile_get_category_by_pid"]];
    
    [request setRequestMethod:@"POST"];
    NSString *postBody = @"{\"pid\":\"myPid\"}";
    postBody = [postBody stringByReplacingOccurrencesOfString:@"myPid" withString:PID];
    NSLog(@"postBody: %@", postBody);
    [request setPostBody:(NSMutableData *)[postBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    request.delegate = self;
    [request startAsynchronous];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"\nMemoryWarning!-sList\n");
}

#pragma mark -
#pragma mark Data Source Loading / Reloading Methods

- (void)reloadTableViewDataSource{
	
	//  should be calling your tableviews data source model to reload
	//  put here just for demo
    [self getSubscriptionList];
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
    return [_subscriptionListData count];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [[_subscriptionListData objectAtIndex:[indexPath row]] objectForKey:@"name"];
    cell.detailTextLabel.text = [[_subscriptionListData objectAtIndex:[indexPath row]] objectForKey:@"describer"];
    
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

//#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
 
    NSLog(@"\n%@\n", [[_subscriptionListData objectAtIndex:indexPath.row] objectForKey:@"name"]);
    DetailViewController *detailVC = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    detailVC.hidesBottomBarWhenPushed = YES;
    detailVC.title = [[_subscriptionListData objectAtIndex:indexPath.row] objectForKey:@"name"];
    detailVC.cid = [[_subscriptionListData objectAtIndex:indexPath.row] objectForKey:@"_id"];
    detailVC.level = 2;
    [self.navigationController pushViewController:detailVC animated:YES];
    [detailVC release];
}

#pragma mark -
#pragma mark ASIHTTPRequestDelegate

- (void)requestStarted:(ASIHTTPRequest *)request
{
    NSLog(@"请求开始了");
    [activityIndicator startAnimating];
    [SVProgressHUD showWithStatus:@"正在获取分类列表"];
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
        _subscriptionListData = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"data"]];

        [SVProgressHUD dismissWithSuccess:@"获取分类列表成功！"];
        [self.tableView reloadData];
        if (_reloading) {            
            [self doneLoadingTableViewData];
        }
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
