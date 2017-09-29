#import "RNAdMobRewarded.h"

#if __has_include(<React/RCTUtils.h>)
#import <React/RCTUtils.h>
#else
#import "RCTUtils.h"
#endif

@implementation RNAdMobRewarded {
    NSString *_adUnitID;
    NSArray *_testDevices;
    RCTPromiseResolveBlock _requestAdResolve;
    RCTPromiseRejectBlock _requestAdReject;
    BOOL hasListeners;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents
{
    return @[
             @"rewarded",
             @"adLoaded",
             @"adFailedToLoad",
             @"adOpened",
             @"videoStarted",
             @"adClosed",
             @"adLeftApplication"];
}

#pragma mark exported methods

RCT_EXPORT_METHOD(setAdUnitID:(NSString *)adUnitID)
{
    _adUnitID = adUnitID;
}

RCT_EXPORT_METHOD(setTestDevices:(NSArray *)testDevices)
{
    _testDevices = testDevices;
}

RCT_EXPORT_METHOD(requestAd:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    _requestAdResolve = resolve;
    _requestAdReject = reject;
    
    [GADRewardBasedVideoAd sharedInstance].delegate = self;
    GADRequest *request = [GADRequest request];
    request.testDevices = _testDevices;
    [[GADRewardBasedVideoAd sharedInstance] loadRequest:request
                                           withAdUnitID:_adUnitID];
}

RCT_EXPORT_METHOD(showAd:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if ([[GADRewardBasedVideoAd sharedInstance] isReady]) {
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        UIViewController *rootViewController = [keyWindow rootViewController];
        [[GADRewardBasedVideoAd sharedInstance] presentFromRootViewController:rootViewController];
        resolve(nil);
    }
    else {
        reject(@"E_AD_NOT_READY", @"Ad is not ready.", nil);
    }
}

RCT_EXPORT_METHOD(isReady:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNumber numberWithBool:[[GADRewardBasedVideoAd sharedInstance] isReady]]]);
}

- (NSDictionary<NSString *,id> *)constantsToExport
{
    return @{
             @"simulatorId": kGADSimulatorID
             };
}

- (void)startObserving
{
    hasListeners = YES;
}

- (void)stopObserving
{
    hasListeners = NO;
}

#pragma mark GADRewardBasedVideoAdDelegate

- (void)rewardBasedVideoAd:(__unused GADRewardBasedVideoAd *)rewardBasedVideoAd
   didRewardUserWithReward:(GADAdReward *)reward {
    if (hasListeners) {
        [self sendEventWithName:@"rewarded" body:@{@"type": reward.type, @"amount": reward.amount}];
    }
}

- (void)rewardBasedVideoAdDidReceiveAd:(__unused GADRewardBasedVideoAd *)rewardBasedVideoAd {
    if (hasListeners) {
        [self sendEventWithName:@"adLoaded" body:nil];
    }
    _requestAdResolve(nil);
}

- (void)rewardBasedVideoAdDidOpen:(__unused GADRewardBasedVideoAd *)rewardBasedVideoAd {
    if (hasListeners) {
        [self sendEventWithName:@"adOpened" body:nil];
    }
}

- (void)rewardBasedVideoAdDidStartPlaying:(__unused GADRewardBasedVideoAd *)rewardBasedVideoAd {
    if (hasListeners) {
        [self sendEventWithName:@"videoStarted" body:nil];
    }
}

- (void)rewardBasedVideoAdDidClose:(__unused GADRewardBasedVideoAd *)rewardBasedVideoAd {
    if (hasListeners) {
        [self sendEventWithName:@"adClosed" body:nil];
    }
}

- (void)rewardBasedVideoAdWillLeaveApplication:(__unused GADRewardBasedVideoAd *)rewardBasedVideoAd {
    if (hasListeners) {
        [self sendEventWithName:@"adLeftApplication" body:nil];
    }
}

- (void)rewardBasedVideoAd:(__unused GADRewardBasedVideoAd *)rewardBasedVideoAd
    didFailToLoadWithError:(NSError *)error {
    if (hasListeners) {
        NSDictionary *jsError = RCTJSErrorFromCodeMessageAndNSError(@"E_AD_FAILED_TO_LOAD", error.localizedDescription, error);
        [self sendEventWithName:@"adFailedToLoad" body:jsError];
    }
    _requestAdReject(@"E_AD_FAILED_TO_LOAD", error.localizedDescription, error);
}

@end
