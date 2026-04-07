import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';

class UserAvatar extends StatelessWidget {
  final String? avatar;
  final String fullName;
  final double size;

  const UserAvatar({
    super.key,
    this.avatar,
    required this.fullName,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;

    if (avatar != null && avatar!.isNotEmpty) {
      if (avatar!.startsWith('data:image')) {
        // Base64 image
        try {
          final base64String = avatar!.split(',').last;
          imageProvider = MemoryImage(base64Decode(base64String));
        } catch (e) {
          imageProvider = null;
        }
      } else if (avatar!.startsWith('http')) {
        // Full URL
        imageProvider = NetworkImage(avatar!);
      } else {
        // Path from server
        final baseUrl = ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '');
        imageProvider = NetworkImage('$baseUrl/$avatar');
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipOval(
        child: imageProvider != null
            ? Image(
                image: imageProvider,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }
}
