import 'package:flutter/material.dart';
import '../../../models/child_model.dart';
import '../../../core/services/children_service.dart';

class DocumentsListScreen extends StatefulWidget {
  const DocumentsListScreen({Key? key}) : super(key: key);

  @override
  State<DocumentsListScreen> createState() => _DocumentsListScreenState();
}

class _DocumentsListScreenState extends State<DocumentsListScreen> {
  List<Child> children = [];
  bool isLoading = true;
  final ChildrenService _childrenService = ChildrenService();

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      children = await _childrenService.getAllChildren();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки детей: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
 }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Документы'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Документы',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 16),
                    
                    Expanded(
                      child: children.isEmpty
                          ? Center(
                              child: Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.document_scanner, size: 48, color: Colors.grey),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Нет документов',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: children.length,
                              itemBuilder: (context, index) {
                                final child = children[index];
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          child.fullName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (child.iin != null) ...[
                                          Row(
                                            children: [
                                              Icon(Icons.badge, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text('ИИН: ${child.iin}',
                                                   style: TextStyle(color: Colors.grey[700])),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        if (child.birthday != null) ...[
                                          Row(
                                            children: [
                                              Icon(Icons.cake, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text('День рождения: ${child.birthday}',
                                                   style: TextStyle(color: Colors.grey[700])),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        if (child.parentName != null) ...[
                                          Row(
                                            children: [
                                              Icon(Icons.person, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text('Родитель: ${child.parentName}',
                                                   style: TextStyle(color: Colors.grey[700])),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        if (child.parentPhone != null) ...[
                                          Row(
                                            children: [
                                              Icon(Icons.phone, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text('Телефон: ${child.parentPhone}',
                                                   style: TextStyle(color: Colors.grey[700])),
                                            ],
                                          ),
                                        ],
                                        if (child.groupId != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Группа: ${child.groupId}',
                                              style: TextStyle(color: Colors.blue),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}