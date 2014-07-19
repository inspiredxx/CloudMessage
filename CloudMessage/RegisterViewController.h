//
//  RegisterViewController.h
//  CloudMessage
//
//  Created by SoftwareLab on 13-7-9.
//  Copyright (c) 2013年 SoftwareLab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RegisterViewController : UIViewController <UITextFieldDelegate>
{
    UIActivityIndicatorView *activityIndicator;
}

@property (nonatomic, retain) IBOutlet UITextField *usernameTextField;
@property (nonatomic, retain) IBOutlet UITextField *passwordTextField;
@property (nonatomic, retain) IBOutlet UITextField *repeatPasswordTextField;

- (IBAction)onSubmitBtnTouchUpInside:(UIButton *)sender;
- (IBAction)onRegisterCancelBtnTouchUpInside:(UIButton *)sender;

@end
