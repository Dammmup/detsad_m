import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewAttendanceAll extends StatelessWidget {
  final String code;
  final String uid;
  final List students;
  const ViewAttendanceAll({
    super.key,
    required this.code,
    required this.uid,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ViewAttendanceAllScreen(
        code: code,
        uid: uid,
        students: students,
      ),
    );
  }
}

class ViewAttendanceAllScreen extends StatefulWidget {
  final String code;
  final String uid;
  final List students;
  const ViewAttendanceAllScreen({
    super.key,
    required this.code,
    required this.uid,
    required this.students,
  });

  @override
  State<ViewAttendanceAllScreen> createState() => _ViewAttendanceAllScreenState();
}

class _ViewAttendanceAllScreenState extends State<ViewAttendanceAllScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  double? _height;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _height = MediaQuery.of(context).size.height;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.code),
        ),
        body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildBody(context))));
  }

  Widget _buildBody(BuildContext context) {
    try {
      return StreamBuilder(
        stream: db
            .collection('attendance')
            .where(FieldPath.documentId, whereIn: widget.students)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();

          return DataTable(
            columnSpacing: 45,
            columns: generateColumns((snapshot.data!.docs[0].data()
                as Map<String, dynamic>)[widget.code]['attendance']),
            rows: snapshot.data!.docs
                .map((element) => generateRows(element.id,
                    (element.data() as Map<String, dynamic>)[widget.code]['attendance']))
                .toList(),
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

  List<DataColumn> generateColumns(List doc) {
    List<String> heading = List<String>.filled(doc.length + 1, '');
    List<String> hrs = List<String>.filled(doc.length + 1, '');
    heading[0] = 'Roll Number';
    hrs[0] = '';
    for (var i = 1; i < doc.length + 1; i++) {
      heading[i] = doc[i - 1]['date'].toString().split('–')[0];
      hrs[i] = doc[i - 1]['hrs'];
    }
    var j = 0;
    return heading
        .map((data) => DataColumn(
              label: Center(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(data,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  SizedBox(height: _height! / 80),
                  (j == 0)
                      ? Text(
                          hrs[j++],
                          style: const TextStyle(color: Colors.white),
                        )
                      : Text('Hrs: ${hrs[j++]}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold))
                ],
              )),
            ))
        .toList();
  }

  DataRow generateRows(String docId, List attendance) {
    List<String> row = List<String>.filled(attendance.length + 1, '');
    row[0] = docId;
    for (var i = 1; i < attendance.length + 1; i++) {
      if (attendance[i - 1]['attendance']) {
        row[i] = '1';
      } else {
        row[i] = '0';
      }
    }
    return DataRow(
      cells: row.map((data) => generateCells(data)).toList(),
    );
  }

  DataCell generateCells(String data) {
    return DataCell(Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        (data == '1')
            ? const Icon(Icons.check, color: Colors.redAccent)
            : (data == '0')
                ? const Icon(Icons.close, color: Colors.grey)
                : Text(data),
      ],
    ));
  }
}