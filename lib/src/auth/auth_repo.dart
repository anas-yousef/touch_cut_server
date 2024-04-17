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
  Future<void> sendOtpToUser(
    String phoneNumber,
  ) async {
    try {
      await supabaseClient.auth.signInWithOtp(
        phone: phoneNumber,
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

  /// Retrieve token and refresh token
  Future<Map<String, String>> verifyAndLoginUserOTP({
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
  Future<Map<String, String>> refreshAccessToken(
    String refreshToken,
  ) async {
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
}
