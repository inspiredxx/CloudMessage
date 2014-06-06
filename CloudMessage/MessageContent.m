//
//  MessageContent.m
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-30.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import "MessageContent.h"

@interface MessageContent ()
{
    UIBarButtonItem *ratingButton;
    BOOL ratingFlag;
    ASValueTrackingSlider *slider;
    UIView *bgView;
    NSTimer *mainTimer;
    NSTimer *subTimer;
    NSTimer *dragTimer;
    NSTimer *deceleratingTimer;
    float readingTime;
    NSInteger dragCount;
    NSInteger deceleratingCount;
    BOOL timerIsRunning;
    BOOL isFullReading;
    float rating;
}

@end

@implementation MessageContent

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
//    [self hideTabBar:YES];
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
//    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 44)];
//    titleLabel.text = self.title;
//    self.navigationItem.titleView = titleLabel;
    [self.webView loadHTMLString:self.content baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
    [self.webView setDelegate:self];
    [self.webView.scrollView setDelegate:self];
    
    //设置打分按钮
    ratingButton = [[UIBarButtonItem alloc] initWithTitle:@"打分" style:UIBarButtonItemStylePlain target:self action:@selector(onRatingButton)];
    self.navigationItem.rightBarButtonItem = ratingButton;
    ratingFlag = false;
    
    slider = [[ASValueTrackingSlider alloc] initWithFrame:CGRectMake(30, 10, 0, 0)];
    bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 70, 0, 0)];
    [bgView setBackgroundColor:[UIColor whiteColor]];
    bgView.layer.cornerRadius = 18;
    bgView.layer.borderWidth = 4;
    bgView.layer.borderColor = [[UIColor grayColor] CGColor];
    bgView.layer.masksToBounds = YES;
    [bgView addSubview:slider];
    [slider hidePopUpView];
    [slider setMinimumValue:1];
    [slider setMaximumValue:10];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterNoStyle];
    [formatter setPositiveSuffix:@"分"];
    [slider setNumberFormatter:formatter];
    slider.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:20];
    slider.popUpViewAnimatedColors = @[[UIColor purpleColor], [UIColor redColor], [UIColor orangeColor]];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self hideTabBar:NO];
    [mainTimer invalidate];
    [subTimer invalidate];
    [dragTimer invalidate];
    [deceleratingTimer invalidate];
    NSLog(@"\nReading time: %.1f\nContent height: %.0lf\nFull reading: %d\nDecelerating count: %d\nDrag count: %d\nRating: %.2lf\n",
          readingTime,
          self.webView.scrollView.contentSize.height,
          isFullReading,
          deceleratingCount,
          dragCount,
          rating);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"\n加载完成\n");
    [mainTimer invalidate];
    [subTimer invalidate];
    mainTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(readingTimeCut) userInfo:nil repeats:NO];
    subTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(readingTimeAdd) userInfo:nil repeats:YES];
    readingTime = 0;
    dragCount = 0;
    deceleratingCount = 0;
    timerIsRunning = YES;
    isFullReading = NO;
    rating = 0;
}

//阅读时间截停
- (void)readingTimeCut
{
    NSLog(@"\n10s\n");
    timerIsRunning = NO;
    [subTimer setFireDate:[NSDate distantFuture]];
}

//阅读时间累加
- (void)readingTimeAdd
{
    readingTime += 0.1;
//    NSLog(@"\nreadingTime: %.1f\n", readingTime);
}

//滑动次数累加
- (void)deceleratingTimeAdd
{
    deceleratingCount ++;
    NSLog(@"\n有效滑动%d次\n", deceleratingCount);
}

//拽动次数累加
- (void)dragTimeAdd
{
    dragCount ++;
    NSLog(@"\n有效拽动%d次\n", dragCount);
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (timerIsRunning == NO) {
        [subTimer setFireDate:[NSDate distantPast]];
        timerIsRunning = YES;
    }
    [mainTimer invalidate];
    mainTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(readingTimeCut) userInfo:nil repeats:NO];
    [dragTimer invalidate];
    [deceleratingTimer invalidate];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"\n滑动\n");
    [dragTimer invalidate];
    deceleratingTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(deceleratingTimeAdd) userInfo:nil repeats:NO];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    NSLog(@"\n拽动\n");
    dragTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(dragTimeAdd) userInfo:nil repeats:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([scrollView isDecelerating] == true) {
//        NSLog(@"滑动");
    } else {
//        NSLog(@"拽动");
    }
    
    CGPoint contentOffsetPoint = self.webView.scrollView.contentOffset;
    CGRect frame = self.webView.frame;
    if (contentOffsetPoint.y == self.webView.scrollView.contentSize.height - frame.size.height || self.webView.scrollView.contentSize.height < frame.size.height)
    {
        NSLog(@"scroll to the end");
        isFullReading = YES;
    }	
}

- (void)hideTabBar:(BOOL) hidden
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

- (void)onRatingButton
{
    if (ratingFlag == false) {
        //暂停计时器
        [mainTimer setFireDate:[NSDate distantFuture]];
        [subTimer setFireDate:[NSDate distantFuture]];
        [dragTimer setFireDate:[NSDate distantFuture]];
        [deceleratingTimer setFireDate:[NSDate distantFuture]];
        ratingFlag = true;
        [ratingButton setTitle:@"完成"];
        [self.webView addSubview:bgView];
        CGContextRef context = UIGraphicsGetCurrentContext();
        [UIView beginAnimations:nil context:context];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [UIView setAnimationDuration:0.05];
        [slider setFrame:CGRectMake(30, 40, 260, 70)];
        [bgView setFrame:CGRectMake(0, 70, 320, 100)];
        [UIView commitAnimations];
        [slider showPopUpView];
    } else {
        //重启计时器
//        [mainTimer setFireDate:[NSDate distantPast]];
//        [subTimer setFireDate:[NSDate distantPast]];
//        [dragTimer setFireDate:[NSDate distantPast]];
//        [deceleratingTimer setFireDate:[NSDate distantPast]];
        ratingFlag = false;
        [ratingButton setTitle:@"打分"];
        [slider hidePopUpView];
        [bgView setFrame:CGRectMake(0, 70, 0, 0)];
//        NSLog(@"\n评分为：%f %d\n", slider.value, [[[NSNumber alloc] initWithFloat:slider.value] intValue]);
        rating = slider.value;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
