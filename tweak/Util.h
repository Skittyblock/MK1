// Util.h

#import "Tweak.h"

enum MK1LogType {
    MK1LogInfo, MK1LogWarn, MK1LogDebug, MK1LogError
};

void initContextIfNeeded();
void setupHardActions();
void setupLogger(BOOL alertOnError);

JSValue *runScriptWithName(NSString *name);
void activateTrigger(NSString *trigger);
BOOL triggerHasScripts(NSString *trigger);

void alertError(NSString *msg);
NSString *toStringCheckNull(JSValue *val);

void MK1Log(enum MK1LogType type, NSString *str);
