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
    //阅读时长截停计时器
    NSTimer *mainTimer;
    //阅读粒度计时器
    NSTimer *subTimer;
    //有效拖动判断计时器
    NSTimer *dragTimer;
    //有效滑动判断计时器
    NSTimer *deceleratingTimer;
    //长时间拖动计时器
    NSTimer *draggingTimer;
    float readingTime;
    NSInteger dragCount;
    NSInteger deceleratingCount;
    BOOL timerIsRunning;
    BOOL isFullReading;
    float rating;
    //阅读区域高度
    float readHt;
    //阅读过的页面高度
    float readHeight;
    //阅读时长超时阈值
    float readTimeThreshold;
    
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
//    NSLog(@"\nContent: %@\n", self.content);

    
    //修改图片宽度
    NSString *jsStr = @"<script type=\"text/javascript\">\n\
    function resizepic(thispic)\n\
    {\n\
        if(thispic.width>304) thispic.width=304;\n\
    }\n</script>\n<body>\n";
    self.content = [jsStr stringByAppendingString:self.content];
//    self.content = [self.content stringByReplacingOccurrencesOfString:@"<img" withString:@"<img style=\"width:304px;\" "];
    self.content = [self.content stringByReplacingOccurrencesOfString:@"<img" withString:@"<img onload=\"javascript:resizepic(this)\" "];
    self.content = [self.content stringByReplacingOccurrencesOfString:@"<IMG" withString:@"<img onload=\"javascript:resizepic(this)\" "];
    
//    [self.content stringByReplacingOccurrencesOfString:@"<img" withString:@"<img onload=\"javascript:resizepic(this)\" " options:NSWidthInsensitiveSearch range:NSMakeRange(0, self.content.length)];
    
    
    NSString *metaStr = @"<html>\n";
    self.content = [metaStr stringByAppendingString:self.content];
    self.content = [self.content stringByAppendingString:@"\n</body>\n</html>"];
    
//    NSLog(@"\ncontent:\n%@\n", self.content);
    
    readTimeThreshold = 12;
    readHt = [UIScreen mainScreen].applicationFrame.size.height - self.navigationController.navigationBar.frame.size.height;
    
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
    readingTime = 0;
    dragCount = 0;
    deceleratingCount = 0;
    timerIsRunning = YES;
    isFullReading = NO;
    rating = 0;

    readHeight = readHt;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.webView stopLoading];
    [self.webView setDelegate:nil];
    [super viewWillDisappear:animated];
    [self hideTabBar:NO];
    [mainTimer invalidate];
    [subTimer invalidate];
    [dragTimer invalidate];
    [deceleratingTimer invalidate];
    [draggingTimer invalidate];
    
//    NSLog(@"\nheight: %.0lf\n", self.webView.scrollView.contentSize.height);
    
    if (self.webView.scrollView.contentSize.height <= readHt/*568-64*/) {
        //recount height 有可能更大
        readHeight = self.webView.scrollView.contentSize.height;
        readHeight = MIN(readHeight, [self flattenHTML:self.content trimWhiteSpace:YES].length * readHeight/400 + 40);
        if ([self.content rangeOfString:@"<img "].length > 0) {
            //包含图片
            readHeight += 228;
        }
        NSLog(@"\nRecount height: %.2lf\n", readHeight);
        isFullReading = YES;
    } else if (readHeight/self.webView.scrollView.contentSize.height >= 0.9) {
        isFullReading = YES;
//        NSLog(@"\nreadHeight>=0.9\n");
    }
    
    NSString *dateStr = [self fixStringForDate:[NSDate date]];
    
    NSLog(@"\ntime height full decelerating drag rating date\n%.1f %.0lf %d %d %d %.2lf %@ %@\n",
          readingTime,
          readHeight,
          isFullReading,
          deceleratingCount,
          dragCount,
          rating,
          dateStr,
          self._id);
    
    if (rating != 0) {
        //保存行为数据
//        NSString *userBehaviorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"behaviorData"];
//        NSMutableArray *behaviorDataArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"behaviorDataArray"];
        NSMutableArray *behaviorDataArray = [[NSMutableArray alloc] init];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"behaviorDataArray"] != nil) {
            NSLog(@"behaviorDataArray != nil");
            [behaviorDataArray addObjectsFromArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"behaviorDataArray"]];
        }

        NSString *userBehaviorData = [[NSString alloc] initWithFormat:@"%.1f %.0lf %d %d %d %.2lf %@ %@\n", readingTime, readHeight, isFullReading, deceleratingCount, dragCount, rating, dateStr, self._id];
    //    NSLog(@"\nuserBehaviorData:\n%@\n", userBehaviorData);
        [behaviorDataArray addObject:userBehaviorData];
//        [[NSUserDefaults standardUserDefaults] setObject:userBehaviorData forKey:@"behaviorData"];
        [[NSUserDefaults standardUserDefaults] setObject:behaviorDataArray forKey:@"behaviorDataArray"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

//修正日期格式
- (NSString *)fixStringForDate:(NSDate *)date
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterFullStyle];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *fixString = [dateFormatter stringFromDate:date];
    return fixString;
}

- (NSString *)flattenHTML:(NSString *)html trimWhiteSpace:(BOOL)trim {
    NSScanner *theScanner = [NSScanner scannerWithString:html];
    NSString *text = nil;
    
    //跳过<script>
    html = [html substringFromIndex:[html rangeOfString:@"<body>"].location];
    NSLog(@"\nhtml: %@\n", html);
    
    while ([theScanner isAtEnd] == NO) {
        // find start of tag
        [theScanner scanUpToString:@"<" intoString:NULL] ;
        // find end of tag
        [theScanner scanUpToString:@">" intoString:&text] ;
        // replace the found tag with a space
        //(you can filter multi-spaces out later if you wish)
        html = [html stringByReplacingOccurrencesOfString: [NSString stringWithFormat:@"%@>", text] withString:@""];
    }
    
    //去除&nbsp; 空格
    html = [html stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    
    // trim off whitespace
    return trim ? [html stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : html;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"\n加载完成\nreadingTime: %.0lf\n", readingTime);
    if (self.webView.scrollView.contentSize.height > readHt) {
        //页面高度大于一屏
        readTimeThreshold = 12;
    } else {
        //页面高度不足一屏幕
        readTimeThreshold = MIN(12, (float)([self flattenHTML:self.content trimWhiteSpace:YES].length) * 12.0f / 400.0f);
        if ([self.content rangeOfString:@"<img "].length > 0) {
            //包含图片
            NSLog(@"\n包含图片，+= 5\n");
            readTimeThreshold += 5;
        }
    }
    NSLog(@"\nreadTimeThreshold: %.1lf\n", readTimeThreshold);
    [mainTimer invalidate];
    [subTimer invalidate];
    mainTimer = [NSTimer scheduledTimerWithTimeInterval:readTimeThreshold target:self selector:@selector(readingTimeCut) userInfo:nil repeats:NO];
    subTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(readingTimeAdd) userInfo:nil repeats:YES];
    
//    NSLog(@"\nreadHt: %.2lf\n", readHt);
}

//阅读时间截停
- (void)readingTimeCut
{
    NSLog(@"\nThreshold: %.1lfs\n", readTimeThreshold);
    timerIsRunning = NO;
    [subTimer setFireDate:[NSDate distantFuture]];
}

//阅读时间累加
- (void)readingTimeAdd
{
    readingTime += 0.1;
    if ((int)(readingTime*10)%10 == 0) {
        NSLog(@"\nreadingTime: %.1fs\n", readingTime);
    }
}

//滑动次数累加
- (void)deceleratingTimeAdd
{
    deceleratingCount ++;
    NSLog(@"\n有效滑动%d次\n", deceleratingCount);
}

//拖动次数累加
- (void)dragTimeAdd
{
    dragCount ++;
    NSLog(@"\n有效拖动%d次\n", dragCount);
}

//dragging计时截停
- (void)draggingTimeCut
{
    NSLog(@"\n长时间dragging！\n");
    dragCount ++;
    
    //开始拖动时的计时
    [draggingTimer invalidate];
    draggingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(draggingTimeAdd) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:draggingTimer forMode:NSRunLoopCommonModes];
}

//dragging计时累加
- (void)draggingTimeAdd
{
    readingTime += 0.1;
    if ((int)(readingTime*10)%10 == 0) {
        NSLog(@"\nreadingTime(dragging): %.1fs\n", readingTime);
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (timerIsRunning == NO) {
        [subTimer setFireDate:[NSDate distantPast]];
        timerIsRunning = YES;
    }
//    NSLog(@"\nwillBeginDragging\n");
    [mainTimer invalidate];
    mainTimer = [NSTimer scheduledTimerWithTimeInterval:readTimeThreshold target:self selector:@selector(readingTimeCut) userInfo:nil repeats:NO];
    //还未加载完成，开始操作则开始计时
    if (subTimer == nil) {
        NSLog(@"\nsubTimer == nil\n");
        subTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(readingTimeAdd) userInfo:nil repeats:YES];
    }
    [dragTimer invalidate];
    [deceleratingTimer invalidate];
    [draggingTimer invalidate];
    
    draggingTimer = [NSTimer scheduledTimerWithTimeInterval:0.7 target:self selector:@selector(draggingTimeCut) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:draggingTimer forMode:NSRunLoopCommonModes];

}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self calcReadHeight];
//    NSLog(@"\n滑动\n");
    [dragTimer invalidate];
    deceleratingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(deceleratingTimeAdd) userInfo:nil repeats:NO];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self calcReadHeight];
//    NSLog(@"\n拖动\n");
    dragTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(dragTimeAdd) userInfo:nil repeats:NO];
    [draggingTimer invalidate];
}

//计算readHeight
- (void)calcReadHeight
{
    if ((self.webView.scrollView.contentSize.height > readHt) && (isFullReading == false)) {
        readHeight = MAX(readHeight, self.webView.scrollView.contentOffset.y + 568);
        readHeight = MIN(readHeight, self.webView.scrollView.contentSize.height);
//        NSLog(@"\nreadHeight: %.0lf\n", readHeight);
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (isFullReading == false) {
        CGPoint contentOffsetPoint = self.webView.scrollView.contentOffset;
        CGRect frame = self.webView.frame;
        if (contentOffsetPoint.y == self.webView.scrollView.contentSize.height - frame.size.height || self.webView.scrollView.contentSize.height < frame.size.height)
        {
            NSLog(@"scroll to the end");
            isFullReading = YES;
            readHeight = self.webView.scrollView.contentSize.height;
        }
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
    NSLog(@"\nMem leaks!\n");
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"MemoryWarning-messageContent" message:@"leaks!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alertView show];
}

@end
