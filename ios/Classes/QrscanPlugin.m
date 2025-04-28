#import "QrscanPlugin.h"
#import <qrscan_plus/qrscan_plus-Swift.h>

@implementation QrscanPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftQrscanPlugin registerWithRegistrar:registrar];
}
@end
