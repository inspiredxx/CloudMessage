//
//  LoginViewController.h
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-6.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface LoginViewController : UIViewController <UITextFieldDelegate>
{
    UIActivityIndicatorView *activityIndicator;
    User *user;
}

@property (nonatomic, retain) IBOutlet UITextField *usernameTextField;
@property (nonatomic, retain) IBOutlet UITextField *passwordTextField;

- (IBAction)onLoginBtnTouchUpInside:(UIButton *)sender;
- (IBAction)onRegisterBtnTouchUpInside:(UIButton *)sender;

@end
