//
//  RegisterViewController.m
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-9.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import "RegisterViewController.h"
#import "SVProgressHUD.h"
#import <ASIHTTPRequest/ASIHTTPRequestHeader.h>
#import "SBJSON.h"
#import "PublicDefinition.h"

@interface RegisterViewController ()

@end

@implementation RegisterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"default.png"]]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.passwordTextField setDelegate:self];
    [self.usernameTextField setDelegate:self];
    [self.repeatPasswordTextField setDelegate:self];
    self.usernameTextField.tag = 1000;
    self.passwordTextField.tag = 1001;
    self.repeatPasswordTextField.tag = 1002;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onSubmitBtnTouchUpInside:(UIButton *)sender {
    if ([[self.usernameTextField text] isEqualToString:@""]) {
        NSLog(@"用户名为空");
        [SVProgressHUD showErrorWithStatus:@"用户名不能为空"];
        return;
    }
    if ([[self.passwordTextField text] isEqualToString:@""]) {
        [SVProgressHUD showErrorWithStatus:@"密码不能为空"];
        return;
    }
    if ([[self.passwordTextField text] isEqualToString:[self.repeatPasswordTextField text]]) {
        NSLog(@"注册");
        
        ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:@"http://59.77.134.226:80/mobile_register"]];
        
        [request setRequestMethod:@"POST"];
        NSString *postBody = @"{\"email\":\"myEmail\",\"pwd\":\"myPwd\"}";
        postBody = [postBody stringByReplacingOccurrencesOfString:@"myEmail" withString:[self.usernameTextField text]];
        postBody = [postBody stringByReplacingOccurrencesOfString:@"myPwd" withString:[self.passwordTextField text]];
        NSLog(@"postBody: %@", postBody);
        [request setPostBody:(NSMutableData *)[postBody dataUsingEncoding:NSUTF8StringEncoding]];
        
        request.delegate = self;
        [request startAsynchronous];
    } else {
        [SVProgressHUD showErrorWithStatus:@"两次输入密码不一致"];
        return;
    }
}

- (IBAction)onRegisterCancelBtnTouchUpInside:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"Register Cancel");
    }];
}

#pragma mark Text field delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{    
    CGRect frame;
    int offset = 0;
    if (textField.tag == 1000) {
        frame = self.usernameTextField.frame;
        offset = frame.origin.y + 32 - (self.view.frame.size.height - 216 - 100); //键盘高度216
    } else if (textField.tag == 1001) {
        frame = self.passwordTextField.frame;
        offset = frame.origin.y + 32 - (self.view.frame.size.height - 216 - 50); //键盘高度216
    } else if (textField.tag == 1002) {
        frame = self.repeatPasswordTextField.frame;
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
    } else if (textField.tag == 1002) {
        [self.repeatPasswordTextField resignFirstResponder];
    }
    return YES;
    
}

#pragma mark -
#pragma mark ASIHTTPRequestDelegate

- (void)requestStarted:(ASIHTTPRequest *)request
{
    NSLog(@"请求开始了");
    [activityIndicator startAnimating];
    [SVProgressHUD showWithStatus:@"正在注册"];
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
    
    [SVProgressHUD dismissWithSuccess:@"注册成功"];
    
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
