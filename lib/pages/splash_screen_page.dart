import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  var _visible = true;

  late AnimationController animationController;
  late Animation<double> animation;

  Timer? _timer;
  
  startTime() async {
    var duration = const Duration(seconds: 3); // Reduced duration
    _timer = Timer(duration, navigationPage);
  }

  navigationPage() async {
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Initialize auth state
      await authProvider.initialize();
      
      // Дожидаемся, пока состояние загрузки не изменится
      while (authProvider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return; // Проверяем, что виджет все еще смонтирован
      }
      
      if (mounted) {
        if (authProvider.isLoggedIn) {
          Navigator.of(context).pushReplacementNamed('home');
        } else {
          Navigator.of(context).pushReplacementNamed('login');
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    animation =
        CurvedAnimation(parent: animationController, curve: Curves.easeOut);

    animation.addListener(() => setState(() {}));
    animationController.forward();

    setState(() {
      _visible = !_visible;
    });
    startTime();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Image.asset(
                    'assets/images/powered_by.png',
                    height: 50.0,
                    width: 140,
                    fit: BoxFit.scaleDown,
                  ))
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/logo.png',
                width: animation.value * 300,
                height: animation.value * 300,
              ),
            ],
          ),
        ],
      ),
    );
  }
}