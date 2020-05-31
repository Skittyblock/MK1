// Util.h

#import "Tweak.h"

void initContextIfNeeded();
void setupHardActions();
void setupLogger(BOOL alertOnError);

void runScriptWithName(NSString *name);
void activateTrigger(NSString *trigger);
BOOL triggerHasScripts(NSString *trigger);

void alertError(NSString *msg);
NSString *toStringCheckNull(JSValue *val);

void MK1Log(enum MK1LogType type, NSString *str);
