// os.m

#import "os.h"
#import <mach/mach.h>
#import <mach/mach_host.h>
#import <sys/utsname.h>
#import <mach-o/arch.h>

@implementation MKOSModule

- (NSString *)arch {
	const NXArchInfo *archInfo = NXGetLocalArchInfo();
	NSString *arch = [NSString stringWithCString:archInfo->name encoding:NSUTF8StringEncoding];
	return arch.lowercaseString;
}

- (NSString *)devNull {
	return @"/dev/null";
}

- (NSString *)endianness {
	union {
		uint32_t i;
		char c[4];
	} bint = {0x01020304};
	
	return bint.c[0] == 1 ? @"BE" : @"LE";
}

- (NSNumber *)freemem {
	mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;

    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);        

    vm_statistics_data_t vm_stat;

    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) return @0;

	// host_info_t info;
	// host_info(host_port, HOST_BASIC_INFO, &info, host_size);

    /* Stats in bytes */ 
    // natural_t mem_used = (vm_stat.active_count +
    //                       vm_stat.inactive_count +
    //                       vm_stat.wire_count) * pagesize;
    natural_t mem_free = vm_stat.free_count * pagesize;
    // natural_t mem_total = mem_used + mem_free;
    // NSLog(@"used: %u free: %u total: %u", mem_used, mem_free, mem_total);

	return [NSNumber numberWithInt:mem_free];
}

- (NSString *)homeDir {
	return [[[NSProcessInfo processInfo] environment] objectForKey:@"HOME"]; // /var/mobile
}

- (NSString *)hostname {
	return [[[NSProcessInfo processInfo] environment] objectForKey:@"HOSTNAME"];
}

- (NSString *)platform {
	return @"darwin";
}

- (NSString *)release:(NSString *)ignore {
	struct utsname systemInfo;
	uname(&systemInfo);
	return [NSString stringWithCString:systemInfo.release encoding:NSUTF8StringEncoding];
}

- (NSString *)tmpdir {
	return @"/tmp";
}

- (NSString *)type {
	struct utsname systemInfo;
	uname(&systemInfo);
	return [NSString stringWithCString:systemInfo.sysname encoding:NSUTF8StringEncoding];
}

- (NSNumber *)totalmem {
	return [NSNumber numberWithLongLong:[[NSProcessInfo processInfo] physicalMemory]];
}

- (NSNumber *)uptime {
	return [NSNumber numberWithInt:(int)[[NSProcessInfo processInfo] systemUptime]];
}

- (NSDictionary *)userInfo:(NSDictionary *)options {
	return @{
		@"uid": [NSNumber numberWithInt:getuid()],
		@"gid": [NSNumber numberWithInt:getgid()],
		@"username": NSUserName(),
		@"homedir": [self homeDir], // TODO: query OS?
		@"shell": [[[NSProcessInfo processInfo] environment] objectForKey:@"SHELL"]
	};
}

- (NSString *)version {
	struct utsname systemInfo;
	uname(&systemInfo);
	return [NSString stringWithCString:systemInfo.version encoding:NSUTF8StringEncoding];
}

@end
