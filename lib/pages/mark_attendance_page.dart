import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MarkAttendance extends StatelessWidget {
  final String code;
  final String uid;
  final List students;
  const MarkAttendance({
    super.key,
    required this.code,
    required this.uid,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: MarkAttendanceScreen(
      code: code,
      uid: uid,
      students: students,
    ));
  }
}

class MarkAttendanceScreen extends StatefulWidget {
  final String code;
  final String uid;
  final List students;
  const MarkAttendanceScreen({
    super.key,
    required this.code,
    required this.uid,
    required this.students,
  });

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  late List<bool> present;
  double? _height, _width;
  final GlobalKey<FormState> _key = GlobalKey();
  DateTime now = DateTime.now();
  late String formattedDate;
  String hrs = '1';
  late FirebaseFirestore db;
  late WriteBatch batch;
  bool _load = false, _submitted = false;

  @override
  void initState() {
    super.initState();
    try {
      db = FirebaseFirestore.instance;
      batch = db.batch();
      formattedDate = DateFormat('dd-MM-yyyy – kk:mm').format(now);
      widget.students.sort();
      present = List<bool>.filled(widget.students.length, true);
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
          title: Text(widget.code),
        ),
        body: ListView(
          children: <Widget>[
            _form(),
            SizedBox(height: _height! / 40.0),
            _listHeader(),
            _listView(),
            SizedBox(height: _height! / 40.0),
            _button(),
            SizedBox(height: _height! / 40.0),
          ],
        ));
  }

  Widget _form() {
    return Container(
      margin: EdgeInsets.only(top: _height! / 15.0),
      child: Form(
        key: _key,
        child: Column(
          children: <Widget>[
            _date(),
            SizedBox(height: _height! / 40.0),
            _numOfHr(),
          ],
        ),
      ),
    );
  }

  Widget _numOfHr() {
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Text('Number of Hrs:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: hrs,
          underline: Container(),
          icon: const Icon(
            Icons.arrow_downward,
            color: Color(0xFF667eea),
          ),
          iconSize: 24.0,
          iconEnabledColor: Colors.blue,
          items: <String>['1', '2', '3', '4']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text("   $value   "),
            );
          }).toList(),
          onChanged: (String? value) {
            setState(() {
              hrs = value!;
            });
          },
        ),
      ],
    ));
  }

  Widget _date() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Text("Date & Time: ",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(formattedDate, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _button() {
    return !_load
        ? SizedBox(
            width: _width! / 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(0.0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0)),
                backgroundColor: Colors.white,
              ),
              onPressed: () {
                if (!_submitted) {
                  _submitted = !_submitted;
                  _markAttendance();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Attendance Already Marked!!!!')));
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
                child: const Text('Submit',
                    style: TextStyle(fontSize: 15, color: Colors.white)),
              ),
            ),
          )
        : const Center(
            child: CircularProgressIndicator(),
          );
  }

  Widget _listHeader() {
    return const Card(
        child: ListTile(
      title: Text('Roll Number',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      trailing: Text("Present",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ));
  }

  Widget _listView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: widget.students.length,
      itemBuilder: (context, index) {
        return Card(
            child: ListTile(
          title: Text(widget.students[index]),
          trailing: present[index]
              ? const Icon(
                  Icons.check,
                  color: Color(0xFF667eea),
                )
              : const Icon(
                  Icons.close,
                  color: Colors.grey,
                ),
          onTap: () {
            setState(() {
              present[index] = !present[index];
            });
          },
        ));
      },
    );
  }

  Future<void> _markAttendance() async {
    try {
      setState(() {
        _load = true;
      });
      DocumentSnapshot<Map<String, dynamic>> data =
          await db.collection('attendance').doc(widget.students[0]).get();
      int length = (data.data()!)[widget.code]['attendance'].length;
      if (mounted) {
        if ((data.data()!)[widget.code]['attendance'][length - 1]['date']
                .toString() ==
            formattedDate) {
          setState(() {
            _load = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Attendance Already Marked!!!!')));
        } else {
          for (var i = 0; i < widget.students.length; i++) {
            var obj = [{}];
            obj[0]['date'] = formattedDate;
            obj[0]['hrs'] = hrs;
            obj[0]['attendance'] = present[i];

            batch.update(db.collection('attendance').doc(widget.students[i]),
                {'${widget.code}.attendance': FieldValue.arrayUnion(obj)});
          }
          await batch.commit();
          if (mounted) {
            setState(() {
              _load = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attendance Marked')));
          }
        }
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
