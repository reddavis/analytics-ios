//
//  SEGOptmizelyIntegration.m
//  Analytics
//
//  Created by Travis Jeffery on 7/16/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGOptimizelyIntegration.h"
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"
#import <Optimizely-iOS-SDK/Optimizely.h>
#import <Optimizely-iOS-SDK/OptimizelyExperimentData.h>

NSString *SEGMixpanelClass = @"Mixpanel";

@interface SEGOptimizelyIntegration ()

@property(nonatomic, assign) BOOL needsToActivateMixpanel;

@end

@implementation SEGOptimizelyIntegration

+ (void)load {
  [SEGAnalytics registerIntegration:self withIdentifier:self.identifier];
}

- (id)init {
  if (self = [super init]) {
    self.name = self.class.identifier;
    self.valid = YES;
    self.initialized = NO;

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(integrationDidStart:)
               name:SEGAnalyticsIntegrationDidStart
             object:nil];
  }
  return self;
}

- (void)start {
  [self activateMixpanel];

  if ([(NSNumber *)[self.settings objectForKey:@"listen"] boolValue]) {
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(experimentDidGetViewed:)
               name:OptimizelyExperimentVisitedNotification
             object:nil];
  }

  [super start];
}

- (void)validate {
  self.valid = YES;
}

- (void)track:(NSString *)event
    properties:(NSDictionary *)properties
       options:(NSDictionary *)options {
  [Optimizely trackEvent:event];
}

#pragma mark - Private

+ (NSString *)identifier {
  return @"Optimizely";
}

- (void)activateMixpanel {
  if (NSClassFromString(SEGMixpanelClass) && self.needsToActivateMixpanel) {
    SEGLog(@"Activating Optimizely's Mixpanel integration.");

    [Optimizely activateMixpanelIntegration];
    self.needsToActivateMixpanel = NO;
  }
}

- (void)integrationDidStart:(NSNotification *)notification {
  SEGAnalyticsIntegration *integration = notification.object;

  if ([integration.name isEqualToString:@"Mixpanel"]) {
    self.needsToActivateMixpanel = YES;

    if (self.initialized) {
      [self activateMixpanel];
    }
  }
}

- (void)experimentDidGetViewed:(NSNotification *)notification {
  NSString *experimentViewed = notification.name;
  NSArray *visitedExperiments = [Optimizely sharedInstance].visitedExperiments;
  for (OptimizelyExperimentData *data in visitedExperiments) {
    if ([data.experimentName isEqualToString:experimentViewed]) {
      [[SEGAnalytics sharedAnalytics] track:@"Experiment Viewed"
                                 properties:@{
                                   @"experimentName" : data.experimentName,
                                   @"variationName" : data.variationName
                                 }];
    }
  }
}

@end
