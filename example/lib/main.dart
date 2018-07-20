import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final FacebookLogin facebookSignIn = new FacebookLogin();

  String _message = 'Log in/out by pressing the buttons below.';
  bool canShareOnFacebook = false;
  bool canShareOnMessenger = false;

  @override
  initState() {
    FacebookLogin.canShareWithFacebook().then((bool canShare) {
      if (mounted) setState(() => canShareOnFacebook = canShare);
    });
    FacebookLogin.canShareWithMessenger().then((bool canShare) {
      if (mounted) setState(() => canShareOnMessenger = canShare);
    });
    super.initState();
  }

  Future<Null> _login() async {
    final FacebookLoginResult result = await facebookSignIn.logInWithReadPermissions(['email']);

    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        final FacebookAccessToken accessToken = result.accessToken;
        _showMessage('''
         Logged in!
         
         Token: ${accessToken.token}
         User id: ${accessToken.userId}
         Expires: ${accessToken.expires}
         Permissions: ${accessToken.permissions}
         Declined permissions: ${accessToken.declinedPermissions}
         ''');
        break;
      case FacebookLoginStatus.cancelledByUser:
        _showMessage('Login cancelled by the user.');
        break;
      case FacebookLoginStatus.error:
        _showMessage('Something went wrong with the login process.\n'
            'Here\'s the error Facebook gave us: ${result.errorMessage}');
        break;
    }
  }

  Future<Null> _logOut() async {
    await facebookSignIn.logOut();
    _showMessage('Logged out.');
  }

  void _showMessage(String message) {
    setState(() {
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Plugin example app'),
        ),
        body: new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Text(_message),
              const Padding(padding: const EdgeInsets.only(top: 12.0)),
              new RaisedButton(
                onPressed: _login,
                child: new Text('Log in'),
              ),
              const Padding(padding: const EdgeInsets.only(top: 12.0)),
              new RaisedButton(
                onPressed: _logOut,
                child: new Text('Logout'),
              ),
              const Padding(padding: const EdgeInsets.only(top: 12.0)),
              new RaisedButton(
                onPressed: !canShareOnFacebook
                    ? null
                    : () async {
                        await FacebookLogin.shareUrlOnFacebook("http://developers.facebook.com/");
                      },
                child: new Text('Share a link on Facebook'),
              ),
              const Padding(padding: const EdgeInsets.only(top: 12.0)),
              new RaisedButton(
                onPressed: !canShareOnMessenger
                    ? null
                    : () async {
                        await FacebookLogin.shareUrlOnMessenger("http://developers.facebook.com/a");
                      },
                child: new Text('Share a link on Messenger'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
