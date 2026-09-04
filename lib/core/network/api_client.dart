import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_config.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

typedef TokenReader = Future<String?> Function();

final _secureStorage = FlutterSecureStorage();

class ApiClient {
  static const tokenKey = 'access_token';

  ApiClient({TokenReader? tokenReader})
    : _readToken = tokenReader ?? _readStoredToken {
    _dio =
        Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              headers: const {'Accept': 'application/json'},
            ),
          )
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) async {
                final token = await _readToken();
                if (token != null && token.isNotEmpty) {
                  options.headers['Authorization'] = 'Bearer $token';
                }
                handler.next(options);
              },
            ),
          );
  }

  late final Dio _dio;
  final TokenReader _readToken;

  Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(method: method),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static Future<String?> _readStoredToken() =>
      _secureStorage.read(key: tokenKey);
}

enum ApiErrorType {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  network,
  timeout,
  server,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  final ApiErrorType type;
  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseMessage = _responseMessage(error.response?.data);

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        type: ApiErrorType.timeout,
        message: 'Request timed out. Please try again.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return const ApiException(
        type: ApiErrorType.network,
        message: 'Network error. Check your connection and try again.',
      );
    }

    final type = statusCode == null
        ? ApiErrorType.unknown
        : switch (statusCode) {
            400 => ApiErrorType.badRequest,
            401 => ApiErrorType.unauthorized,
            403 => ApiErrorType.forbidden,
            404 => ApiErrorType.notFound,
            409 => ApiErrorType.conflict,
            >= 500 => ApiErrorType.server,
            _ => ApiErrorType.unknown,
          };

    return ApiException(
      type: type,
      statusCode: statusCode,
      message: responseMessage ?? _defaultMessage(type),
    );
  }

  @override
  String toString() => message;

  static String? _responseMessage(Object? data) {
    if (data case {'message': final String message} when message.isNotEmpty) {
      return message;
    }
    return null;
  }

  static String _defaultMessage(ApiErrorType type) => switch (type) {
    ApiErrorType.badRequest => 'The request is not valid.',
    ApiErrorType.unauthorized => 'Your session is invalid or expired.',
    ApiErrorType.forbidden => 'You do not have permission for this action.',
    ApiErrorType.notFound => 'The requested resource was not found.',
    ApiErrorType.conflict => 'The request conflicts with existing data.',
    ApiErrorType.server => 'The server encountered an error.',
    _ => 'An unexpected error occurred.',
  };
}
