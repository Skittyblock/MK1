// MKConsoleViewController.m

#import "MKConsoleViewController.h"
#include <notify.h>

MKConsoleViewController *consoleVC;

void updateConsoleNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void*object, CFDictionaryRef userInfo){
    [consoleVC updateConsole];
}

@implementation MKConsoleViewController

- (void)loadView {
    consoleVC = self;
    [super loadView];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearLog)];

    self.parentViewController.title = @"Console";

    self.textView = [[UITextView alloc] initWithFrame:self.view.frame];
    self.textView.delegate = self;
    self.textView.attributedText = [[NSMutableAttributedString alloc] initWithString:@"Log is empty"];
    self.textView.font = [UIFont fontWithName:@"Courier" size:12];
    self.textView.editable = NO;
    [self updateConsole];
    [self.view addSubview:self.textView];

    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    if (center) {
        CFNotificationCenterAddObserver(center, NULL, updateConsoleNotification, CFSTR("xyz.skitty.mk1app.updateconsole"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    }
}

- (void)updateConsole {
    NSError *error;
    NSString *logtxt = [NSString stringWithContentsOfFile:@"/tmp/MK1.log" encoding:NSUTF8StringEncoding error:&error];
    if (error) self.textView.text = [error localizedDescription];
    else if(logtxt.length > 1) {
        self.textView.attributedText = [[NSAttributedString alloc] initWithString:logtxt attributes:@{NSForegroundColorAttributeName:UIColor.blackColor}];
        [self setColorForText:@"[DEBUG]" color:UIColor.magentaColor];
        [self setColorForText:@"[ERROR]" color:UIColor.redColor];
        [self setColorForText:@"[INFO]" color:UIColor.blueColor];
        [self setColorForText:@"[WARN]" color:UIColor.orangeColor];
    }
}

- (void)setColorForText:(NSString*)textToFind color:(UIColor*)color {
    NSMutableAttributedString *str = [self.textView.attributedText mutableCopy];
    [self.textView.attributedText.string enumerateSubstringsInRange:[self.textView.attributedText.string rangeOfString:self.textView.attributedText.string] options:NSStringEnumerationByLines usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop){
        if ([substring hasPrefix:textToFind]) [str addAttribute:NSForegroundColorAttributeName value:color range:substringRange];
    }];
    self.textView.attributedText = str;
}

- (void)clearLog {
    [@"[INFO] [MK1] Log cleared." writeToFile:@"/tmp/MK1.log" atomically:NO encoding:NSUTF8StringEncoding error:nil];
    [self updateConsole];
}

@end
