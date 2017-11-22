//
//  ZhugeCompres.h
//  HelloZhuge
//
//  Created by 郭超 on 2017/11/22.
//  Copyright © 2017年 37degree. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (ZhugeCompres)
// ZLIB

- (NSData *) zgZlibDeflate;

@end
