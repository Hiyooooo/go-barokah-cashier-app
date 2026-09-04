import 'package:flutter/material.dart';

import '../network/api_client.dart';

String userFacingError(
  Object error, {
  String fallback = 'Something went wrong.',
}) {
  if (error is ApiException && error.message.isNotEmpty) return error.message;
  return fallback;
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
  const AppError({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ],
    ),
  );
}
