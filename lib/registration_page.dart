import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
              onChanged: (bool? value) {
                setState(() {
                  _acceptTerms = value ?? false;
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
                Navigator.pushNamed(context, '/LoginPage');
              },
              child: Text('آیا قبلاً ثبت نام کرده‌اید؟ ورود'),
            ),
          ],
        ),
      ),
    );
  }

  void _register() {
    if (_acceptTerms) {
      _sendFormDataToServer(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );
    } else {
      // نمایش پیام خطا اگر کاربر قوانین و شرایط را نپذیرفته باشد
      _showErrorDialog('لطفاً قوانین و شرایط را بپذیرید.');
    }
  }

  Future<void> _sendFormDataToServer(
      String username, String email, String password) async {
    String serverUrl = 'http://127.0.0.1:8000/api/register/';

    try {
      var response = await http.post(
        Uri.parse(serverUrl),
        body: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      // لاگ کردن پاسخ سرور برای بررسی محتوای آن
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // نمایش دیالوگ موفقیت و انتقال به صفحه NoteApp
        _showRegistrationSuccessDialog(context);
      } else {
        // نمایش پیام خطا اگر کد وضعیت HTTP نشان دهنده موفقیت نیست
        _showErrorDialog('خطا در ثبت نام. لطفاً دوباره تلاش کنید.');
      }
    } catch (e) {
      // نمایش پیام خطا اگر ارتباط با سرور با مشکل مواجه شود
      _showErrorDialog('خطا در برقراری ارتباط با سرور: $e');
    }
  }

  void _showRegistrationSuccessDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Icon(Icons.check_circle, color: Colors.green, size: 48.0),
          content: Text('ثبت نام با موفقیت انجام شد.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // بستن دیالوگ
              },
              child: Text('باشه'),
            ),
          ],
        );
      },
    );

    // انتقال به صفحه NoteApp پس از بسته شدن دیالوگ
    // Navigator.pushReplacementNamed(context, '/NoteApp');
    Navigator.pushNamed(context, '/LoginPage');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Icon(Icons.error_outline, color: Colors.red, size: 48.0),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // بستن دیالوگ
              },
              child: Text('باشه'),
            ),
          ],
        );
      },
    );
  }
}
