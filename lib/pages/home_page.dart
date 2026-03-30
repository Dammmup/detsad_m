import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../models/group_model.dart';
import '../models/user_model.dart' as model;
import '../core/utils/logger.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  bool _isLoading = false;
  model.User? _currentUser;
  Future<List<Group>>? _groupsFuture;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = await _storageService.getUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _groupsFuture = _fetchGroups();
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('HomePage | Error loading initial data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Group>> _fetchGroups() async {
    try {
      final response = await _apiService.get('/groups');
      final List<dynamic> data = response.data;
      return data.map((json) => Group.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('HomePage | Error fetching groups: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () => _logout(),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _groupsFuture = _fetchGroups();
          });
        },
        child: _buildBody(),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await _storageService.clearAll();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выхода: $e')),
        );
      }
    }
  }

  Widget _buildBody() {
    if (_currentUser == null) {
      return const Center(child: Text('Пользователь не найден. Войдите снова.'));
    }

    return FutureBuilder<List<Group>>(
      future: _groupsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Ошибка: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _groupsFuture = _fetchGroups();
                    });
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final groups = snapshot.data ?? [];
        
        if (groups.isEmpty) {
          return const Center(child: Text('Список групп пуст'));
        }

        return _buildGroupList(groups);
      },
    );
  }

  Widget _buildGroupList(List<Group> groups) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Text(group.name.substring(0, 1).toUpperCase()),
            ),
            title: Text(
              group.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(group.description ?? 'Нет описания'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showGroupActions(group),
          ),
        );
      },
    );
  }

  void _showGroupActions(Group group) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(group.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _actionButton('View Attendance', group),
              const SizedBox(height: 12),
              _actionButton('Mark Attendance', group),
              const SizedBox(height: 12),
              _actionButton('Morning Check', group),
              const SizedBox(height: 12),
              _actionButton('Kitchen Menu', group),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  Widget _actionButton(String text, Group group) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {
          Navigator.pop(context); // Close dialog first
          _handleAction(text, group);
        },
        child: Text(text),
      ),
    );
  }

  void _handleAction(String text, Group group) {
    switch (text) {
      case 'View Attendance':
        Navigator.pushNamed(context, '/view-attendance-all', arguments: {
          'code': group.id,
          'uid': _currentUser!.id,
          'students': group.children?.map((c) => c['_id'] ?? c['id']).toList() ?? [],
        });
        break;
      case 'Mark Attendance':
        Navigator.pushNamed(context, '/mark-attendance', arguments: {
          'code': group.id,
          'uid': _currentUser!.id,
          'students': group.children?.map((c) => c['_id'] ?? c['id']).toList() ?? [],
        });
        break;
      case 'Morning Check':
        Navigator.pushNamed(context, '/medical-check', arguments: {
          'groupId': group.id,
          'groupName': group.name,
        });
        break;
      case 'Kitchen Menu':
        Navigator.pushNamed(context, '/kitchen-menu');
        break;
    }
  }
}