import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mark_attendance_page.dart';
import 'view_attendance_all_page.dart';
import 'view_attendance_stud_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double? _height, _width;
  SharedPreferences? prefs;
  bool _load = false;
  String? _uid, _role;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    try {
      prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _uid = prefs!.getString('userid');
          _role = prefs!.getString('role');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

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
        title: const Text('Home'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.exit_to_app,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _load = true;
              });
              _logout();
            },
          )
        ],
      ),
      body: !_load
          ? _checkRole()
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('role');
      await prefs.remove('userid');
      if (mounted) {
        setState(() {
          _load = false;
        });
        Navigator.of(context).pushReplacementNamed('login');
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

  Widget _checkRole() {
    switch (_role) {
      case 'student':
        return _listViewStudents();
      case 'staff':
        return _listViewStaff();
      case 'admin':
        return _listViewAdmin();
      default:
        return const Center(
          child: Text('Not a valid user role'),
        );
    }
  }

  Widget _listViewStudents() {
    try {
      return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .where('students', arrayContains: _uid)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView(
            children: snapshot.data!.docs.map((document) {
              return Card(
                child: ListTile(
                  title: Text(document.id),
                  subtitle: Text(
                      (document.data() as Map<String, dynamic>)['name']),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                ViewAttendanceStud(
                                  code: document.id,
                                  uid: _uid!,
                                )));
                  },
                ),
              );
            }).toList(),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return Center(child: Text(e.toString()));
    }
  }

  Widget _listViewStaff() {
    try {
      return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .where('staff', isEqualTo: _uid)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView(
            children: snapshot.data!.docs.map((document) {
              return Card(
                child: ListTile(
                  title: Text(document.id),
                  subtitle: Text(
                      (document.data() as Map<String, dynamic>)['name']),
                  onTap: () {
                    _staffDialog(document.id,
                        (document.data() as Map<String, dynamic>)['students']);
                  },
                ),
              );
            }).toList(),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return Center(child: Text(e.toString()));
    }
  }

  Widget _listViewAdmin() {
    try {
      return StreamBuilder(
        stream: FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView(
            children: snapshot.data!.docs.map((document) {
              return Card(
                child: ListTile(
                  title: Text(document.id),
                  subtitle: Text(
                      (document.data() as Map<String, dynamic>)['name']),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => ViewAttendanceAll(
                                code: document.id,
                                uid: _uid!,
                                students: (document.data()
                                    as Map<String, dynamic>)['students'])));
                  },
                ),
              );
            }).toList(),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return Center(child: Text(e.toString()));
    }
  }

  _staffDialog(String docId, List students) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Center(
            child: AlertDialog(
              content: Stack(
                children: <Widget>[
                  Positioned(
                    right: -40.0,
                    top: -40.0,
                    child: InkResponse(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: const CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buttonWidget('View Attendance', docId, students),
                      SizedBox(height: _height! / 40.0),
                      _buttonWidget('Mark Attendance', docId, students),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buttonWidget(String text, String docId, List students) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
        padding: const EdgeInsets.all(0.0),
      ),
      onPressed: () {
        if (text == 'View Attendance') {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => ViewAttendanceAll(
                      code: docId, uid: _uid!, students: students)));
        } else if (text == 'Mark Attendance') {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => MarkAttendance(
                      code: docId, uid: _uid!, students: students)));
        }
      },
      child: Container(
        alignment: Alignment.center,
        width: _width! / 2,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(25.0)),
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Text(text, style: const TextStyle(fontSize: 15, color: Colors.white)),
      ),
    );
  }
}