import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  double? _height, _width;
  String _email = '';
  bool _load = false;

  final GlobalKey<FormState> _key = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _height = MediaQuery.of(context).size.height;
    _width = MediaQuery.of(context).size.width;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: Container(
        height: _height,
        width: _width,
        padding: const EdgeInsets.only(bottom: 5),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              _image(),
              _form(),
              SizedBox(height: _height! / 12),
              _button()
            ],
          ),
        ),
      ),
    );
  }

  Widget _image() {
    return Container(
      margin: EdgeInsets.only(top: _height! / 15.0),
      height: 100.0,
      width: 100.0,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: Image.asset('assets/images/login.png'),
    );
  }

  Widget _form() {
    return Container(
      margin: EdgeInsets.only(
          left: _width! / 12.0, right: _width! / 12.0, top: _height! / 15.0),
      child: Form(
        key: _key,
        child: Column(
          children: <Widget>[
            _emailBox(),
          ],
        ),
      ),
    );
  }

  Widget _emailBox() {
    return Material(
      borderRadius: BorderRadius.circular(30.0),
      elevation: 10,
      child: TextFormField(
        onSaved: (input) {
          if (input != null) {
            _email = input;
          }
        },
        keyboardType: TextInputType.emailAddress,
        cursorColor: const Color(0xFF667eea),
        obscureText: false,
        decoration: InputDecoration(
          prefixIcon:
              const Icon(Icons.email, color: Color(0xFF667eea), size: 20),
          hintText: "Email ID",
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _button() {
    return !_load
        ? ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0)),
              padding: const EdgeInsets.all(0.0),
            ),
            onPressed: () {
              RegExp regExp = RegExp(
                  r'^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$');
              final formstate = _key.currentState;
              if (!formstate!.validate()) return;
              formstate.save();
              if (_email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email Cannot be empty')));
              } else if (!regExp.hasMatch(_email)) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a Valid Email')));
              } else {
                setState(() {
                  _load = true;
                });
                _resetPassword();

                setState(() {
                  _email = '';
                });
              }
            },
            child: Container(
              alignment: Alignment.center,
              width: _width! / 2,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(25.0)),
                gradient: const LinearGradient(
                  colors: <Color>[
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(12.0),
              child: const Text('Reset Password',
                  style: TextStyle(fontSize: 15, color: Colors.white)),
            ),
          )
        : const Center(
            child: CircularProgressIndicator(),
          );
  }

  Future<void> _resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email);
      if (mounted) {
        setState(() {
          _load = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Reset password link sent to registered email')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _load = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('An error occurred. Please try again later')));
      }
    }
  }
}
