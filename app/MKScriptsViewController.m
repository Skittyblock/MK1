// MKScriptsViewController.m

#import "MKScriptsViewController.h"
#import "MKScript.h"
#import "MKAppDelegate.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>
#import <UIKit/UIKit+Private.h>

@implementation MKScriptsViewController

- (void)loadView {
    [super loadView];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"About" style:UIBarButtonItemStylePlain target:self action:@selector(aboutMK1)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"View Docs" style:UIBarButtonItemStylePlain target:self action:@selector(viewDocs)];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshScripts) forControlEvents:UIControlEventValueChanged];
    self.scripts = [[NSMutableOrderedSet alloc] init];
    [self refreshScripts];
}

- (void)aboutMK1 {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"MK1" message:@"Copyright (c) Castyte 2020. All Rights Reserved.\nModified work copyright (c) Skitty 2020.\nSee documentation for full credits." preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *twitter = [UIAlertAction actionWithTitle:@"Open @castyte Twitter" style:UIAlertActionStyleDefault handler:^(id _) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/castyte"] options:@{} completionHandler:nil];
    }];
    [alert addAction:twitter];

    UIAlertAction *twitter2 = [UIAlertAction actionWithTitle:@"Open @Skittyblock Twitter" style:UIAlertActionStyleDefault handler:^(id _) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/Skittyblock"] options:@{} completionHandler:nil];
    }];
    [alert addAction:twitter2];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:^(id _){}];
    [alert addAction:okAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewDocs {
     if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"filza://"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"filza://view/Library/MK1/DOCS.md"] options:@{} completionHandler:nil];
    } else {
        alertError(@"Unable to open Filza. You can find the documentation file at /Library/MK1/DOCS.md");
    }
}

- (void)refreshScripts {
    [self.scripts removeAllObjects];
    NSError *dError;
    NSData *jsonData = [NSData dataWithContentsOfFile:@"/Library/MK1/scripts.json" options:kNilOptions error:&dError];
    if (dError) {
        alertError([dError localizedDescription]);
        return;
    }
    NSError *jError;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jError];
    if (jError) {
        alertError([jError localizedDescription]);
        return;
    }
    self.scriptsDict = [dict mutableCopy];
    for (__block NSString *trigger in self.scriptsDict) {
        for (NSString *script in self.scriptsDict[trigger]) {
            [self.scripts addObject:[[MKScript alloc] initWithName:script trigger:trigger]];
        }
    }
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.scripts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
	}

	MKScript *script = self.scripts[indexPath.row];
	cell.textLabel.text = script.name;
    cell.detailTextLabel.text = script.trigger;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *name = self.scripts[indexPath.row].name;
    NSMutableArray *new = [self.scriptsDict[self.scripts[indexPath.row].trigger] mutableCopy];
    [new removeObject:name];
    self.scriptsDict[self.scripts[indexPath.row].trigger] = new;
    [self saveScriptsDict];

    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/Library/MK1/Scripts/%@.js", name] error:nil];
    [self refreshScripts];
}

- (void)textBoxWithTitle:(NSString *)title message:(NSString *)msg initText:(NSString *)initText block:(void (^)(NSString *))block {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf){
        tf.text = initText;
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
		handler:^(UIAlertAction * action) {}];
    [alert addAction:cancelAction];

	UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        block([alert textFields][0].text);
    }];
	[alert addAction:okAction];

	[self presentViewController:alert animated:YES completion:nil];
}

- (void)saveScriptsDict {
    NSError *jsonError; 
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.scriptsDict options:NSJSONWritingPrettyPrinted error:&jsonError];
    if (jsonError) {
        alertError([jsonError localizedDescription]);
        return;
    }

    NSError *writeError;
    [jsonData writeToFile:@"/Library/MK1/scripts.json" options:NSDataWritingAtomic error:&writeError];
    if (writeError) {
        alertError([writeError localizedDescription]);
        return;
    }

    static CPDistributedMessagingCenter *c = nil;
    c = [CPDistributedMessagingCenter centerNamed:@"xyz.skitty.mk1"];
    rocketbootstrap_distributedmessagingcenter_apply(c);
    [c sendMessageName:@"updateScripts" userInfo:nil];
}


- (void)setScriptName:(MKScript *)script name:(NSString *)newName {
    NSMutableArray *new = [self.scriptsDict[script.trigger] mutableCopy];
    [new removeObject:script.name];
    [new addObject:newName];
    self.scriptsDict[script.trigger] = new;

    [self saveScriptsDict];

    NSError *moveError;
    [[NSFileManager defaultManager] moveItemAtPath:script.path toPath:[NSString stringWithFormat:@"/Library/MK1/Scripts/%@.js", newName] error:&moveError];

    if (moveError) {
        alertError([moveError localizedDescription]);
        return;
    }

    [self refreshScripts];
}

- (void)setScriptTrigger:(MKScript *)script trigger:(NSString *)trigger {
    NSMutableArray *new = [self.scriptsDict[script.trigger] mutableCopy];
    [new removeObject:script.name];
    self.scriptsDict[script.trigger] = new;

    if (!self.scriptsDict[trigger]) {
        self.scriptsDict[trigger] = [@[script.name] mutableCopy];
    } else {
        NSMutableArray *new2 = [self.scriptsDict[trigger] mutableCopy];
        [new2 addObject:script.name];
        self.scriptsDict[trigger] = new2;
    }

    [self saveScriptsDict];
    [self refreshScripts];
}

- (void)confirmationDialogWithTitle:(NSString *)title message:(NSString *)message block:(void (^)(BOOL))block {
    dispatch_async(dispatch_get_main_queue(), ^ {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
        handler:^(UIAlertAction *action) {
            block(NO);
        }];
        [alert addAction:cancelAction];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *action) {
            block(YES);
        }];
        [alert addAction:okAction];

        alert.preferredAction = okAction;
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)shareScript:(MKScript *)script description:(NSString *)description {
    [self confirmationDialogWithTitle:@"Share script publicly?" message:@"This will upload the script to a public URL where it can be shared with anyone.\n\nBy continuing you confirm you have permission to upload the content, and that it does not contain any personal information." block:^(BOOL choice){
        if (!choice) return;
        __block UIProgressHUD *hud = [[UIProgressHUD alloc] initWithFrame:CGRectZero];
        [hud setText:@"Uploading"];
        [hud showInView:self.view];

        NSError *codeError;
        NSString *code = [script codeWithError:&codeError];
        if (codeError) return alertError([codeError localizedDescription]);

        NSError *jsonError;
        NSData *postData = [NSJSONSerialization dataWithJSONObject:@{
            @"name": script.name,
            @"description": description,
            @"trigger": script.trigger,
            @"code": code
        } options:kNilOptions error:&jsonError];
        if (jsonError) return alertError([jsonError localizedDescription]);

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://mk1.skitty.xyz/s/api/new"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];

        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:postData];

        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) return alertError([error localizedDescription]);
            if (((NSHTTPURLResponse *)response).statusCode != 200) return alertError(@"Unknown error while uploading script. Please try again later.");
            UIPasteboard.generalPasteboard.URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://mk1.skitty.xyz/s/%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hide];

                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Script Uploaded" message:@"A public URL to share the script has been copied to the clipboard" preferredStyle:UIAlertControllerStyleAlert];

                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
                [alert addAction:okAction];

                [self presentViewController:alert animated:YES completion:nil];
            });
        }] resume];
    }];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

	alert.popoverPresentationController.sourceView = [tableView cellForRowAtIndexPath:indexPath];
    alert.popoverPresentationController.sourceRect = alert.popoverPresentationController.sourceView.bounds;

    UIAlertAction *runAction = [UIAlertAction actionWithTitle:@"Run Script" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        static CPDistributedMessagingCenter *c = nil;
        c = [CPDistributedMessagingCenter centerNamed:@"xyz.skitty.mk1"];
        rocketbootstrap_distributedmessagingcenter_apply(c);
        [c sendMessageName:@"runscript" userInfo:@{@"name": self.scripts[indexPath.row].name}];
    }];
    [alert addAction:runAction];

    UIAlertAction *nameAction = [UIAlertAction actionWithTitle:@"Change Script Name" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self textBoxWithTitle:@"Script Name" message:nil initText:self.scripts[indexPath.row].name block:^(NSString *name){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setScriptName:self.scripts[indexPath.row] name:name];
            });
        }];
    }];
    [alert addAction:nameAction];

    UIAlertAction *triggerAction = [UIAlertAction actionWithTitle:@"Change Script Trigger" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self textBoxWithTitle:@"Script Trigger" message:nil initText:self.scripts[indexPath.row].trigger block:^(NSString *trigger){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setScriptTrigger:self.scripts[indexPath.row] trigger:trigger];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Trigger Updated" message:@"A respring may be required for changes to take effect" preferredStyle:UIAlertControllerStyleAlert];

                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
                [alert addAction:okAction];

                [self presentViewController:alert animated:YES completion:nil];
            });
        }];
    }];
    [alert addAction:triggerAction];

    UIAlertAction *shareAction = [UIAlertAction actionWithTitle:@"Share Script" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self textBoxWithTitle:@"Script Description" message:@"A brief description of what the script does." initText:@"" block:^(NSString *description){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self shareScript:self.scripts[indexPath.row] description:description];
            });
        }];
    }];
    [alert addAction:shareAction];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"filza://"]]) {
        UIAlertAction *filzaAction = [UIAlertAction actionWithTitle:@"Show in Filza" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"filza://view/%@", self.scripts[indexPath.row].path]] options:@{} completionHandler:nil];
        }];
        [alert addAction:filzaAction];
    }

	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
	[alert addAction:cancelAction];

	[self presentViewController:alert animated:YES completion:nil];

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
