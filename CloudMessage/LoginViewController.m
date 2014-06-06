//
//  LoginViewController.m
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-6.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import "LoginViewController.h"
#import "SBJSON.h"
#import "ASIFormDataRequest.h"
#import "SVProgressHUD.h"
#import "RegisterViewController.h"
#import "PublicDefinition.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
//        [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"login.png"]]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.usernameTextField setDelegate:self];
    [self.passwordTextField setDelegate:self];
    self.usernameTextField.tag = 1000;
    self.passwordTextField.tag = 1001;
}

- (void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
    [self.usernameTextField setText:[[NSUserDefaults standardUserDefaults] objectForKey:USER_NAME]];
    [self.passwordTextField setText:[[NSUserDefaults standardUserDefaults] objectForKey:PASSWORD]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onLoginBtnTouchUpInside:(UIButton *)sender {
    
    NSLog(@"登录！");
    if ([[self.usernameTextField text] length] == 0) {
        [SVProgressHUD showErrorWithStatus:@"用户名不能为空"];
        return;
    }
    if ([[self.passwordTextField text] length] == 0) {
        [SVProgressHUD showErrorWithStatus:@"密码不能为空"];
        return;
    }
    ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://59.77.134.226:80/mobile_login"]];
    
    [request setRequestMethod:@"POST"];
    NSString *postBody = @"{\"email\":\"myEmail\",\"pwd\":\"myPwd\"}";
    postBody = [postBody stringByReplacingOccurrencesOfString:@"myEmail" withString:[self.usernameTextField text]];
    postBody = [postBody stringByReplacingOccurrencesOfString:@"myPwd" withString:[self.passwordTextField text]];
    NSLog(@"postBody: %@", postBody);
    [request setPostBody:(NSMutableData *)[postBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    request.delegate = self;
    [request startAsynchronous];
}

- (IBAction)onRegisterBtnTouchUpInside:(UIButton *)sender {
    RegisterViewController *registerViewController = [[RegisterViewController alloc] init];
    [self presentViewController:registerViewController animated:YES completion:^{
        NSLog(@"Register");
    }];
//    [registerViewController release];
}

#pragma mark Text field delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{

    CGRect frame;
    int offset;
    if (textField.tag == 1000) {
        //用户名框
        frame = self.usernameTextField.frame;
        offset = frame.origin.y + 32 - (self.view.frame.size.height - 216 - 50); //键盘高度216
    } else if (textField.tag == 1001) {
        frame = self.passwordTextField.frame;
        offset = frame.origin.y + 32 - (self.view.frame.size.height - 216); //键盘高度216
    }
        
    if (offset > 0) {
        [UIView animateWithDuration:0.3 animations:^{
            self.view.frame = CGRectMake(0, -offset, self.view.frame.size.width, self.view.frame.size.height);
        }];
    }    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSLog(@"\nReturn\n");
    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    }];

    if (textField.tag == 1000) {
        [self.usernameTextField resignFirstResponder];
    
    } else if (textField.tag == 1001) {
        [self.passwordTextField resignFirstResponder];
    }
    return YES;
}

#pragma mark -
#pragma mark ASIHTTPRequestDelegate

- (void)requestStarted:(ASIHTTPRequest *)request
{
    NSLog(@"请求开始了");
    [activityIndicator startAnimating];
    [SVProgressHUD showWithStatus:@"正在登录"];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSLog(@"请求结束了");
    [activityIndicator stopAnimating];
    
    //responseString就是response响应的正文内容.(即网页的源代码)
    NSString *str = request.responseString;
    if ([str length] == 0) {
        NSLog(@"str为空！");
    }
    //NSLog(@"str is ---> %@",str);
    
    SBJSON *json = [[SBJSON alloc] init];
    NSDictionary *dic = [json objectWithString:str];
    NSLog(@"dic = %@",dic);
    NSString *code = [dic objectForKey:@"code"];
    NSString *msg = [dic objectForKey:@"msg"];
    NSLog(@"code: %@", code);
    if ([code intValue] == 0) {
        NSDictionary *data = [dic objectForKey:@"data"];
        NSString *accessToken = [data objectForKey:@"access_token"];
        NSString *uid = [data objectForKey:@"uid"];
        NSLog(@"access_token: %@ uid:%@", accessToken, uid);
//        [User setUser:[self.usernameTextField text] withPassword:[self.passwordTextField text] withAccessToken:accessToken withUid:uid];
        [[NSUserDefaults standardUserDefaults] setObject:[self.usernameTextField text] forKey:USER_NAME];
        [[NSUserDefaults standardUserDefaults] setObject:[self.passwordTextField text] forKey:PASSWORD];
        [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:ACCESS_TOKEN];
        [[NSUserDefaults standardUserDefaults] setObject:uid forKey:UID];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        NSLog(@"msg: %@", msg);
    }
    
    user = [User sharedUser];
    [SVProgressHUD dismissWithSuccess:@"登录成功"];
    
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"LoginView Dismiss");
    }];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    
    NSLog(@"请求失败了");
//    NSLog([[request error] localizedDescription]);
}

@end
