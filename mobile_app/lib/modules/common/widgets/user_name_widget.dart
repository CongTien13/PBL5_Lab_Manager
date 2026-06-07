import 'package:flutter/material.dart';
import '../../../core/services/user_service.dart';

class UserNameWidget extends StatelessWidget {
  final String userId;
  final TextStyle? style;

  const UserNameWidget({
    super.key,
    required this.userId,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: UserService().getUserName(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text('...', style: style);
        }
        return Text(snapshot.data ?? userId, style: style);
      },
    );
  }
}