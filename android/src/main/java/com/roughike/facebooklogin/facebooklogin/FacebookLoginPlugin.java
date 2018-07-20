package com.roughike.facebooklogin.facebooklogin;

import android.net.Uri;

import com.facebook.AccessToken;
import com.facebook.CallbackManager;
import com.facebook.FacebookCallback;
import com.facebook.FacebookException;
import com.facebook.login.LoginBehavior;
import com.facebook.login.LoginManager;
import com.facebook.share.Sharer;
import com.facebook.share.model.ShareLinkContent;
import com.facebook.share.widget.MessageDialog;
import com.facebook.share.widget.ShareDialog;

import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

public class FacebookLoginPlugin implements MethodCallHandler {
    private static final String CHANNEL_NAME = "com.roughike/flutter_facebook_login";

    private static final String ERROR_UNKNOWN_LOGIN_BEHAVIOR = "unknown_login_behavior";

    private static final String METHOD_LOG_IN_WITH_READ_PERMISSIONS = "loginWithReadPermissions";
    private static final String METHOD_LOG_IN_WITH_PUBLISH_PERMISSIONS = "loginWithPublishPermissions";
    private static final String METHOD_LOG_OUT = "logOut";
    private static final String METHOD_GET_CURRENT_ACCESS_TOKEN = "getCurrentAccessToken";
    private static final String METHOD_CAN_SHARE_WITH_FACEBOOK = "canShareWithFacebook";
    private static final String METHOD_CAN_SHARE_WITH_MESSENGER = "canShareWithMessenger";
    private static final String METHOD_SHARE_URL_ON_FACEBOOK = "shareUrlOnFacebook";
    private static final String METHOD_SHARE_URL_ON_MESSENGER = "shareUrlOnMessenger";

    private static final String ARG_LOGIN_BEHAVIOR = "behavior";
    private static final String ARG_PERMISSIONS = "permissions";
    private static final String ARG_SHARE_URL = "url";

    private static final String LOGIN_BEHAVIOR_NATIVE_WITH_FALLBACK = "nativeWithFallback";
    private static final String LOGIN_BEHAVIOR_NATIVE_ONLY = "nativeOnly";
    private static final String LOGIN_BEHAVIOR_WEB_ONLY = "webOnly";
    private static final String LOGIN_BEHAVIOR_WEB_VIEW_ONLY = "webViewOnly";

    private final FacebookSignInDelegate delegate;

    private FacebookLoginPlugin(Registrar registrar) {
        delegate = new FacebookSignInDelegate(registrar);
    }

    public static void registerWith(Registrar registrar) {
        final FacebookLoginPlugin plugin = new FacebookLoginPlugin(registrar);
        final MethodChannel channel = new MethodChannel(registrar.messenger(), CHANNEL_NAME);
        channel.setMethodCallHandler(plugin);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        String loginBehaviorStr;
        LoginBehavior loginBehavior;

        switch (call.method) {
            case METHOD_LOG_IN_WITH_READ_PERMISSIONS:
                loginBehaviorStr = call.argument(ARG_LOGIN_BEHAVIOR);
                loginBehavior = loginBehaviorFromString(loginBehaviorStr, result);
                List<String> readPermissions = call.argument(ARG_PERMISSIONS);

                delegate.logInWithReadPermissions(loginBehavior, readPermissions, result);
                break;
            case METHOD_LOG_IN_WITH_PUBLISH_PERMISSIONS:
                loginBehaviorStr = call.argument(ARG_LOGIN_BEHAVIOR);
                loginBehavior = loginBehaviorFromString(loginBehaviorStr, result);
                List<String> publishPermissions = call.argument(ARG_PERMISSIONS);

                delegate.logInWithPublishPermissions(loginBehavior, publishPermissions, result);
                break;
            case METHOD_LOG_OUT:
                delegate.logOut(result);
                break;
            case METHOD_GET_CURRENT_ACCESS_TOKEN:
                delegate.getCurrentAccessToken(result);
                break;
            case METHOD_CAN_SHARE_WITH_FACEBOOK:
                result.success(delegate.canShareWithFacebook());
                break;
            case METHOD_CAN_SHARE_WITH_MESSENGER:
                result.success(delegate.canShareWithMessenger());
                break;
            case METHOD_SHARE_URL_ON_FACEBOOK:
                delegate.shareUrl(result, call.argument(ARG_SHARE_URL).toString(), false);
                break;
            case METHOD_SHARE_URL_ON_MESSENGER:
                delegate.shareUrl(result, call.argument(ARG_SHARE_URL).toString(), true);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private LoginBehavior loginBehaviorFromString(String loginBehavior, Result result) {
        switch (loginBehavior) {
            case LOGIN_BEHAVIOR_NATIVE_WITH_FALLBACK:
                return LoginBehavior.NATIVE_WITH_FALLBACK;
            case LOGIN_BEHAVIOR_NATIVE_ONLY:
                return LoginBehavior.NATIVE_ONLY;
            case LOGIN_BEHAVIOR_WEB_ONLY:
                return LoginBehavior.WEB_ONLY;
            case LOGIN_BEHAVIOR_WEB_VIEW_ONLY:
                return LoginBehavior.WEB_VIEW_ONLY;
            default:
                result.error(
                        ERROR_UNKNOWN_LOGIN_BEHAVIOR,
                        "setLoginBehavior called with unknown login behavior: "
                                + loginBehavior,
                        null
                );
                return null;
        }
    }

    public static final class FacebookSignInDelegate {
        private final Registrar registrar;
        private final CallbackManager callbackManager;
        private final LoginManager loginManager;
        private final FacebookLoginResultDelegate resultDelegate;
        private final ShareDialog shareDialog;
        private final MessageDialog messageDialog;

        public FacebookSignInDelegate(Registrar registrar) {
            this.registrar = registrar;
            this.callbackManager = CallbackManager.Factory.create();
            this.loginManager = LoginManager.getInstance();
            this.resultDelegate = new FacebookLoginResultDelegate(callbackManager);
            this.shareDialog = new ShareDialog(registrar.activity());
            this.messageDialog = new MessageDialog(registrar.activity());

            loginManager.registerCallback(callbackManager, resultDelegate);
            registrar.addActivityResultListener(resultDelegate);
        }

        public void logInWithReadPermissions(
                LoginBehavior loginBehavior, List<String> permissions, Result result) {
            resultDelegate.setPendingResult(METHOD_LOG_IN_WITH_READ_PERMISSIONS, result);

            loginManager.setLoginBehavior(loginBehavior);
            loginManager.logInWithReadPermissions(registrar.activity(), permissions);
        }

        public void logInWithPublishPermissions(
                LoginBehavior loginBehavior, List<String> permissions, Result result) {
            resultDelegate.setPendingResult(METHOD_LOG_IN_WITH_PUBLISH_PERMISSIONS, result);

            loginManager.setLoginBehavior(loginBehavior);
            loginManager.logInWithPublishPermissions(registrar.activity(), permissions);
        }

        public void logOut(Result result) {
            loginManager.logOut();
            result.success(null);
        }

        public void shareUrl(final Result result, String urlString, boolean isMessenger) {
            Uri url;
            try {
                url = Uri.parse(urlString);
            } catch (NullPointerException e) {
                result.error("shareError", "Invalid url: " + urlString, null);
                return;
            }

            ShareLinkContent content = new ShareLinkContent.Builder()
                    .setContentUrl(url)
                    .build();

            FacebookCallback<Sharer.Result> shareCallback = new FacebookCallback<Sharer.Result>() {
                @Override
                public void onSuccess(Sharer.Result sharerResult) {
                    result.success(null);
                }

                @Override
                public void onCancel() {
                    result.success(null);
                }

                @Override
                public void onError(FacebookException error) {
                    result.error("shareError", error.getMessage(), null);
                }
            };

            if (isMessenger && canShareWithMessenger()) {
                messageDialog.registerCallback(callbackManager, shareCallback);
                messageDialog.show(content);
            } else if (canShareWithFacebook()) {
                shareDialog.registerCallback(callbackManager, shareCallback);
                shareDialog.show(content);
            } else {
                result.error("shareError", "Requested app is not available for sharing.", null);
            }
        }

        public boolean canShareWithFacebook() {
            return ShareDialog.canShow(ShareLinkContent.class);
        }

        public boolean canShareWithMessenger() {
            return MessageDialog.canShow(ShareLinkContent.class);
        }

        public void getCurrentAccessToken(Result result) {
            AccessToken accessToken = AccessToken.getCurrentAccessToken();
            Map<String, Object> tokenMap = FacebookLoginResults.accessToken(accessToken);

            result.success(tokenMap);
        }
    }
}
