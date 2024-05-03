import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _acceptTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ثبت نام'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'نام و نام خانوادگی'),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'ایمیل'),
            ),
            SizedBox(height: 16.0),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'رمز عبور'),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            CheckboxListTile(
              title: Text('تمام قوانین و شرایط را می‌پذیرم'),
              value: _acceptTerms,
              onChanged: (value) {
                setState(() {
                  _acceptTerms = value!;
                });
              },
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _acceptTerms ? _register : null,
              child: Text('ثبت نام'),
            ),
            SizedBox(height: 16.0),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('آیا قبلاً ثبت نام کرده‌اید؟ ورود'),
            ),
          ],
        ),
      ),
    );
  }

  void _register() {
    // گرفتن اطلاعات فرم از کنترلر‌ها
    String username = _usernameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;

    // ارسال اطلاعات به سرور
    _sendFormDataToServer(username, email, password);
  }

  Future<void> _sendFormDataToServer(
      String username, String email, String password) async {
    // URL سرور مقصد
    String serverUrl = 'http://127.0.0.1:8000/api/register';

    try {
      // ارسال درخواست POST به سرور
      var response = await http.post(
        Uri.parse(serverUrl),
        body: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      // بررسی وضعیت پاسخ از سرور
      if (response.statusCode == 200) {
        // پاسخ موفق
        print('Registration successful.');
      } else {
        // پاسخ ناموفق
        print(
            'Failed to register. Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      // خطا در ارسال درخواست
      print('Error sending registration request: $e');
    }
  }
}
