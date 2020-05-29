/**
 * This header is generated by class-dump-z 0.1-11s.
 * class-dump-z is Copyright (C) 2009 by KennyTM~, licensed under GPLv3.
 *
 * Source: /System/Library/PrivateFrameworks/AppSupport.framework/AppSupport
 */

#include <SystemConfiguration/SystemConfiguration.h>
#include <mach/message.h>
#include <CoreFoundation/CoreFoundation.h>

typedef audit_token_t XXStruct_kUSYWB;

/*
typedef struct {
	unsigned _field1[8];
} XXStruct_kUSYWB;
 
 [0] -> audit user ID
 [1] -> effective user ID
 [2] -> effective group ID
 [3] -> real user ID
 [4] -> real group ID
[5] -> process ID
 [6] -> task or sender's audit session ID
 [7] -> task or sender's terminal ID
 
 */

#if __cplusplus
extern "C" {
#endif
	
	CFStringRef CPSystemRootDirectory();	// "/"
	CFStringRef CPMailComposeControllerAutosavePath();	// ~/Library/Mail/OrphanedDraft-com.yourcompany.appName
	bool CPMailComposeControllerHasAutosavedMessage();
	CFStringRef CPCopyBundleIdentifierFromAuditToken(audit_token_t* token, bool* unknown);
	CFStringRef CPSharedResourcesDirectory();	// "/var/mobile", or value of envvar IPHONE_SHARED_RESOURCES_DIRECTORY
	bool CPCanSendMMS();
	CFStringRef CPCopySharedResourcesPreferencesDomainForDomain(CFStringRef domain);	// /var/mobile/Library/Preferences/domain
	CFStringRef CPGetDeviceRegionCode();
	bool CPCanSendMail();

#if __cplusplus
}
#endif