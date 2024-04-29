import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:touch_cut_server/server_exception.dart';
import 'package:touch_cut_server/src/auth/auth_repo.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    // Send OTP
    return _sendOtp(context);
  } else {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _sendOtp(RequestContext context) async {
  print('Sending or resending OTP');
  final authRepo = context.read<AuthRepo>();
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final params = context.request.uri.queryParameters;

    final resend = params['resend'];

    final phoneNumber = body['phone_number'] as String?;
    final userMetadata = body['user_metadata'] as Map<String, dynamic>?;

    // Phone number must be given
    if (phoneNumber == null) {
      print('Phone number is null');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error_message': 'Phone number is missing'},
      );
    }

    // Resend OTP
    if (resend != null && resend.toLowerCase() == 'true') {
      print('Resending OTP');
      await authRepo.resendOtpToUser(
        phoneNumber,
      );
      return Response.json();
    }

    final phoneNumberExists = false;
    // await authRepo.phoneNumberExists(phoneNumber: phoneNumber);
    if (userMetadata == null) {
      // Signing in old user
      print('Signing in old user, $phoneNumber');
      if (phoneNumberExists) {
        // Phone number exists in system, we can proceed
        await authRepo.sendOtpToUser(
          phoneNumber: phoneNumber,
        );
        return Response.json();
      } else {
        // Phone number does not exist in system, we can't proceed with the
        // log in
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {
            'error_message':
                'User with the provided phone number not found, please sign up',
          },
        );
      }
    } else {
      print('Signing up new user, $phoneNumber, with metadata $userMetadata');
      if (phoneNumberExists) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {
            'error_message':
                'User with the provided phone number already exists, please sign in',
          },
        );
      }
      // userMetadata will be in the form
      // {'first_name': <value>, 'last_name': <value>, 'village': <value>}
      if (userMetadata
          case {
            'first_name': String _,
            'last_name': final String _,
            'village': final String _,
          }) {
        await authRepo.sendOtpToUser(
          phoneNumber: phoneNumber,
          data: userMetadata,
        );
        return Response.json();
      } else {
        print('User metadata has wrong format, $userMetadata');
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'error_message': 'User metadata has wrong format'},
        );
      }
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
