import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class KeycloakService {
  final FlutterAppAuth _appAuth = FlutterAppAuth();

  // Keycloak Configuration
  final String _clientId = 'flutter-client';
  final String _redirectUrl = 'http://10.0.2.2:5000/';
  final String _issuer = 'http://10.0.2.2:8080/realms/flutter-app';
  final List<String> _scopes = ['openid', 'profile', 'email'];
  Timer? _refreshTimer;

  Future<bool> login(String email, String password) async {
    try {
      final response = await _authenticateWithCredentials(email, password);

      if (response != null && response['access_token'] != null) {
        await _saveTokens(response['access_token'], response['refresh_token'],
            response['expires_in']);
        _startTokenRefreshScheduler();
        print('Access Token: ${response['access_token']}');
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>?> _authenticateWithCredentials(
      String email, String password) async {
    final url = '$_issuer/protocol/openid-connect/token';
    final body = {
      'client_id': _clientId,
      'client_secret': '4UU2nb4SCdXZj7o4dhHYkJCjZTOTGTDN',
      'username': email,
      'password': password,
      'grant_type': 'password',
      'scope': _scopes.join(' '),
    };

    try {
      final response = await http.post(Uri.parse(url), body: body);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to authenticate: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during authentication: $e');
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _refreshTimer?.cancel();
    print('User logged out');
  }

  Future<void> _saveTokens(
      String? accessToken, String? refreshToken, int? expiresIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken ?? '');
    await prefs.setString('refreshToken', refreshToken ?? '');
    await prefs.setInt('expiresIn',
        expiresIn ?? (DateTime.now().millisecondsSinceEpoch + 300 * 1000));
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final tokenExpiry = prefs.getInt('expiresIn');

    if (accessToken != null &&
        tokenExpiry != null &&
        DateTime.now().millisecondsSinceEpoch < tokenExpiry) {
      return accessToken;
    } else {
      return await _refreshToken();
    }
  }

  Future<String?> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');

    if (refreshToken == null) {
      await logout();
      return null;
    }

    try {
      final TokenResponse? result = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUrl,
          refreshToken: refreshToken,
          discoveryUrl: '$_issuer/.well-known/openid-configuration',
          scopes: _scopes,
        ),
      );

      if (result != null) {
        await _saveTokens(result.accessToken, result.refreshToken,
            result.accessTokenExpirationDateTime?.millisecondsSinceEpoch);
        return result.accessToken;
      }
    } catch (e) {
      print('Error refreshing token: $e');
      await logout();
    }
    return null;
  }

  void _startTokenRefreshScheduler() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      final token = await _refreshToken();
      if (token == null) {
        print('Token refresh failed, logging out...');
        await logout();
      }
    });
  }
}
