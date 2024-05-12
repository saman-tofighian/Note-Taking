import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';

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
    String username = _usernameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;

    _sendFormDataToServer(username, email, password);
  }

  Future<void> _sendFormDataToServer(
      String username, String email, String password) async {
    String serverUrl = 'http://127.0.0.1:8000/api/register';

    try {
      var response = await http.post(
        Uri.parse(serverUrl),
        body: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        _showRegistrationSuccessDialog(context);
      } else {
        print(
            'ثبت نام ناموفق بود. سرور با کد وضعیت ${response.statusCode} پاسخ داده است.');
      }
    } catch (e) {
      print('خطا در ارسال درخواست ثبت نام: $e');
    }
  }

  void _showRegistrationSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Icon(Icons.check_circle, color: Colors.green, size: 48.0),
          content: Text('ثبت نام با موفقیت انجام شد.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('باشه'),
            ),
          ],
        );
      },
    );
  }
}
