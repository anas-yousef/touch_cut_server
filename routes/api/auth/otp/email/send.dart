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
  print('Sending or resending email OTP');
  final authRepo = context.read<AuthRepo>();
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final params = context.request.uri.queryParameters;

    final resend = params['resend'];

    final email = body['email'] as String?;
    final userMetadata = body['user_metadata'] as Map<String, dynamic>?;

    // Email must be given
    if (email == null) {
      print('Email is null');
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error_message': 'Email is missing'},
      );
    }

    // Resend OTP
    if (resend != null && resend.toLowerCase() == 'true') {
      print('Resending OTP');
      await authRepo.resendOtpToUser(
        email: email,
      );
      return Response.json();
    }

    final barbershopEmailExists =
        await authRepo.barbershopEmailExists(email: email);
    if (userMetadata == null) {
      // Signing in old user
      print('Signing in old user, $email');
      if (barbershopEmailExists) {
        // Phone number exists in system, we can proceed
        await authRepo.sendOtpToUser(
          email: email,
        );
        return Response.json();
      } else {
        // Phone number does not exist in system, we can't proceed with the
        // log in
        return Response.json(
          statusCode: HttpStatus.notFound,
          body: {
            'error_message':
                'User with the provided email not found, please sign up',
          },
        );
      }
    } else {
      print('Signing up new user, $email, with metadata $userMetadata');
      if (barbershopEmailExists) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {
            'error_message':
                'User with the provided email already exists, please sign in',
          },
        );
      }
      // userMetadata will be in the form
      // {'first_name': <value>, 'last_name': <value>, 'village': <value>,
      // 'phone_number': <value>}
      if (userMetadata
          case {
            'first_name': String _,
            'last_name': final String _,
            'village': final String _,
            'phone_number': final String _,
          }) {
        await authRepo.sendOtpToUser(
          email: email,
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
