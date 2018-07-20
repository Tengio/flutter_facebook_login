#import "FacebookLoginPlugin.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

@interface NSError (FlutterError)
@property(readonly, nonatomic) FlutterError *flutterError;
@end

@implementation NSError (FlutterError)
- (FlutterError *)flutterError {
    return [FlutterError errorWithCode:[NSString stringWithFormat:@"Error %d", (int)self.code]
                               message:self.domain
                               details:self.localizedDescription];
}
@end

@implementation FacebookLoginPlugin {
    FBSDKLoginManager *loginManager;
    FlutterResult resultForDelegate;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
                                     methodChannelWithName:@"com.roughike/flutter_facebook_login"
                                     binaryMessenger:[registrar messenger]];
    FacebookLoginPlugin *instance = [[FacebookLoginPlugin alloc] init];
    [registrar addApplicationDelegate:instance];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
    loginManager = [[FBSDKLoginManager alloc] init];
    return self;
}

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:
(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    BOOL handled = [[FBSDKApplicationDelegate sharedInstance]
                    application:application
                    openURL:url
                    sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                    annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    return handled;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    BOOL handled =
    [[FBSDKApplicationDelegate sharedInstance] application:application
                                                   openURL:url
                                         sourceApplication:sourceApplication
                                                annotation:annotation];
    return handled;
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
    if ([@"loginWithReadPermissions" isEqualToString:call.method]) {
        FBSDKLoginBehavior behavior =
        [self loginBehaviorFromString:call.arguments[@"behavior"]];
        NSArray *permissions = call.arguments[@"permissions"];
        
        [self loginWithReadPermissions:behavior
                           permissions:permissions
                                result:result];
    } else if ([@"loginWithPublishPermissions" isEqualToString:call.method]) {
        FBSDKLoginBehavior behavior =
        [self loginBehaviorFromString:call.arguments[@"behavior"]];
        NSArray *permissions = call.arguments[@"permissions"];
        
        [self loginWithPublishPermissions:behavior
                              permissions:permissions
                                   result:result];
    } else if ([@"logOut" isEqualToString:call.method]) {
        [self logOut:result];
    } else if ([@"getCurrentAccessToken" isEqualToString:call.method]) {
        [self getCurrentAccessToken:result];
    } else if ([@"canShareWithFacebook" isEqualToString:call.method]) {
        if([self canShareWithFacebook]) {
            result(@YES);
        } else {
            result(@NO);
        }
    } else if ([@"canShareWithMessenger" isEqualToString:call.method]) {
        if([self canShareWithMessenger]) {
            result(@YES);
        } else {
            result(@NO);
        }
    } else if ([@"shareUrlOnFacebook" isEqualToString:call.method]) {
        [self shareUrl:result urlString:call.arguments[@"url"] isMessenger:NO];
    } else if ([@"shareUrlOnMessenger" isEqualToString:call.method]) {
        [self shareUrl:result urlString:call.arguments[@"url"] isMessenger:YES];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (FBSDKLoginBehavior)loginBehaviorFromString:(NSString *)loginBehaviorStr {
    if ([@[ @"nativeWithFallback", @"nativeOnly" ]
         containsObject:loginBehaviorStr]) {
        return FBSDKLoginBehaviorNative;
    } else if ([@"webOnly" isEqualToString:loginBehaviorStr]) {
        return FBSDKLoginBehaviorBrowser;
    } else if ([@"webViewOnly" isEqualToString:loginBehaviorStr]) {
        return FBSDKLoginBehaviorWeb;
    } else {
        NSString *message = [NSString
                             stringWithFormat:@"Unknown login behavior: %@", loginBehaviorStr];
        
        @throw [NSException exceptionWithName:@"InvalidLoginBehaviorException"
                                       reason:message
                                     userInfo:nil];
    }
}

- (void)loginWithReadPermissions:(FBSDKLoginBehavior)behavior
                     permissions:(NSArray *)permissions
                          result:(FlutterResult)result {
    [loginManager setLoginBehavior:behavior];
    [loginManager
     logInWithReadPermissions:permissions
     fromViewController:nil
     handler:^(FBSDKLoginManagerLoginResult *loginResult,
               NSError *error) {
         [self handleLoginResult:loginResult
                          result:result
                           error:error];
     }];
}

- (void)loginWithPublishPermissions:(FBSDKLoginBehavior)behavior
                        permissions:(NSArray *)permissions
                             result:(FlutterResult)result {
    [loginManager setLoginBehavior:behavior];
    [loginManager
     logInWithPublishPermissions:permissions
     fromViewController:nil
     handler:^(FBSDKLoginManagerLoginResult *loginResult,
               NSError *error) {
         [self handleLoginResult:loginResult
                          result:result
                           error:error];
     }];
}

- (void)logOut:(FlutterResult)result {
    [loginManager logOut];
    result(nil);
}

- (void)shareUrl:(FlutterResult)result
       urlString:(NSString *)urlString
     isMessenger:(Boolean)isMessenger{
    NSURL *url = [NSURL URLWithString:urlString];
    if(url == nil) {
        result([FlutterError errorWithCode:@"error" message:[NSString stringWithFormat:@"Invalid url: %@", urlString] details:nil]);
        return;
    }
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = url;
    if(isMessenger && [self canShareWithMessenger]) {
        [self setFlutterResultForDelegate:result];
        [FBSDKMessageDialog showWithContent:content delegate:self];
    } else if([self canShareWithFacebook]){
        [self setFlutterResultForDelegate:result];
        [FBSDKShareDialog showFromViewController:nil withContent:content delegate:self];
    } else {
        result([FlutterError errorWithCode:@"error" message:@"Requested app is not available for sharing." details:nil]);
    }
}

- (BOOL)canShareWithFacebook{
    return [[[FBSDKShareDialog alloc] init] canShow];
}

- (BOOL)canShareWithMessenger{
    return [[[FBSDKMessageDialog alloc] init] canShow];
}

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results {
        [self handleFlutterResultDelegate:nil];    
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error{
    [self handleFlutterResultDelegate:error];
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer{
    [self handleFlutterResultDelegate:nil];
}

- (void)setFlutterResultForDelegate:(FlutterResult)result{
    if(resultForDelegate != nil) {
        resultForDelegate([FlutterError errorWithCode:@"error" message:@"Previous call didn't return a result." details:@"This could prevent the Future to ever return."]);
    }
    resultForDelegate = result;
}

- (void)handleFlutterResultDelegate:(NSError *)error{
    if(resultForDelegate == nil) {
        return;
    }
    
    if(error != nil) {
        resultForDelegate([FlutterError errorWithCode:@"error" message:@"Sharing returned with an error." details:[error localizedDescription]]);
        
    } else {
        resultForDelegate(nil);
    }
    resultForDelegate = nil;
}



- (void)getCurrentAccessToken:(FlutterResult)result {
    FBSDKAccessToken *currentToken = [FBSDKAccessToken currentAccessToken];
    NSDictionary *mappedToken = [self accessTokenToMap:currentToken];
    
    result(mappedToken);
}

- (void)handleLoginResult:(FBSDKLoginManagerLoginResult *)loginResult
                   result:(FlutterResult)result
                    error:(NSError *)error {
    if (error == nil) {
        if (!loginResult.isCancelled) {
            NSDictionary *mappedToken = [self accessTokenToMap:loginResult.token];
            
            result(@{
                     @"status" : @"loggedIn",
                     @"accessToken" : mappedToken,
                     });
        } else {
            result(@{
                     @"status" : @"cancelledByUser",
                     });
        }
    } else {
        result(@{
                 @"status" : @"error",
                 @"errorMessage" : [error description],
                 });
    }
}

- (id)accessTokenToMap:(FBSDKAccessToken *)accessToken {
    if (accessToken == nil) {
        return [NSNull null];
    }
    
    NSString *userId = [accessToken userID];
    NSArray *permissions = [accessToken.permissions allObjects];
    NSArray *declinedPermissions = [accessToken.declinedPermissions allObjects];
    NSNumber *expires = [NSNumber
                         numberWithLong:accessToken.expirationDate.timeIntervalSince1970 * 1000.0];
    
    return @{
             @"token" : accessToken.tokenString,
             @"userId" : userId,
             @"expires" : expires,
             @"permissions" : permissions,
             @"declinedPermissions" : declinedPermissions,
             };
}
@end
