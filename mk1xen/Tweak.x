// MK1 XenHTML Integration - Copyright (c) 2020 Castyte. All rights reserved.

#import <WebKit/WebKit.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

@interface XENHWidgetController <WKScriptMessageHandler>
@end

static CPDistributedMessagingCenter *messagingCenter = nil;


%group NeedsCreate

%hook XENHWidgetController

%new

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
	NSURL *url = navigationAction.request.URL;
	if([url.scheme isEqualToString:@"mk1"]){
		NSDictionary *userInfo;
		if(url.pathComponents.count > 2) userInfo = @{@"name": url.pathComponents[1], @"arg": url.lastPathComponent};
		else userInfo = @{@"name": url.lastPathComponent};
		if([url.host isEqualToString:@"runscript"]){
			[messagingCenter sendMessageName:@"runscript" userInfo:userInfo];
		} else if([url.host isEqualToString:@"runtrigger"]){
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

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
	NSURL *url = navigationAction.request.URL;
	if([url.scheme isEqualToString:@"mk1"]){
		NSDictionary *userInfo;
		if(url.pathComponents.count > 2) userInfo = @{@"name": url.pathComponents[1], @"arg": url.lastPathComponent};
		else userInfo = @{@"name": url.lastPathComponent};
		if([url.host isEqualToString:@"runscript"]){
			[messagingCenter sendMessageName:@"runscript" userInfo:userInfo];
		} else if([url.host isEqualToString:@"runtrigger"]){
			[messagingCenter sendMessageName:@"runtrigger" userInfo:userInfo];
		}
		decisionHandler(WKNavigationActionPolicyCancel);
	} else {
		%orig;
	}
}

%end

%end


%ctor{
	messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.castyte.mk1"];
	rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
	if([%c(XENHWidgetController) instancesRespondToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]){
		%init(NeedsHook);
	} else {
		%init(NeedsCreate);
	}
}