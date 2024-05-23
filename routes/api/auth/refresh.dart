import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:touch_cut_server/server_exception.dart';
import 'package:touch_cut_server/src/auth/auth_repo.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    // Refresh session
    return _refreshAccessToken(context);
  } else {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

/// Refresh session using refresh token
Future<Response> _refreshAccessToken(RequestContext context) async {
  print('Refreshing access token');
  final authRepo = context.read<AuthRepo>();
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final refreshToken = body['refresh_token'] as String?;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      final tokens =
          await authRepo.refreshAccessToken(refreshToken: refreshToken);
      return Response.json(body: tokens);
    } else {
      print('Refresh token is missing or empty. Bad request');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error_message': 'Refresh token is missing or empty'},
      );
    }
  } on ServerException catch (serverException) {
    print('Got ServerException. $serverException');
    return Response.json(
      statusCode: serverException.errorCode,
      body: {'error_message': serverException.errorMessage},
    );
  } catch (err) {
    print('Got general exception. $err');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error_message': err.toString()},
    );
  }
}
