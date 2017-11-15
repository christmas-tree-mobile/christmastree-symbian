#import <GoogleMobileAds/GADMobileAds.h>
#import <GoogleMobileAds/GADRequest.h>
#import <GoogleMobileAds/GADBannerView.h>
#import <GoogleMobileAds/GADBannerViewDelegate.h>

#include <QtCore/QDebug>

#include "admobhelper.h"

const QString AdMobHelper::ADMOB_APP_ID            ("ca-app-pub-2455088855015693~5306005769");
const QString AdMobHelper::ADMOB_BANNERVIEW_UNIT_ID("ca-app-pub-3940256099942544/2934735716");
const QString AdMobHelper::ADMOB_TEST_DEVICE_ID    ("ac878e09bd5bd55f0b72b20a8fca6ffa");

AdMobHelper *AdMobHelper::Instance = NULL;

@interface BannerViewDelegate : NSObject<GADBannerViewDelegate>

- (id)init;
- (void)dealloc;
- (void)loadAd;

@property (nonatomic, retain) GADBannerView *BannerView;

@end

@implementation BannerViewDelegate

@synthesize BannerView;

- (id)init
{
    self = [super init];

    if (self) {
        UIViewController * __block root_view_controller = nil;

        [[[UIApplication sharedApplication] windows] enumerateObjectsUsingBlock:^(UIWindow * _Nonnull window, NSUInteger, BOOL * _Nonnull stop) {
            root_view_controller = [window rootViewController];

            *stop = (root_view_controller != nil);
        }];

        self.BannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];

        self.BannerView.adUnitID                                  = AdMobHelper::ADMOB_BANNERVIEW_UNIT_ID.toNSString();
        self.BannerView.rootViewController                        = root_view_controller;
        self.BannerView.translatesAutoresizingMaskIntoConstraints = NO;
        self.BannerView.delegate                                  = self;

        [root_view_controller.view addSubview:self.BannerView];
        [root_view_controller.view addConstraints:@[
            [NSLayoutConstraint constraintWithItem:self.BannerView
                                attribute:NSLayoutAttributeTop
                                relatedBy:NSLayoutRelationEqual
                                toItem:root_view_controller.topLayoutGuide
                                attribute:NSLayoutAttributeBottom
                                multiplier:1
                                constant:0],
            [NSLayoutConstraint constraintWithItem:self.BannerView
                                attribute:NSLayoutAttributeCenterX
                                relatedBy:NSLayoutRelationEqual
                                toItem:root_view_controller.view
                                attribute:NSLayoutAttributeCenterX
                                multiplier:1
                                constant:0]
        ]];
    }

    return self;
}

- (void)dealloc
{
    [BannerView removeFromSuperview];
    [BannerView release];

    [super dealloc];
}

- (void)loadAd
{
    GADRequest *request = [GADRequest request];

    if (AdMobHelper::ADMOB_TEST_DEVICE_ID != "") {
        request.testDevices = @[ AdMobHelper::ADMOB_TEST_DEVICE_ID.toNSString() ];
    }

    [self.BannerView loadRequest:request];
}

- (void)adViewDidReceiveAd:(GADBannerView *)adView
{
    Q_UNUSED(adView)

    AdMobHelper::setBannerViewHeight(BannerView.bounds.size.height);
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView
{
    Q_UNUSED(adView)
}

- (void)adViewWillDismissScreen:(GADBannerView *)adView
{
    Q_UNUSED(adView)
}

- (void)adViewWillLeaveApplication:(GADBannerView *)adView
{
    Q_UNUSED(adView)
}

- (void)adView:(GADBannerView *)adView didFailToReceiveAdWithError:(GADRequestError *)error
{
    Q_UNUSED(adView)

    qWarning() << QString::fromNSString([error localizedDescription]);

    [self performSelector:@selector(loadAd) withObject:nil afterDelay:10.0];
}

@end

AdMobHelper::AdMobHelper(QObject *parent) : QObject(parent)
{
    Initialized                = false;
    InterstitialActive         = false;
    BannerViewHeight           = 0;
    Instance                   = this;
    BannerViewDelegateInstance = NULL;
}

AdMobHelper::~AdMobHelper()
{
    if (Initialized) {
        [BannerViewDelegateInstance release];
    }
}

bool AdMobHelper::interstitialReady() const
{
    if (Initialized) {
        return false;
        //return [[GADRewardBasedVideoAd sharedInstance] isReady];
    } else {
        return false;
    }
}

bool AdMobHelper::interstitialActive() const
{
    return InterstitialActive;
}

int AdMobHelper::bannerViewHeight() const
{
    return BannerViewHeight;
}

void AdMobHelper::initialize()
{
    if (!Initialized) {
        [GADMobileAds configureWithApplicationID:ADMOB_APP_ID.toNSString()];

        Initialized = true;
    }
}

void AdMobHelper::showBannerView()
{
    if (Initialized) {
        if (BannerViewDelegateInstance != NULL && BannerViewDelegateInstance != nil) {
            [BannerViewDelegateInstance release];

            BannerViewHeight = 0;

            emit bannerViewHeightChanged(BannerViewHeight);

            BannerViewDelegateInstance = nil;
        }

        BannerViewDelegateInstance = [[BannerViewDelegate alloc] init];

        [BannerViewDelegateInstance loadAd];
    }
}

void AdMobHelper::hideBannerView()
{
    if (Initialized) {
        if (BannerViewDelegateInstance != NULL && BannerViewDelegateInstance != nil) {
            [BannerViewDelegateInstance release];

            BannerViewHeight = 0;

            emit bannerViewHeightChanged(BannerViewHeight);

            BannerViewDelegateInstance = nil;
        }
    }
}

void AdMobHelper::showInterstitial()
{
    if (Initialized) {
    }
}

void AdMobHelper::setInterstitialActive(const bool &active)
{
    Instance->InterstitialActive = active;

    emit Instance->interstitialActiveChanged(Instance->InterstitialActive);
}

void AdMobHelper::setBannerViewHeight(const int &height)
{
    Instance->BannerViewHeight = height;

    emit Instance->bannerViewHeightChanged(Instance->BannerViewHeight);
}