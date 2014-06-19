//
//  SINavigationMenuView.m
//  NavigationMenu
//
//  Created by Ivan Sapozhnik on 2/19/13.
//  Copyright (c) 2013 Ivan Sapozhnik. All rights reserved.
//

#import "SINavigationMenuView.h"
#import "SIMenuButton.h"
#import "QuartzCore/QuartzCore.h"
#import "SIMenuConfiguration.h"

@interface SINavigationMenuView  ()
{
    float tableViewOffset;
}
@property (nonatomic, strong) SIMenuButton *menuButton;
@property (nonatomic, strong) SIMenuTable *table;
@property (nonatomic, strong) UIView *menuContainer;
@end

@implementation SINavigationMenuView

- (id)initWithFrame:(CGRect)frame title:(NSString *)title
{
    self = [super initWithFrame:frame];
    if (self) {
        frame.origin.y += 1.0;
        self.menuButton = [[SIMenuButton alloc] initWithFrame:frame];
        self.menuButton.title.text = title;
        [self.menuButton.title setFont:[UIFont systemFontOfSize:18]];
        self.menuButton.title.textColor = [UIColor blackColor];
        [self.menuButton addTarget:self action:@selector(onHandleMenuTap:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.menuButton];
    }
    return self;
}

- (void)displayMenuInView:(UIView *)view
{
    self.menuContainer = view;
}

- (void)setTitle:(NSString *)title
{
    self.menuButton.title.text = title;
}

#pragma mark -
#pragma mark Actions
- (void)onHandleMenuTap:(id)sender
{
    UITableView *tableView = self.menuContainer;
    if ([tableView isDecelerating] == true) {
        return;
    }
    if (self.menuButton.isActive) {
        NSLog(@"On show");
        [self onShowMenu];
    } else {
        NSLog(@"On hide");
        [self onHideMenu];
    }
}

- (void)onShowMenu
{
    UITableView *tableView = self.menuContainer;
    
    if (!self.table) {
//        UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
//        CGRect frame = mainWindow.frame;
//        frame.origin.y += self.frame.size.height + [[UIApplication sharedApplication] statusBarFrame].size.height;
        self.table = [[SIMenuTable alloc] initWithFrame:self.menuContainer.frame items:self.items];
        self.table.menuDelegate = self;
    }
    [self.menuContainer addSubview:self.table];
    //滚动到顶部，防止出现菜单漂移
    [tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    NSLog(@"\nshow y: %f\n", tableView.contentOffset.y);
//    [self.table setFrame:CGRectMake(0, tableView.contentOffset.y+64, 320, 960)];
    [self.table setFrame:CGRectMake(0, 0, 320, 960)];
    tableViewOffset = tableView.contentOffset.y+64;
    [tableView setScrollEnabled:NO];
    [self rotateArrow:M_PI];
    [self.table show];
}

- (void)onHideMenu
{
    [self rotateArrow:0];
    [self.table hide];
    UITableView *tableView = self.menuContainer;
    NSLog(@"\nhide y: %f\n", tableView.contentOffset.y);
//    [self.table setFrame:CGRectMake(0, tableView.contentOffset.y+64, 320, 960)];
//    [self.table setFrame:CGRectMake(0, tableViewOffset, 320, 640)];
    [self.table setFrame:CGRectMake(0, 0, 320, 960)];
    [tableView setScrollEnabled:YES];
}

- (void)rotateArrow:(float)degrees
{
    [UIView animateWithDuration:[SIMenuConfiguration animationDuration] delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.menuButton.arrow.layer.transform = CATransform3DMakeRotation(degrees, 0, 0, 1);
    } completion:NULL];
}

#pragma mark -
#pragma mark Delegate methods
- (void)didSelectItemAtIndex:(NSUInteger)index
{
    self.menuButton.isActive = !self.menuButton.isActive;
    [self onHandleMenuTap:nil];
    [self.delegate didSelectItemAtIndex:index];
}

- (void)didBackgroundTap
{
    self.menuButton.isActive = !self.menuButton.isActive;
    [self onHandleMenuTap:nil];
}

#pragma mark -
#pragma mark Memory management
- (void)dealloc
{
    self.items = nil;
    self.menuButton = nil;
    self.menuContainer = nil;
}

@end
