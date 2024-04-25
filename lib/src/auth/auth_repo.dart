import 'package:supabase/supabase.dart';
import 'package:touch_cut_server/server_exception.dart';

/// An exception class for the authentication repository
class AuthRepoException extends ServerException {
  /// Constructor for the AuthRepoException class
  AuthRepoException({
    required String errorMessage,
    super.errorCode,
    super.errorBody,
  }) : super(
          errorMessage: 'AuthRepoException -> $errorMessage',
        );
}

class AuthRepo {
  /// Constructor
  const AuthRepo({required this.supabaseClient});

  /// The supabase client
  final SupabaseClient supabaseClient;

  /// Send OTP to user
  Future<void> sendOtpToUser({
    required String phoneNumber,
    Map<String, dynamic>? data,
  }) async {
    try {
      await supabaseClient.auth.signInWithOtp(
        phone: phoneNumber,
        data: data,
      );
    } on AuthException catch (authException) {
      print(authException);
      throw AuthRepoException(
        errorCode: authException.statusCode,
        errorMessage: authException.toString(),
      );
    } catch (err) {
      throw AuthRepoException(
        errorMessage: err.toString(),
      );
    }
  }

  /// Resend OTP to user
  Future<void> resendOtpToUser(
    String phoneNumber,
  ) async {
    try {
      final resendResponse = await supabaseClient.auth.resend(
        type: OtpType.sms,
        phone: phoneNumber,
      );
      // print(resendResponse.messageId);
    } on AuthException catch (authException) {
      print(authException);
      throw AuthRepoException(
        errorCode: authException.statusCode,
        errorMessage: authException.toString(),
      );
    } catch (err) {
      throw AuthRepoException(
        errorMessage: err.toString(),
      );
    }
  }

  /// Verify the token and return the user
  Future<User?> verifyAccessToken({
    required String accessToken,
  }) async {
    try {
      final userResponse = await supabaseClient.auth.getUser(accessToken);
      print("Got the user $userResponse");
      return userResponse.user;
    } on AuthException catch (authException) {
      print(authException);
      // We will have a wrapper that sends a 401 status code if the user is null
      return null;
    } catch (err) {
      throw AuthRepoException(
        errorMessage: err.toString(),
      );
    }
  }

  /// Verifies the OTP supplied by the user, and returns
  /// the access and refresh token, after creating a session
  /// for the user
  Future<Map<String, String>> verifyOTP({
    required String phoneNumber,
    required String token,
  }) async {
    try {
      final authResponse = await supabaseClient.auth.verifyOTP(
        type: OtpType.sms,
        token: token,
        phone: phoneNumber,
      );
      final session = authResponse.session!;
      return {
        'access_token': session.accessToken,
        'refresh_token': session.refreshToken!,
      };
    } on AuthException catch (authException) {
      print(authException);
      throw AuthRepoException(
        errorCode: authException.statusCode,
        errorMessage: authException.toString(),
      );
    } catch (err) {
      throw AuthRepoException(
        errorMessage: err.toString(),
      );
    }
  }

  /// Refresh access and refresh token
  Future<Map<String, String>> refreshAccessToken({
    required String refreshToken,
  }) async {
    try {
      final authResponse = await supabaseClient.auth.setSession(refreshToken);
      final session = authResponse.session!;
      return {
        'access_token': session.accessToken,
        'refresh_token': session.refreshToken!,
      };
    } on AuthException catch (authException) {
      throw AuthRepoException(
        errorCode: authException.statusCode,
        errorMessage: authException.toString(),
      );
    } catch (err) {
      throw AuthRepoException(
        errorMessage: err.toString(),
      );
    }
  }

  /// This function checks if the supplied phone number from the user is
  /// in the DB, while trying to sign in. If not found, that means no user
  /// exits with that phone number, therefore, we will return an error asking
  /// the user to sign-up, if found, then we will go ahead and send the user
  /// an SMS containing an OTP.
  Future<bool> phoneNumberExists({required String phoneNumber}) async {
    // Supabase DB saves the phone number without the + sign
    var phoneNumberToCheck = phoneNumber;
    if (phoneNumber.startsWith('+')) {
      phoneNumberToCheck = phoneNumber.substring(1);
    }
    final data = await supabaseClient
        .from('users')
        .select()
        .eq('phone_number', phoneNumberToCheck);
    if (data.isEmpty) {
      print('$phoneNumber not found in the system');
      return false;
    }
    print('$phoneNumber found in the system');
    return true;
  }
}
