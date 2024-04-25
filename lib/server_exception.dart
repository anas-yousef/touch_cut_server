import 'dart:io';

/// A general exception class used to handle error messages on the server side
class ServerException implements Exception {
  /// Constructor
  ServerException({
    required this.errorMessage,
    String? errorCode,
    this.errorBody,
  }) : errorCode = errorCode != null
            ? int.parse(errorCode)
            : HttpStatus.internalServerError;

  /// The error message received
  final String errorMessage;

  /// Error code of exception
  final int errorCode;

  /// An error body if available
  final Map<String, dynamic>? errorBody;

  @override
  String toString() {
    return 'ServerException -> $errorMessage';
  }
}
