import 'package:flutter/material.dart';

import '../network/api_client.dart';

String userFacingError(
  Object error, {
  String fallback = 'Terjadi kendala. Coba lagi.',
}) {
  if (error is ApiException) {
    final parts = <String>[];
    if (error.message.isNotEmpty) parts.add(error.message);
    if (error.code case final code?) parts.add('Code: $code');
    if (_detailsText(error.details) case final details?) {
      parts.add('Details: $details');
    }
    if (parts.isNotEmpty) return parts.join('\n');
  }
  return fallback;
}

String? _detailsText(Object? details) {
  if (details == null) return null;
  if (details is String && details.isNotEmpty) return details;
  if (details is Map) {
    return details.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }
  if (details is List) return details.join(', ');
  return details.toString();
}

class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class AppEmpty extends StatelessWidget {
  const AppEmpty({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}

class AppError extends StatelessWidget {
  const AppError({required this.message, this.onRetry, this.onBack, super.key});

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
        if (onBack != null) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: onBack, child: const Text('Kembali')),
        ],
      ],
    ),
  );
}
