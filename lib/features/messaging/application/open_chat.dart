import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../data/messaging_repository.dart';

/// Opens (creating it if needed) the conversation with [userId].
/// Messaging is reserved to connections: the API refuses otherwise.
Future<void> openChatWith(
  BuildContext context,
  WidgetRef ref,
  String userId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final conversation = await ref
        .read(messagingRepositoryProvider)
        .start(userId);
    if (context.mounted) {
      await context.push(AppRoutes.chat(conversation.id));
    }
  } on ApiException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
  }
}
