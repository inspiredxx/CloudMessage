//
//  Setup.m
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-28.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import "Setup.h"
#import "LoginViewController.h"
#import "PublicDefinition.h"
#import "CMNavBarNotificationView.h"
#import "User.h"

@interface Setup ()
{
    NSArray *cellsData0, *cellsData1;
    UISwitch *switch0, *switch1;
    NSArray *switchArray;
}

@end

@implementation Setup

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
    cellsData0 = [[NSArray alloc] initWithArray:@[@"注销登录", @"清空用户数据"]];
    cellsData1 = [[NSArray alloc] initWithArray:@[@"上传行为数据", @"个性化推荐"]];
    switch0 = [[UISwitch alloc] initWithFrame:CGRectZero];
    switch1 = [[UISwitch alloc] initWithFrame:CGRectZero];
    switchArray = [[NSArray alloc] initWithObjects:switch0, switch1, nil];
    [switch0 addTarget:self action:@selector(updateSwitch0:) forControlEvents:UIControlEventValueChanged];
    [switch1 addTarget:self action:@selector(updateSwitch1:) forControlEvents:UIControlEventValueChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    if ([indexPath section] == 0) {
        cell.textLabel.text = [cellsData0 objectAtIndex:[indexPath row]];
    } else if ([indexPath section] == 1)
    {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = [cellsData1 objectAtIndex:[indexPath row]];
        cell.accessoryView = [switchArray objectAtIndex:[indexPath row]];
    }
    return cell;
}

- (void)updateSwitch0:(id)sender
{
    UISwitch *switchView = (UISwitch *)sender;
    if ([switchView isOn] == true) {
        NSLog(@"\n打开行为数据上传\n");
//        NSString *userDefaultData = [[NSUserDefaults standardUserDefaults] objectForKey:@"behaviorData"];
        NSMutableArray *behaviorDataArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"behaviorDataArray"];
        NSString *dataStr = [[NSString alloc] init];
        for (NSString *data in behaviorDataArray) {
            //NSLog(@"%@", data);
            dataStr = [dataStr stringByAppendingString:data];
        }
        NSLog(@"\n%@\n", dataStr);
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"behaviorDataArray"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        NSLog(@"\n关闭行为数据上传\n");
    }
}

- (void)updateSwitch1:(id)sender
{
    UISwitch *switchView = (UISwitch *)sender;
    if ([switchView isOn] == true) {
        NSLog(@"\n打开个性化推荐\n");
    } else {
        NSLog(@"\n关闭个性化推荐\n");
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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    if ([indexPath section] == 0) {
        if ([indexPath row] == 0) {
            NSLog(@"注销");
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:ACCESS_TOKEN];
            //        NSLog(@"\naccess_token: %@\n", [[NSUserDefaults standardUserDefaults] objectForKey:ACCESS_TOKEN]);
            [[NSUserDefaults standardUserDefaults] synchronize];
            LoginViewController *loginViewController = [[[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil] autorelease];
            [self presentViewController:loginViewController animated:YES completion:^{
                NSLog(@"\nLogin VC\n");
            }];
        } else if ([indexPath row] == 1) {
            NSLog(@"\n清空数据\n");
//        [[NSUserDefaults standardUserDefaults] init];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:[User getUid]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [User emptyDataBase];
            [CMNavBarNotificationView notifyWithText:@"已清空所有数据" detail:@"" andDuration:0.3];
        }
    }
    
}

@end
