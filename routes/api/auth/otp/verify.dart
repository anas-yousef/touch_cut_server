import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:touch_cut_server/server_exception.dart';
import 'package:touch_cut_server/src/auth/auth_repo.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    // Create session by submitting OTP from user
    return _verifyOTP(context);
  } else {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

/// Verifies the OTP sent by the user and creates a session for him
/// We return the access and refresh token, where the client will need to
/// save them locally
Future<Response> _verifyOTP(RequestContext context) async {
  print('Verifying OTP');
  final authRepo = context.read<AuthRepo>();
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final otpToken = body['otp_token'] as String?;
    final phoneNumber = body['phone_number'] as String?;
    if (otpToken != null && phoneNumber != null) {
      final tokens =
          await authRepo.verifyOTP(phoneNumber: phoneNumber, token: otpToken);
      return Response.json(body: tokens);
    } else {
      print('Phone number, or OTP are missing. Bad request');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error_message': 'Phone number, or OTP are missing'},
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
