import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewAttendanceStud extends StatelessWidget {
  final String code;
  final String uid;
  const ViewAttendanceStud({
    super.key,
    required this.code,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ViewAttendanceStudScreen(code: code, uid: uid),
    );
  }
}

class ViewAttendanceStudScreen extends StatefulWidget {
  final String code;
  final String uid;
  const ViewAttendanceStudScreen({
    super.key,
    required this.code,
    required this.uid,
  });

  @override
  State<ViewAttendanceStudScreen> createState() => _ViewAttendanceStudScreenState();
}

class _ViewAttendanceStudScreenState extends State<ViewAttendanceStudScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

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
            .where(FieldPath.documentId, isEqualTo: widget.uid)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();

          List data = (snapshot.data!.docs[0].data()
              as Map<String, dynamic>)[widget.code]['attendance'];
          return DataTable(
            columnSpacing: 45,
            columns: const [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Periods')),
              DataColumn(label: Text('Attendance')),
            ],
            rows: data
                .map((element) => DataRow(cells: [
                      DataCell(
                          Text(element['date'].toString().split('–')[0])),
                      DataCell(Text(element['hrs'])),
                      DataCell((!element['attendance'])
                          ? const Icon(Icons.close, color: Colors.grey)
                          : const Icon(Icons.check, color: Colors.redAccent))
                    ]))
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
}