// Util.h

#import "Tweak.h"

enum MK1LogType {
    MK1LogGeneral, MK1LogInfo, MK1LogWarn, MK1LogError, MK1LogDebug
};

void initContextIfNeeded();
void setupHardActions();

JSValue *runScriptWithName(NSString *name);
JSValue *evaluateCode(NSString *code);
void activateTrigger(NSString *trigger);
BOOL triggerHasScripts(NSString *trigger);

void alertError(NSString *msg);
NSString *toStringCheckNull(JSValue *val);

void MK1Log(enum MK1LogType type, NSString *str);
