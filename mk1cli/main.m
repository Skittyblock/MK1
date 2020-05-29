// MK1 CLI - Copyright (c) 2020 Castyte. All rights reserved.

#include <stdio.h>
#include <string.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

int main(int argc, char *argv[], char *envp[]) {
	static CPDistributedMessagingCenter *c = nil;
	c = [CPDistributedMessagingCenter centerNamed:@"com.castyte.mk1"];
	rocketbootstrap_distributedmessagingcenter_apply(c);
	if(argc < 3){
		printf("Usage: %s <runscript | runtrigger> <name> [arg]\n", argv[0]);
	} else if(strcmp(argv[1], "runscript") == 0){
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
		if(argc > 3) userInfo[@"arg"] = [NSString stringWithCString:argv[3] encoding:NSUTF8StringEncoding];
		userInfo[@"name"] = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
		[c sendMessageName:@"runscript" userInfo:userInfo];
		printf("Attempting to run script %s...\n", argv[2]);
	} else if(strcmp(argv[1], "runtrigger") == 0){
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
		if(argc > 3) userInfo[@"arg"] = [NSString stringWithCString:argv[3] encoding:NSUTF8StringEncoding];
		userInfo[@"name"] = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];
		[c sendMessageName:@"runtrigger" userInfo:userInfo];
	} else {
		printf("Unknown arguments\n");
	}


	return 0;
}
