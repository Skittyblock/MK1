/**
 * This header is generated by class-dump-z 0.1-11s.
 * class-dump-z is Copyright (C) 2009 by KennyTM~, licensed under GPLv3.
 *
 * Source: /System/Library/PrivateFrameworks/AppSupport.framework/AppSupport
 */

#import "AppSupport-Structs.h"
#import <Foundation/NSObject.h>

@class NSLock, NSMutableDictionary, NSOperationQueue, NSString, NSDictionary, NSError;

@interface CPDistributedMessagingCenter : NSObject {
	NSString* _centerName;
	NSLock* _lock;
	unsigned _sendPort;
	CFMachPortRef _invalidationPort;
	NSOperationQueue* _asyncQueue;
	CFRunLoopSourceRef _serverSource;
	NSString* _requiredEntitlement;
	NSMutableDictionary* _callouts;
}
+(CPDistributedMessagingCenter*)centerNamed:(NSString*)serverName;
-(id)_initWithServerName:(NSString*)serverName;
// inherited: -(void)dealloc;
-(NSString*)name;
-(unsigned)_sendPort;
-(void)_serverPortInvalidated;
-(BOOL)sendMessageName:(NSString*)name userInfo:(NSDictionary*)info;
-(NSDictionary*)sendMessageAndReceiveReplyName:(NSString*)name userInfo:(NSDictionary*)info;
-(NSDictionary*)sendMessageAndReceiveReplyName:(NSString*)name userInfo:(NSDictionary*)info error:(NSError**)error;
-(void)sendMessageAndReceiveReplyName:(NSString*)name userInfo:(NSDictionary*)info toTarget:(id)target selector:(SEL)selector context:(void*)context;
-(BOOL)_sendMessage:(id)message userInfo:(id)info receiveReply:(id*)reply error:(id*)error toTarget:(id)target selector:(SEL)selector context:(void*)context;
-(BOOL)_sendMessage:(id)message userInfoData:(id)data oolKey:(id)key oolData:(id)data4 receiveReply:(id*)reply error:(id*)error;
-(void)runServerOnCurrentThread;
-(void)runServerOnCurrentThreadProtectedByEntitlement:(id)entitlement;
-(void)stopServer;
-(void)registerForMessageName:(NSString*)messageName target:(id)target selector:(SEL)selector;
-(void)unregisterForMessageName:(NSString*)messageName;
-(void)_dispatchMessageNamed:(id)named userInfo:(id)info reply:(id*)reply auditToken:(XXStruct_kUSYWB*)token;
-(BOOL)_isTaskEntitled:(XXStruct_kUSYWB*)entitled;
-(id)_requiredEntitlement;
@end
