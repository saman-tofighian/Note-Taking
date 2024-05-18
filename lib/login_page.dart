import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    // آدرس سرور
    String serverUrl = 'http://127.0.0.1:8000/api/token/';

    try {
      // ارسال درخواست POST به سرور برای دریافت توکن
      var response = await http.post(
        Uri.parse(serverUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      // بررسی کد وضعیت درخواست
      if (response.statusCode == 200) {
        // پاسخ را به داده JSON تبدیل کرده و از آن استفاده می‌کنیم
        var data = json.decode(response.body);

        // دریافت توکن از پاسخ سرور
        String token = data['access'];
        print('Token: $token');

        // ذخیره توکن در حافظه محلی
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);

        // انتقال به صفحه دیگر (مانند NotePage)
        Navigator.pushReplacementNamed(context, '/NoteApp');
      } else {
        // نمایش پیام خطا با جزئیات بیشتر
        var errorData = json.decode(response.body);
        _showErrorDialog(context, 'ورود ناموفق بود: ${errorData['detail']}');
      }
    } catch (e) {
      // نمایش پیام خطا
      _showErrorDialog(context, 'مشکلی در ارتباط با سرور پیش آمده است: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('خطا'),
          content: Text(message),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 540.0,
          height: 551.0,
          padding: const EdgeInsets.all(50.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 30.0),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'خوش آمدید',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              TextFormField(
                controller: _usernameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'نام کاربری',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                ),
              ),
              SizedBox(height: 20.0),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'رمز عبور',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24.0),
              TextButton(
                onPressed: () {
                  // فراموشی رمز عبور
                },
                child: const Text(
                  'رمز عبور خود را فراموش کرده‌اید؟ فراموشی رمز عبور',
                  style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30.0),
              SizedBox(
                width: 352.0,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    _login(context); // فراخوانی تابع ورود
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    fixedSize: const Size(352.0, 50.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  child: const Text(
                    'ورود',
                    style: TextStyle(fontSize: 16.0, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
