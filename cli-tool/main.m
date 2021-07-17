// MK1 CLI, by Skitty
// Run MK1-powered JS code from the command line

#include <stdio.h>
#import <Foundation/Foundation.h>
#import "../Headers/AppSupport/CPDistributedMessagingCenter.h"
#import <rocketbootstrap/rocketbootstrap.h>
#import <JavaScriptCore/JavaScriptCore.h>

static CPDistributedMessagingCenter *c = nil;

char *read_line(void) {
	char *line = NULL;
	size_t bufsize = 0;

	if (getline(&line, &bufsize, stdin) == -1){
		if (feof(stdin)) {
			exit(EXIT_SUCCESS);
		} else  {
			perror("readline");
			exit(EXIT_FAILURE);
		}
	}

	return line;
}

int execute(char *line) {
	// Handle commands
	if (strcmp(line, ".help\n") == 0) {
		printf(".exit     Exit the REPL\n");
		// printf(".trigger  Trigger the provided trigger\n");
		return 1;
	// } else if (strcmp(line, ".trigger\n") == 0) {
	// 	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	// 	userInfo[@"name"] = [NSString stringWithUTF8String:"TRIGGER"];
	// 	[c sendMessageName:@"runTrigger" userInfo:userInfo];
	// 	printf("Triggered %s\n", argv[2]);
	}
	else if (strcmp(line, ".exit\n") == 0) return 0;

	// Execute code
	NSDictionary *ret = [c sendMessageAndReceiveReplyName:@"runCode" userInfo:@{@"code": [NSString stringWithUTF8String:line]}];
	NSString *result = ret[@"result"];

	// TODO: syntax highlighting (just gray for now)
	if (result && ![result isEqualToString:@"\n"] && ![result isEqualToString:@""]) printf("\e[90m%s\e[0m", [result UTF8String]);

	printf("\n");

	return 1;
}

int main(int argc, char *argv[], char *envp[]) {
	c = [CPDistributedMessagingCenter centerNamed:@"xyz.skitty.mk1"];
	rocketbootstrap_distributedmessagingcenter_apply(c);

	printf("Welcome to MK1 v0.2.\n");
	
	char *line;
	int status;

	do {
		printf("> ");
		line = read_line();
		status = execute(line);
	} while (status);

	return 0;
}
