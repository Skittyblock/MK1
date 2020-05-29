// Util.h

#import "Tweak.h"

void runScriptWithName(NSString *name);
void initContextIfNeeded();
void runAllForTrigger(NSString *trigger);
BOOL triggerHasScripts(NSString *trigger);
void setupHardActions();

void alertError(NSString *msg);
void setupLogger(BOOL alertOnError);
NSString *toStringCheckNull(JSValue *val);

void MK1Log(enum MK1LogType type, NSString *str);
