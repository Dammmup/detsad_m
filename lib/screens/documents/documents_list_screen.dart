import 'package:flutter/material.dart';
import '../../../models/child_model.dart';
import '../../../core/services/children_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';

class DocumentsListScreen extends StatefulWidget {
  const DocumentsListScreen({super.key});

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки детей: $e')),
        );
      }
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
        title: const Text('Документы'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Container(
        decoration: AppDecorations.pageBackground,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Документы',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: children.isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: AppDecorations.cardDecoration,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.document_scanner,
                                        size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'Нет документов',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 16),
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
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: AppDecorations.cardDecoration,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              const Icon(Icons.badge,
                                                  size: 16,
                                                  color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text('ИИН: ${child.iin}',
                                                  style: TextStyle(
                                                      color: Colors.grey[700])),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        if (child.birthday != null) ...[
                                          Row(
                                            children: [
                                              const Icon(Icons.cake,
                                                  size: 16,
                                                  color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                  'День рождения: ${child.birthday}',
                                                  style: TextStyle(
                                                      color: Colors.grey[700])),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        if (child.parentName != null) ...[
                                          Row(
                                            children: [
                                              const Icon(Icons.person,
                                                  size: 16,
                                                  color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text('Родитель: ${child.parentName}',
                                                  style: TextStyle(
                                                      color: Colors.grey[700])),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        if (child.parentPhone != null) ...[
                                          Row(
                                            children: [
                                              const Icon(Icons.phone,
                                                  size: 16,
                                                  color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text('Телефон: ${child.parentPhone}',
                                                  style: TextStyle(
                                                      color: Colors.grey[700])),
                                            ],
                                          ),
                                        ],
                                        if (child.groupId != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withAlpha((0.1 * 255).round()),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Группа: ${child.groupId}',
                                              style: const TextStyle(
                                                  color: AppColors.primary),
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
