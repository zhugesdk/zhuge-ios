#import <UIKit/UIKit.h>

@interface UIColor (ZGColor)

+ (UIColor *)zg_applicationPrimaryColor;
+ (UIColor *)zg_lightEffectColor;
+ (UIColor *)zg_extraLightEffectColor;
+ (UIColor *)zg_darkEffectColor;

- (UIColor *)colorWithSaturationComponent:(CGFloat) saturation;

@end
