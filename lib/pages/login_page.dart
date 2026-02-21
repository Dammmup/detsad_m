import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  double? _height, _width;
  String _email = '', _password = '';
  final GlobalKey<FormState> _key = GlobalKey();
  bool _showPassword = true, _load = false;

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
        title: const Text('Attendance'),
      ),
      body: Container(
        height: _height,
        width: _width,
        padding: const EdgeInsets.only(bottom: 5),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              _image(),
              _welcomeText(),
              _loginText(),
              _form(),
              _forgetPassText(),
              SizedBox(height: _height! / 12),
              _button(),
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

  Widget _welcomeText() {
    return Container(
      margin: EdgeInsets.only(left: _width! / 20, top: _height! / 100),
      child: const Row(
        children: <Widget>[
          Text(
            "Welcome",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginText() {
    return Container(
      margin: EdgeInsets.only(left: _width! / 15.0),
      child: const Row(
        children: <Widget>[
          Text(
            "Sign in to your account",
            style: TextStyle(
              fontWeight: FontWeight.w200,
              fontSize: 17,
            ),
          ),
        ],
      ),
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
            SizedBox(height: _height! / 40.0),
            _passwordBox(),
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
        onSaved: (input) => _email = input!,
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

  Widget _passwordBox() {
    return Material(
      borderRadius: BorderRadius.circular(30.0),
      elevation: 10,
      child: TextFormField(
        onSaved: (input) => _password = input!,
        keyboardType: TextInputType.visiblePassword,
        cursorColor: const Color(0xFF667eea),
        obscureText: _showPassword,
        decoration: InputDecoration(
          prefixIcon:
              const Icon(Icons.lock, color: Color(0xFF667eea), size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.remove_red_eye,
              color: _showPassword ? Colors.grey : const Color(0xFF667eea),
            ),
            onPressed: () {
              setState(() => _showPassword = !_showPassword);
            },
          ),
          hintText: "Password",
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _forgetPassText() {
    return Container(
      margin: EdgeInsets.only(top: _height! / 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            "Forgot your password?",
            style: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
          ),
          const SizedBox(
            width: 5,
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('forgotpassword');
            },
            child: const Text(
              "Recover",
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFF667eea)),
            ),
          )
        ],
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
              formstate!.save();
              if (_email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email Cannot be empty')));
              } else if (_password.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Password needs to be atleast six characters')));
              } else if (!regExp.hasMatch(_email)) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a Valid Email')));
              } else {
                setState(() {
                  _load = true;
                });
                _signIn();
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
              child: const Text('SIGN IN',
                  style: TextStyle(fontSize: 15, color: Colors.white)),
            ),
          )
        : const Center(
            child: CircularProgressIndicator(),
          );
  }

  Future<void> _signIn() async {
    try {
      UserCredential result = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email, password: _password);
      User? user = result.user;

      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', user.email!);
      await prefs.setString(
          'role', (snapshot.data() as Map<String, dynamic>)['role']);
      await prefs.setString('userid', user.uid);
      if (mounted) {
        setState(() {
          _load = false;
        });
        Navigator.of(context).pushReplacementNamed('home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _load = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}