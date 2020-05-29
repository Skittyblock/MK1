@class MKScript;
@interface MKScriptsViewController : UITableViewController
@property (strong, nonatomic) NSMutableOrderedSet<MKScript *> *scripts;
@property (strong, nonatomic) NSMutableDictionary *scriptsDict;

-(void)refreshScripts;
@end