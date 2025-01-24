import 'package:flutter/material.dart';

import 'keycloak_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final KeycloakService _keycloakService = KeycloakService();
  String _status = 'Not logged in';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;
    bool isLoggedIn = await _keycloakService.login(email, password);
    setState(() {
      _status = isLoggedIn ? 'Logged in successfully' : 'Login failed';
    });
  }

  Future<void> _logout() async {
    await _keycloakService.logout();
    setState(() {
      _status = 'Not logged in';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Keycloak Auth')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: Text('Login')),
            ElevatedButton(onPressed: _logout, child: Text('Logout')),
          ],
        ),
      ),
    );
  }
}
