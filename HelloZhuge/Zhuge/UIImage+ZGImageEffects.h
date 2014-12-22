
@interface UIImage (ZGImageEffects)

- (UIImage *)zg_applyLightEffect;
- (UIImage *)zg_applyExtraLightEffect;
- (UIImage *)zg_applyDarkEffect;
- (UIImage *)zg_applyTintEffectWithColor:(UIColor *)tintColor;

- (UIImage *)zg_applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage;

@end
