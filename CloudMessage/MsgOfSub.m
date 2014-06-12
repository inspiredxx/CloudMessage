//
//  MsgOfSub.m
//  CloudMessage
//
//  Created by SoftwareLab on 14-6-12.
//  Copyright (c) 2014年 SoftwareLab. All rights reserved.
//

#import "MsgOfSub.h"
#import "User.h"
#import "MessageContent.h"
#import "ASIFormDataRequest.h"
#import "SBJSON.h"
#import "SVProgressHUD.h"

@interface MsgOfSub ()
{
    NSMutableArray *subData;
}

@end

@implementation MsgOfSub

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    subData = [[NSMutableArray alloc] initWithArray:[User getMessageInfoByRid:self.rid]];
    //按照时间排序
    [subData sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        if ([[obj1 objectForKey:@"include_time"] compare:[obj2 objectForKey:@"include_time"]] == NSOrderedDescending) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    if (subData == nil) {
        return 0;
    }
    return [subData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    NSDictionary *obj = [subData objectAtIndex:[indexPath row]];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //获取消息具体内容
    if ([[[subData objectAtIndex:[indexPath row]] objectForKey:@"read_flag"]  isEqual: @"true"]) {
        //从数据库读取消息
        NSDictionary *data = [User getMessageContentByMid:[[subData objectAtIndex:[indexPath row]] objectForKey:@"mid"]];
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
        postBody = [postBody stringByReplacingOccurrencesOfString:@"myMid" withString:[[subData objectAtIndex:[indexPath row]] objectForKey:@"mid"]];
        
        NSLog(@"postBody: %@", postBody);
        [request setPostBody:(NSMutableData *)[postBody dataUsingEncoding:NSUTF8StringEncoding]];
        
        request.delegate = self;
        [request startAsynchronous];
        //标记为已读
        NSString *readFlag = [[NSString alloc] initWithString:@"true"];
        NSMutableDictionary *obj = [[NSMutableDictionary alloc] initWithDictionary:[subData objectAtIndex:[indexPath row]]];
        NSLog(@"\nObj: %@\n", obj);
        [obj removeObjectForKey:@"read_flag"];
        [obj setObject:readFlag forKey:@"read_flag"];
        [subData replaceObjectAtIndex:[indexPath row] withObject:obj];
        //修改数据库数据标记为已读
        NSLog(@"\nUpdate: %@\n", obj);
        [User updateMessageContentByMid:[obj objectForKey:@"mid"] forField:@"read_flag" withValue:@"true"];
    }
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
    
    SBJSON *json = [[SBJSON alloc] init];
    NSDictionary *dic = [json objectWithString:str];
//    NSLog(@"dic = %@",dic);
    NSString *code = [dic objectForKey:@"code"];
    NSString *msg = [dic objectForKey:@"msg"];
    NSLog(@"code: %@", code);
    if ([code intValue] == 0) {
        NSDictionary *data = [[NSDictionary alloc] initWithDictionary:[dic objectForKey:@"data"]];
//        NSLog(@"\n消息内容：%@\n", data);
        [User insertMessageContent:data];
        [SVProgressHUD dismissWithSuccess:@"获取消息内容成功！"];
        
        MessageContent *messageContent = [[MessageContent alloc] initWithNibName:@"MessageContent" bundle:nil];
        messageContent.title = [data objectForKey:@"title"];
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
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

/*
#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here, for example:
    // Create the next view controller.
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
}
*/

@end
