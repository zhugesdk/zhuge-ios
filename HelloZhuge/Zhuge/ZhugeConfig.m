//
//  ZhugeConfig.m
//  HelloZhuge
//
//  Copyright (c) 2014 37degree. All rights reserved.
//

#import "ZhugeConfig.h"


@implementation ZhugeConfig

- (instancetype)init {
    if (self = [super init]) {
        self.sdkVersion = ZG_SDK_VERSION;
        self.appVersion = ZG_APP_VERSION;
        self.channel = ZG_CHANNEL;

        self.policy = SEND_ON_START;
        self.sendInterval = 10;
        self.sessionInterval = 30;
        self.sendMaxSizePerDay = 1000;
        self.cacheMaxSize = 1000;
        
        self.isLogEnabled = NO;
        self.isCrashReportEnabled = YES;
        self.isOnlineConfigEnabled = YES;
    }
    
    return self;
}

- (void) updateOnlineConfig:(NSString *) configString {
    NSArray *items = [configString componentsSeparatedByString:@":"];
    if ([items count] > 2) {
        NSArray *sendItems = [[items objectAtIndex:2] componentsSeparatedByString:@"|"];
        if ([sendItems count] > 7) {
            self.policy = [[sendItems objectAtIndex:0] intValue];
            self.sessionInterval = [[sendItems objectAtIndex:1] intValue];
            self.sendMaxSizePerDay = [[sendItems objectAtIndex:2] intValue];
            self.cacheMaxSize = [[sendItems objectAtIndex:3] intValue];
            self.sendInterval = [[sendItems objectAtIndex:7] intValue];
        }
    }
}

- (NSString *) description {
    return [NSString stringWithFormat: @"\n{\nsdkVersion=%@,\nappVersion=%@,\nchannel=%@,\npolicy=%lu,\nsendInterval=%lu,\nsessionInterval=%lu,\nsendMaxSizePerDay=%lu,\ncacheMaxSize=%lu,\nisLogEnabled=%lu,\nisCrashReportEnabled=%lu,\nisOnlineConfigEnabled=%lu\n}", _sdkVersion, _appVersion, _channel, (unsigned long)_policy, (unsigned long)_sendInterval, (unsigned long)_sessionInterval, (unsigned long)_sendMaxSizePerDay, (unsigned long)_cacheMaxSize, (unsigned long)_isLogEnabled, (unsigned long)_isCrashReportEnabled, (unsigned long)_isOnlineConfigEnabled];
}

@end
