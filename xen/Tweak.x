// MK1 XenHTML Integration - Copyright (c) 2020 Castyte. All rights reserved.
// Modified work copyright (c) 2020 Skitty.
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>
#import "XENHWidgetController.h"

static CPDistributedMessagingCenter *messagingCenter = nil;
static NSArray<NSString *> *scripts;

static JSValue *(*runScriptWithName)(NSString *);
static void (*activateTrigger)(NSString *);

// Expose mk1Message()
%hook XENHWidgetController

- (void)_loadWebView {
	%orig;

	WKUserScript *mk1Message = [[WKUserScript alloc] initWithSource:@"function mk1Message(name, body) { window.webkit.messageHandlers[name].postMessage(body); }" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
	[self.webView.configuration.userContentController addUserScript:mk1Message];

	for (NSString *scriptName in scripts) {
		[self.webView.configuration.userContentController addScriptMessageHandler:self name:scriptName];
	}
}

%new
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
	NSString *ret;

	if ([message.name isEqualToString:@"runScript"]) {
		JSValue *val = runScriptWithName(message.body);
		ret = [val toString];
	} else if ([message.name isEqualToString:@"activateTrigger"]) {
		JSValue *val = activateTrigger(message.body);
		ret = "null";
	}

	[self.webView evaluateJavaScript:[NSString stringWithFormat:@"mk1Callback({message: {name: '%@', body: '%@'}, return: %@});", message.name, message.body, ret] completionHandler:nil];
}

%end

// Process mk1:// url scheme
%group NeedsCreate
%hook XENHWidgetController

%new
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
	NSURL *url = navigationAction.request.URL;
	if ([url.scheme isEqualToString:@"mk1"]) {
		NSDictionary *userInfo;
		if (url.pathComponents.count > 2) {
			userInfo = @{@"name": url.pathComponents[1], @"arg": url.lastPathComponent};
		} else {
			userInfo = @{@"name": url.lastPathComponent};
		}
		if ([url.host isEqualToString:@"runscript"]) {
			[messagingCenter sendMessageName:@"runscript" userInfo:userInfo];
		} else if ([url.host isEqualToString:@"runtrigger"]) {
			[messagingCenter sendMessageName:@"runtrigger" userInfo:userInfo];
		}
		decisionHandler(WKNavigationActionPolicyCancel);
	} else {
		decisionHandler(WKNavigationActionPolicyAllow);
	}
}

%end
%end

%group NeedsHook
%hook XENHWidgetController

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
	NSURL *url = navigationAction.request.URL;
	if ([url.scheme isEqualToString:@"mk1"]) {
		NSDictionary *userInfo;
		if (url.pathComponents.count > 2) {
			userInfo = @{@"name": url.pathComponents[1], @"arg": url.lastPathComponent};
		} else {
			userInfo = @{@"name": url.lastPathComponent};
		}
		if ([url.host isEqualToString:@"runscript"]){
			[messagingCenter sendMessageName:@"runscript" userInfo:userInfo];
		} else if ([url.host isEqualToString:@"runtrigger"]) {
			[messagingCenter sendMessageName:@"runtrigger" userInfo:userInfo];
		}
		decisionHandler(WKNavigationActionPolicyCancel);
	} else {
		%orig;
	}
}

%end
%end

%ctor {
	void *handle = dlopen("/Library/MobileSubstrate/DynamicLibraries/MK1.dylib", RTLD_LAZY);
	runScriptWithName = dlsym(handle, "runScriptWithName");
	activateTrigger = dlsym(handle, "activateTrigger");
	
	messagingCenter = [CPDistributedMessagingCenter centerNamed:@"xyz.skitty.mk1"];
	rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
	scripts = @[@"runScript", @"activateTrigger"];

	%init;
	if ([%c(XENHWidgetController) instancesRespondToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
		%init(NeedsHook);
	} else {
		%init(NeedsCreate);
	}
}